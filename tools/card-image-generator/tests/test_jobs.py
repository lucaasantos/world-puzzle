"""Codex hand-off tests, isolated from real jobs and network."""
import json
from pathlib import Path
import unittest

import test_workflow as fixtures
from generator import Workflow


class CodexJobsTests(unittest.TestCase):
    setUpClass = classmethod(fixtures.WorkflowTests.setUpClass.__func__)
    setUp = fixtures.WorkflowTests.setUp

    def source(self, second=False):
        source = self.root / ('second.webp' if second else 'first.webp')
        raw = ((fixtures.ROOT / 'assets/images/themes/japan/japan_02.webp').read_bytes()
               if second else self.image)
        source.write_bytes(raw)
        return source

    def test_queue_resume_snapshot_and_dry_run(self):
        preview = self.flow.prepare(limit=2, dry_run=True)
        self.assertEqual(preview['selected'], 2)
        self.assertEqual(self.flow.jobs(), [])
        batch = self.flow.prepare(limit=2)
        first = batch['jobs'][0]['jobId']
        second = batch['jobs'][1]['jobId']
        prompt = self.flow.job(first)['promptUsed']
        self.assertNotIn(self.cards[1]['name'], prompt)
        self.assertNotIn(self.cards[0]['name'], self.flow.job(second)['promptUsed'])
        self.flow.template = 'changed template'
        self.assertEqual(self.flow.prepare(limit=2)['jobs'], batch['jobs'])
        self.assertEqual(self.flow.job(first)['promptUsed'], prompt)
        self.flow.start_job(first)
        with self.assertRaises(ValueError):
            self.flow.start_job(first)
        other = Workflow(self.root, self.home, self.cards, self.settings, self.template)
        try:
            self.assertEqual(other.job(first)['status'], 'running')
            self.assertEqual(other.state(self.cards[0]['id'])['generationStatus'], 'generating')
            self.assertEqual(other.batch(batch['batchId'])['running'], 1)
        finally:
            other.close()

    def test_import_idempotence_duplicate_protection_and_review(self):
        batch = self.flow.prepare(limit=2)
        first, second = [j['jobId'] for j in batch['jobs']]
        source = self.source()
        with self.assertRaises(ValueError):
            self.flow.import_job(first, source)
        self.flow.start_job(first)
        job = self.flow.import_job(first, source)
        self.assertEqual(self.flow.import_job(first, source), job)
        self.assertEqual(self.flow.state(self.cards[0]['id'])['generationAttempts'], 1)
        self.assertTrue((self.home / job['originalPath']).exists())
        self.assertIsNone(self.flow.state(self.cards[0]['id'])['model'])
        self.flow.review(self.cards[0]['id'], True)
        self.flow.apply(self.cards[0]['id'])
        self.flow.start_job(second)
        with self.assertRaises(ValueError):
            self.flow.import_job(second, source)
        self.flow.import_job(second, self.source(second=True))
        self.assertEqual(self.flow.batch(batch['batchId'])['completed'], 2)
        self.flow.review(self.cards[1]['id'], False)
        retry = self.flow.prepare(card_id=self.cards[1]['id'], mode='regenerate')
        self.assertNotEqual(retry['jobs'][0]['jobId'], second)

    def test_failed_jobs_do_not_block_remaining_cards(self):
        batch = self.flow.prepare(limit=2)
        first, second = [j['jobId'] for j in batch['jobs']]
        self.flow.start_job(first)
        self.flow.fail_job(first, 'tool unavailable secret-for-test')
        retry = self.flow.prepare(mode='retry-failed')
        self.assertEqual(retry['selected'], 1)
        self.assertEqual(retry['jobs'][0]['cardId'], self.cards[0]['id'])
        self.flow.start_job(second)
        self.flow.import_job(second, self.source(second=True))
        result = self.flow.batch(batch['batchId'])
        self.assertEqual((result['completed'], result['failed']), (1, 1))
        self.flow.export_logs()
        self.assertNotIn('secret-for-test', (self.home / 'logs/events.jsonl').read_text())

    def test_local_limit_reserves_only_started_jobs(self):
        batch = self.flow.prepare(limit=2)
        first, second = [j['jobId'] for j in batch['jobs']]
        self.assertEqual(self.flow.db.execute('SELECT COUNT(*) FROM requests').fetchone()[0], 0)
        self.flow.start_job(first, daily_limit=1)
        self.flow.fail_job(first, 'interrupted')
        with self.assertRaises(ValueError):
            self.flow.start_job(second, daily_limit=1)
        self.assertEqual(self.flow.job(second)['status'], 'queued')
        self.flow.start_job(second, daily_limit=0)
        self.assertEqual(self.flow.job(second)['status'], 'running')
        self.assertEqual(self.flow.db.execute('SELECT COUNT(*) FROM requests').fetchone()[0], 2)

    def test_default_batch_is_fifteen_without_generating(self):
        pending_cards = [dict(card, isPlaceholderImage=True) for card in self.catalog[:20]]
        other = Workflow(self.root, self.home, pending_cards, self.settings, self.template)
        try:
            self.assertEqual(other.prepare()['selected'], 15)
            self.assertEqual(len(other.jobs()), 15)
            self.assertEqual(other.prepare()['selected'], 15)
            self.assertEqual(len(other.jobs()), 15)
        finally:
            other.close()

    def test_invalid_import_stays_resumable_and_settings_are_frozen(self):
        jid = self.flow.prepare(limit=1)['jobs'][0]['jobId']
        self.flow.start_job(jid)
        source = self.root / 'broken.png'
        source.write_bytes(b'invalid image')
        with self.assertRaises(Exception):
            self.flow.import_job(jid, source)
        self.assertEqual(self.flow.job(jid)['status'], 'running')
        original_settings = self.flow.settings
        self.flow.settings = {**original_settings, 'width': 500}
        self.flow.import_job(jid, self.source())
        self.assertEqual(self.flow.state(self.cards[0]['id'])['dimensions'], [1000, 1024])


if __name__ == '__main__':
    unittest.main()
