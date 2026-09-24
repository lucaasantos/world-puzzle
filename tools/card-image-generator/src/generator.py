"""Offline development workflow. Only apply() touches the Flutter project."""
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import uuid
from datetime import datetime, timezone

from PIL import Image, ImageOps
from jobs import CodexJobs


def now():
    return datetime.now(timezone.utc).isoformat()


def atomic_write(path, content):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    try:
        temporary.write_bytes(content)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def within(root, relative):
    root = Path(root).resolve()
    result = (root / relative).resolve()
    if not result.is_relative_to(root) or result == root:
        raise ValueError('Caminho fora da pasta permitida.')
    return result


@contextlib.contextmanager
def workflow_lock(home):
    """OS releases this lock even after a crash; file presence alone is harmless."""
    path = Path(home) / 'data/workflow.lock'
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a+b') as handle:
        handle.seek(0)
        if path.stat().st_size == 0:
            handle.write(b'0')
            handle.flush()
        handle.seek(0)
        try:
            if os.name == 'nt':
                import msvcrt
                msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            raise RuntimeError('Outra execução está usando esta ferramenta.') from None
        try:
            yield
        finally:
            handle.seek(0)
            if os.name == 'nt':
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(handle, fcntl.LOCK_UN)


def export_catalog(root, home, dart=None):
    executable = dart or shutil.which('dart')
    if not executable:
        raise ValueError('Dart não encontrado. Configure DART_EXECUTABLE.')
    result = subprocess.run([executable, str(Path(home) / 'scripts/export_catalog.dart')],
                            cwd=root, capture_output=True, encoding='utf-8', timeout=90)
    if result.returncode:
        raise RuntimeError('Falha ao ler catálogo Dart: ' + result.stderr[:1500])
    cards = json.loads(result.stdout)
    ids = [card['id'] for card in cards]
    if not cards or len(ids) != len(set(ids)):
        raise ValueError('Catálogo vazio ou com IDs duplicados.')
    for card in cards:
        if not re.fullmatch(r'[a-z0-9_]+', card['id']):
            raise ValueError('ID de carta inválido.')
        path = within(Path(root) / 'assets/images/cards',
                      Path(card['imagePath']).relative_to('assets/images/cards'))
        if path.suffix != '.webp':
            raise ValueError('Convenção de assets mudou: execute inspect e adapte a ferramenta.')
    return cards


def inspect_project(root, cards):
    """Read the actual widget contract; fail visibly if its structure changes."""
    root = Path(root)
    widget = (root / 'lib/widgets/collectible_card').resolve()
    tile = (widget / 'collectible_card_tile.dart').read_text(encoding='utf-8')
    frame = (widget / 'collectible_card_frame.dart').read_text(encoding='utf-8')
    artwork = (widget / 'card_artwork.dart').read_text(encoding='utf-8')
    def number(pattern, source):
        match = re.search(pattern, source)
        if not match:
            raise ValueError('Layout mudou; revise inspect_project antes de gerar.')
        return float(match[1])
    ratio = re.search(r'collectibleCardAspectRatio\s*=\s*(\d+)\s*/\s*(\d+)', tile)
    if not ratio or 'BoxFit.cover' not in artwork:
        raise ValueError('Contrato de renderização mudou; revisar manualmente.')
    width = number(r'constraints.maxWidth / ([\d.]+)', frame)
    heights = re.findall(r'height: ([\d.]+) \* scale', frame.split('class _Header')[0])
    if len(heights) != 2:
        raise ValueError('Cabeçalho/rodapé mudou; revisar dimensões.')
    pad = number(r'EdgeInsets.symmetric\(horizontal: ([\d.]+) \* scale\)', frame)
    art_width = width - 2 * pad
    art_height = width * int(ratio[2]) / int(ratio[1]) - sum(map(float, heights))
    images = []
    for card in cards:
        path = root / card['imagePath']
        if path.exists():
            with Image.open(path) as im:
                images.append(dict(path=card['imagePath'], width=im.width, height=im.height,
                                   format=im.format))
    return dict(cards=len(cards), countries=len({c['countryId'] for c in cards}),
                placeholders=sum(c['isPlaceholderImage'] for c in cards),
                cardAspectRatio=f'{ratio[1]}:{ratio[2]}',
                nominalArtworkSize=[art_width, round(art_height, 3)],
                artworkAspectRatio=round(art_width / art_height, 6),
                fit='BoxFit.cover (center crop)', format='WEBP', existingImages=images,
                note='Placeholders são widgets; não há resolução raster obrigatória. '
                     'A área varia quando o scale é limitado pelo clamp do layout.')


def optimize(raw, settings):
    if len(raw) > 30_000_000:
        raise ValueError('Imagem excede 30 MB.')
    with Image.open(io.BytesIO(raw)) as check:
        check.verify()
    with Image.open(io.BytesIO(raw)) as source:
        source = ImageOps.exif_transpose(source)
        width, height = settings['width'], settings['height']
        if source.width < width or source.height < height:
            raise ValueError('Imagem pequena demais; upscale automático não é permitido.')
        image = ImageOps.fit(source.convert('RGB'), (width, height), Image.Resampling.LANCZOS)
        for quality in range(settings['quality'], 69, -4):
            output = io.BytesIO()
            image.save(output, 'WEBP', quality=quality, method=6)
            data = output.getvalue()
            if len(data) <= settings['maxBytes']:
                return data
    raise ValueError('WebP acima do limite de bytes; revise a configuração.')


