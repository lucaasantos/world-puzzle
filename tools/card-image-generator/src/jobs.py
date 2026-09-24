"""Persistent hand-off to Codex image_gen; no API calls or ChatGPT login."""
import hashlib
import io
import json
from pathlib import Path
import uuid
from PIL import Image


class CodexJobs:
    def init_jobs(self):
        self.db.execute('CREATE TABLE IF NOT EXISTS jobs '
                        '(id TEXT PRIMARY KEY, card_id TEXT NOT NULL, status TEXT NOT NULL, payload TEXT NOT NULL)')
        self.db.execute("CREATE UNIQUE INDEX IF NOT EXISTS active_card_job ON jobs(card_id) "
                        "WHERE status IN ('queued', 'running')")
        self.db.commit()

    def job(self, job_id):
        row = self.db.execute('SELECT payload FROM jobs WHERE id=?', (job_id,)).fetchone()
        if not row:
            raise ValueError('Job desconhecido; consulte jobs ou batch.')
        return json.loads(row[0])

    def jobs(self):
        return [json.loads(row[0]) for row in self.db.execute('SELECT payload FROM jobs ORDER BY rowid')]

    def record_job(self, job, state, action):
        from generator import now
        cid = job['cardId']
        job, state = self.clean(job), self.clean(state)
        event = dict(cardId=cid, name=self.cards[cid]['name'], timestamp=now(), action=action, **state)
        with self.db:
            self.db.execute('INSERT INTO jobs VALUES (?, ?, ?, ?) '
                            'ON CONFLICT(id) DO UPDATE SET status=excluded.status, payload=excluded.payload',
                            (job['jobId'], cid, job['status'], json.dumps(job)))
            self.db.execute('UPDATE cards SET metadata=? WHERE id=?', (json.dumps(state), cid))
            self.db.execute('INSERT INTO events(data) VALUES (?)', (json.dumps(event, ensure_ascii=False),))

    def prepare(self, limit=15, card_id=None, mode='generate', dry_run=False):
        from generator import atomic_write, now
        if limit < 1:
            raise ValueError('Limite deve ser positivo.')
        allowed = {'pending', 'retry'} if mode == 'generate' else {'failed', 'retry'}
        if mode == 'regenerate':
            if not card_id:
                raise ValueError('regenerate exige --id.')
            allowed = {'pending', 'generated', 'approved', 'rejected', 'failed', 'retry'}
        candidates = [card_id] if card_id else list(self.cards)
        active = {j['cardId']: j for j in self.jobs() if j['status'] in {'queued', 'running'}}
        candidates.sort(key=lambda cid: cid not in active)
        chosen = []
        for cid in candidates:
            state = self.state(cid)
            if cid in active:
                if mode == 'retry-failed' and active[cid].get('mode') != 'retry-failed':
                    continue
                chosen.append(active[cid])
            elif state['generationStatus'] in allowed:
                job = dict(jobId=uuid.uuid4().hex, cardId=cid, status='queued', createdAt=now(),
                           provider='codex-chatgpt', model=None, mode=mode, promptUsed=self.prompt(cid),
                           settings=json.loads(json.dumps(self.settings)))
                if not dry_run:
                    state['activeJobId'] = job['jobId']
                    if mode != 'generate':
                        state['generationStatus'] = 'retry'
                    self.record_job(job, state, 'queued')
                chosen.append(job)
            elif card_id:
                raise ValueError('Estado incompatível; use regenerate para uma nova versão.')
            if len(chosen) >= limit:
                break
        batch_id = uuid.uuid4().hex
        manifest = dict(batchId=batch_id, createdAt=now(), jobIds=[j['jobId'] for j in chosen])
        if not dry_run:
            atomic_write(self.home / 'output/batches' / f'{batch_id}.json',
                         json.dumps(manifest, indent=2).encode())
        return dict(batchId=None if dry_run else batch_id, selected=len(chosen),
                    jobs=[{k: j[k] for k in ['jobId', 'cardId', 'status']} for j in chosen],
                    dryRun=dry_run, mode='codex-chatgpt',
                    nextStep='Codex: start --job=<jobId>, image_gen com promptUsed, import --job --file. '
                             'A CLI prepara a fila; a geração acontece na sessão do Codex/ChatGPT.')

    def batch(self, batch_id):
        from generator import within
        if not batch_id or any(c not in '0123456789abcdef' for c in batch_id):
            raise ValueError('ID de lote inválido.')
        path = within(self.home / 'output/batches', f'{batch_id}.json')
        manifest = json.loads(path.read_text())
        jobs = [self.job(jid) for jid in manifest['jobIds']]
        counts = {status: sum(j['status'] == status for j in jobs)
                  for status in ['queued', 'running', 'completed', 'failed']}
        return dict(batchId=batch_id, selected=len(jobs), **counts,
                    jobs=[{k: j[k] for k in ['jobId', 'cardId', 'status']} for j in jobs])

    def start_job(self, job_id, daily_limit=0):
        from generator import now
        job = self.job(job_id)
        if job['status'] != 'queued':
            raise ValueError('Job já iniciado ou finalizado. Não gere novamente. '
                             'Se running, importe o resultado existente ou registre fail explicitamente.')
        if daily_limit < 0:
            raise ValueError('Limite diário deve ser zero (sem limite) ou positivo.')
        cid = job['cardId']
        state = self.state(cid)
        if state.get('activeJobId') != job_id:
            raise ValueError('Job não corresponde à versão atual da carta.')
        day = now()[:10]
        used = self.db.execute('SELECT COUNT(*) FROM requests WHERE day=?', (day,)).fetchone()[0]
        if daily_limit and used >= daily_limit:
            raise ValueError('Limite local diário atingido. Job continua na fila para retomar depois.')
        state.update(generationStatus='generating', generationAttempts=state['generationAttempts'] + 1,
                     provider='codex-chatgpt', model=None, promptUsed=job['promptUsed'],
                     startedAt=now(), generatedAt=None, outputPath=None, errorMessage=None, usage=None)
        job.update(status='running', startedAt=state['startedAt'], attempt=state['generationAttempts'])
        # The reservation is committed with the state and event by record_job.
        self.db.execute('INSERT INTO requests VALUES (?, ?)', (day, cid))
        self.record_job(job, state, 'generating')
        return job

    def import_job(self, job_id, source_path):
        from generator import atomic_write, now, optimize
        job = self.job(job_id)
        source = Path(source_path).resolve()
        if not source.is_file() or source.stat().st_size > 30_000_000:
            raise ValueError('Arquivo ausente ou maior que 30 MB.')
        original = source.read_bytes()
        source_hash = hashlib.sha256(original).hexdigest()
        if job['status'] == 'completed':
            if job.get('sourceSha256') == source_hash:
                return job
            raise ValueError('Job já importado com outro arquivo; use regenerate para nova versão.')
        if job['status'] != 'running':
            raise ValueError('Execute start antes de importar o resultado deste job.')
        cid = job['cardId']
        state = self.state(cid)
        if state.get('activeJobId') != job_id:
            raise ValueError('Job não corresponde à versão atual da carta.')
        for previous in self.jobs():
            if previous['cardId'] != cid and previous.get('sourceSha256') == source_hash:
                raise ValueError('Este arquivo já foi importado para outra carta.')
        raw = optimize(original, job['settings'])
        name = f"{cid}__a{job['attempt']:04d}__{job_id[:8]}.webp"
        relative = 'output/generated/' + name
        # Preserve the original inside the project, not just in CODEX_HOME.
        with Image.open(io.BytesIO(original)) as image:
            suffix = {'PNG': '.png', 'JPEG': '.jpg', 'WEBP': '.webp'}.get(image.format, '.source')
        original_path = 'output/originals/' + job_id + suffix
        atomic_write(self.home / original_path, original)
        atomic_write(self.home / relative, raw)
        state.update(generationStatus='generated', generatedAt=now(), outputPath=relative,
                     sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw),
                     dimensions=[job['settings']['width'], job['settings']['height']], format='WEBP',
                     sourceSha256=source_hash, originalPath=original_path, activeJobId=None)
        job.update(status='completed', completedAt=state['generatedAt'], sourceSha256=source_hash,
                   outputPath=relative, originalPath=original_path)
        self.record_job(job, state, 'generated')
        return job

    def fail_job(self, job_id, message):
        from generator import now
        job = self.job(job_id)
        if job['status'] not in {'queued', 'running'}:
            raise ValueError('Somente jobs abertos podem ser encerrados com falha.')
        state = self.state(job['cardId'])
        job.update(status='failed', errorMessage=message[:1000], failedAt=now())
        state.update(generationStatus='failed', errorMessage=message[:1000], activeJobId=None)
        self.record_job(job, state, 'failed')
        return job
