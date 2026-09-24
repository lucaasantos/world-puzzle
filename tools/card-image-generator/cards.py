#!/usr/bin/env python3
"""Run from any working directory: python path/to/cards.py --help."""
import argparse
import json
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / 'src'))
from generator import Workflow, export_catalog, inspect_project, workflow_lock

HOME = Path(__file__).resolve().parent
ROOT = HOME.parents[1]


def environment():
    env = {}
    path = HOME / '.env'
    if path.exists():
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                key, sep, value = line.partition('=')
                if not sep:
                    raise ValueError('Linha inválida no .env.')
                env[key.strip()] = value.strip().strip('\"\'')
    env.update(os.environ)
    return env


def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description='Puzzle World — ferramenta interna de artes')
    subs = parser.add_subparsers(dest='command', required=True)
    for name in ['generate', 'regenerate', 'retry-failed']:
        cmd = subs.add_parser(name)
        cmd.add_argument('--id', required=name == 'regenerate')
        cmd.add_argument('--limit', type=int, default=15)
        cmd.add_argument('--dry-run', action='store_true')
    for name in ['approve', 'reject', 'apply', 'show', 'prompt']:
        cmd = subs.add_parser(name)
        cmd.add_argument('--id', required=True)
        if name in ['approve', 'reject']:
            cmd.add_argument('--note', default='')
        if name == 'apply':
            cmd.add_argument('--replace', action='store_true')
    for name in ['list-pending', 'inspect', 'status']:
        subs.add_parser(name)
    subs.add_parser('jobs')
    cmd = subs.add_parser('batch')
    cmd.add_argument('--batch', required=True)
    for name in ['start', 'import', 'fail', 'job']:
        cmd = subs.add_parser(name)
        cmd.add_argument('--job', required=True)
        if name == 'import':
            cmd.add_argument('--file', required=True)
        if name == 'fail':
            cmd.add_argument('--reason', required=True)
    args = parser.parse_args()
    env = environment()
    with workflow_lock(HOME):
        cards = export_catalog(ROOT, HOME, env.get('DART_EXECUTABLE'))
        report = inspect_project(ROOT, cards)
        settings = json.loads((HOME / 'config/style.json').read_text(encoding='utf-8'))
        template = (HOME / 'config/prompt.txt').read_text(encoding='utf-8')
        flow = Workflow(ROOT, HOME, cards, settings, template, env.get('IMAGE_API_KEY', ''))
        try:
            command = args.command
            if command in ['jobs', 'job', 'batch', 'start', 'import', 'fail']:
                if command == 'jobs':
                    result = [{k: j[k] for k in ['jobId', 'cardId', 'status']} for j in flow.jobs()]
                elif command == 'job':
                    result = flow.job(args.job)
                elif command == 'batch':
                    result = flow.batch(args.batch)
                elif command == 'start':
                    result = flow.start_job(args.job, int(env.get('DAILY_GENERATION_LIMIT', '0')))
                elif command == 'import':
                    result = flow.import_job(args.job, args.file)
                else:
                    result = flow.fail_job(args.job, args.reason)
                print(json.dumps(result, indent=2, ensure_ascii=False))
            elif command == 'inspect':
                report['outputSettings'] = settings
                print(json.dumps(report, indent=2, ensure_ascii=False))
            elif command == 'prompt':
                flow.state(args.id)
                print(flow.prompt(args.id))
            elif command == 'show':
                state = flow.state(args.id)
                print(json.dumps({**flow.cards[args.id], **state}, indent=2, ensure_ascii=False))
            elif command == 'list-pending':
                for card in cards:
                    status = flow.state(card['id'])['generationStatus']
                    if status in {'pending', 'retry'}:
                        print(f"{card['id']} | {card['catalogNumber']} | {card['name']} | {status}")
            elif command == 'status':
                counts = {}
                for card in cards:
                    status = flow.state(card['id'])['generationStatus']
                    counts[status] = counts.get(status, 0) + 1
                print(json.dumps(counts, indent=2))
            elif command in ['approve', 'reject']:
                flow.review(args.id, command == 'approve', args.note)
                print(json.dumps(flow.state(args.id), indent=2, ensure_ascii=False))
            elif command == 'apply':
                print('Aplicado: ' + flow.apply(args.id, args.replace))
            else:
                report = flow.prepare(args.limit, args.id, command, args.dry_run)
                print(json.dumps(report, indent=2, ensure_ascii=False))
        finally:
            flow.export_logs()
            flow.close()
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (Exception, KeyboardInterrupt) as error:
        # Redact a configured key even if a library unexpectedly echoes it.
        message = str(error)
        try:
            secret = environment().get('IMAGE_API_KEY', '')
            if secret:
                message = message.replace(secret, '[REDACTED]')
        except Exception:
            message = 'Falha ao carregar a configuração.'
        print('Erro: ' + (message or 'Execução interrompida.'), file=sys.stderr)
        sys.exit(1)