class Workflow(CodexJobs):
    def __init__(self, root, home, cards, settings, template, secret=''):
        self.root, self.home = Path(root), Path(home)
        self.cards = {c['id']: c for c in cards}
        self.settings, self.template, self.secret = settings, template, secret
        for folder in ['data', 'logs', 'output/generated', 'output/approved', 'output/rejected']:
            (self.home / folder).mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(self.home / 'data/state.sqlite3')
        self.db.execute('CREATE TABLE IF NOT EXISTS cards (id TEXT PRIMARY KEY, metadata TEXT NOT NULL)')
        self.db.execute('CREATE TABLE IF NOT EXISTS events (sequence INTEGER PRIMARY KEY, data TEXT NOT NULL)')
        self.db.execute('CREATE TABLE IF NOT EXISTS requests (day TEXT NOT NULL, card_id TEXT NOT NULL)')
        self.init_jobs()
        with self.db:
            for card in cards:
                metadata = dict(generationStatus='pending' if card['isPlaceholderImage'] else 'approved',
                                generationAttempts=0)
                self.db.execute('INSERT OR IGNORE INTO cards VALUES (?, ?)',
                                (card['id'], json.dumps(metadata)))
        # Caller owns OS lock, so generating means a previous process was interrupted.
        for card in cards:
            state = self.state(card['id'])
            if state['generationStatus'] == 'generating' and not state.get('activeJobId'):
                state.update(generationStatus='failed', errorMessage='Execução interrompida; retry manual.')
                self.save(card['id'], state, 'interrupted')

    def close(self):
        self.db.close()

    def state(self, card_id):
        if card_id not in self.cards:
            raise ValueError(f'Carta desconhecida: {card_id}. Use o ID listado no catálogo.')
        return json.loads(self.db.execute('SELECT metadata FROM cards WHERE id=?', (card_id,)).fetchone()[0])

    def clean(self, value):
        text = json.dumps(value, ensure_ascii=False)
        if self.secret:
            text = text.replace(self.secret, '[REDACTED]')
        return json.loads(text)

    def save(self, card_id, state, action):
        state = self.clean(state)
        event = dict(cardId=card_id, name=self.cards[card_id]['name'], timestamp=now(),
                     action=action, **state)
        with self.db:
            self.db.execute('UPDATE cards SET metadata=? WHERE id=?', (json.dumps(state), card_id))
            self.db.execute('INSERT INTO events(data) VALUES (?)', (json.dumps(event, ensure_ascii=False),))

    def export_logs(self):
        lines = [row[0] for row in self.db.execute('SELECT data FROM events ORDER BY sequence')]
        atomic_write(self.home / 'logs/events.jsonl', ('\n'.join(lines) + '\n').encode('utf-8'))

    def prompt(self, card_id):
        card = self.cards[card_id]
        return self.template.format(**card, **{k: v for k, v in self.settings.items() if k != 'rarity'},
                                    rarityStyle=self.settings['rarity'].get(card['rarity'], 'Natural light.'))

    def generate(self, provider, limit=15, card_id=None, mode='generate', daily_limit=0):
        if limit < 1 or daily_limit < 0:
            raise ValueError('Lote deve ser positivo; limite diário deve ser zero (sem limite) ou positivo.')
        allowed = {'pending', 'retry'} if mode == 'generate' else {'failed', 'retry'}
        if mode == 'regenerate':
            if not card_id:
                raise ValueError('regenerate exige --id.')
            allowed = {'pending', 'generated', 'approved', 'rejected', 'failed', 'retry'}
        candidates = [card_id] if card_id else list(self.cards)
        selected = []
        for cid in candidates:
            state = self.state(cid)
            if state['generationStatus'] in allowed:
                selected.append(cid)
            elif card_id:
                raise ValueError('Estado incompatível; use regenerate para nova versão.')
        selected = selected[:limit]
        done = failed = 0
        attempted = 0
        for cid in selected:
            day = now()[:10]
            used = self.db.execute('SELECT COUNT(*) FROM requests WHERE day=?', (day,)).fetchone()[0]
            if daily_limit and used >= daily_limit:
                break
            state = self.state(cid)
            if mode != 'generate':
                state['generationStatus'] = 'retry'
                self.save(cid, state, 'retry')
            state.update(generationStatus='generating', generationAttempts=state['generationAttempts'] + 1,
                         provider=provider.name, model=provider.model, promptUsed=self.prompt(cid),
                         startedAt=now(), generatedAt=None, outputPath=None, errorMessage=None, usage=None)
            # Durable reservation before sending: timeouts/crashes still count toward the cap.
            with self.db:
                self.db.execute('INSERT INTO requests VALUES (?, ?)', (day, cid))
            self.save(cid, state, 'generating')
            attempted += 1
            try:
                result = provider.generate(state['promptUsed'], self.settings)
                state['usage'] = result.usage
                raw = optimize(result.image, self.settings)
                name = f"{cid}__a{state['generationAttempts']:04d}__{uuid.uuid4().hex[:8]}.webp"
                relative = 'output/generated/' + name
                atomic_write(self.home / relative, raw)
                state.update(generationStatus='generated', generatedAt=now(), outputPath=relative,
                             sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw),
                             dimensions=[self.settings['width'], self.settings['height']], format='WEBP')
                done += 1
            except Exception as error:
                state.update(generationStatus='failed', errorMessage=str(error)[:1000])
                failed += 1
            self.save(cid, state, state['generationStatus'])
            print(f"{cid}: {state['generationStatus']}", flush=True)
        self.export_logs()
        return dict(selected=len(selected), attempted=attempted, generated=done, failed=failed,
                    deferredByDailyLimit=len(selected)-attempted,
                    pending=sum(self.state(cid)['generationStatus'] in {'pending', 'retry'} for cid in self.cards),
                    output=str(self.home / 'output/generated'))

    def review(self, card_id, approve, note=''):
        state = self.state(card_id)
        if state['generationStatus'] != 'generated':
            raise ValueError('Somente uma versão generated pode ser aprovada/rejeitada.')
        source = within(self.home / 'output/generated', Path(state['outputPath']).name)
        raw = source.read_bytes()
        if hashlib.sha256(raw).hexdigest() != state['sha256']:
            raise ValueError('Imagem mudou desde a geração; revisão recusada.')
        status = 'approved' if approve else 'rejected'
        destination = self.home / 'output' / status / source.name
        if destination.exists():
            raise ValueError('Versão já existe; sobrescrita recusada.')
        atomic_write(destination, raw)
        state.update(generationStatus=status, reviewedAt=now(), reviewNote=note,
                     outputPath=destination.relative_to(self.home).as_posix())
        if approve:
            state.update(approvedPath=state['outputPath'], approvedSha256=state['sha256'])
        self.save(card_id, state, status)
        self.export_logs()

    def apply(self, card_id, replace=False):
        state = self.state(card_id)
        if state['generationStatus'] != 'approved' or not state.get('approvedPath'):
            raise ValueError('A versão atual precisa ser aprovada antes de aplicar.')
        source = within(self.home / 'output/approved', Path(state['approvedPath']).name)
        raw = source.read_bytes()
        if hashlib.sha256(raw).hexdigest() != state['approvedSha256']:
            raise ValueError('Arquivo aprovado foi alterado; aplicação recusada.')
        with Image.open(io.BytesIO(raw)) as im:
            if im.format != 'WEBP' or list(im.size) != state['dimensions']:
                raise ValueError('Formato ou dimensão incompatível.')
            im.verify()
        card = self.cards[card_id]
        target = within(self.root / 'assets/images/cards',
                        Path(card['imagePath']).relative_to('assets/images/cards'))
        manifest = self.root / 'lib/data/approved_card_art.dart'
        pubspec = self.root / 'pubspec.yaml'
        original_manifest, original_pubspec = manifest.read_bytes(), pubspec.read_bytes()
        old = target.read_bytes() if target.exists() else None
        if old is not None and old != raw and not replace:
            raise ValueError('Asset existente. Use --replace explicitamente; será criado backup.')
        text = original_manifest.decode('utf-8')
        ids = set(re.findall(r"'([a-z0-9_]+)'", text))
        ids.add(card_id)
        manifest_data = ('// Updated only by the development tool after manual artwork approval.\n'
                         'const approvedCardArtIds = <String>{\n' +
                         ''.join(f"  '{cid}',\n" for cid in sorted(ids)) + '};\n').encode()
        spec = original_pubspec.decode('utf-8')
        directory = Path(card['imagePath']).parent.as_posix() + '/'
        if not re.search(r'^\s*-\s*' + re.escape(directory) + r'\s*$', spec, re.M):
            if spec.count('  assets:') != 1:
                raise ValueError('Não foi possível localizar flutter.assets no pubspec.')
            spec = spec.replace('  assets:', f'  assets:\n    - {directory}', 1)
        backup = self.home / 'output/applied-backups' / (card_id + '__' + uuid.uuid4().hex)
        backup.mkdir(parents=True)
        atomic_write(backup / 'approved_card_art.dart', original_manifest)
        atomic_write(backup / 'pubspec.yaml', original_pubspec)
        if old is not None:
            atomic_write(backup / target.name, old)
        try:
            atomic_write(target, raw)
            atomic_write(pubspec, spec.encode('utf-8'))
            atomic_write(manifest, manifest_data)
        except BaseException:
            atomic_write(manifest, original_manifest)
            atomic_write(pubspec, original_pubspec)
            if old is None:
                target.unlink(missing_ok=True)
            else:
                atomic_write(target, old)
            raise
        state.update(appliedAt=now(), appliedPath=card['imagePath'],
                     appliedSha256=state['approvedSha256'], backupPath=str(backup))
        self.save(card_id, state, 'applied')
        self.export_logs()
        return card['imagePath']
