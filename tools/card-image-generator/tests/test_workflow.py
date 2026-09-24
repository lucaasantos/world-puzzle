"""No network/cost. Exactly two existing catalog cards, in a temporary project."""
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

HOME = Path(__file__).resolve().parents[1]
ROOT = HOME.parents[1]
sys.path.insert(0, str(HOME / 'src'))
from generator import Workflow, export_catalog, inspect_project, optimize, workflow_lock
from providers import GenerationResult
from PIL import Image


class FixtureProvider:
    name, model = 'test-fixture', 'local-file'

    def __init__(self, image, fail_first=False):
        self.image, self.fail_first, self.prompts = image, fail_first, []

    def generate(self, prompt, settings):
        self.prompts.append(prompt)
        if self.fail_first and len(self.prompts) == 1:
            raise TimeoutError('simulated timeout secret-for-test')
        return GenerationResult(self.image, {'testOnly': True})


class WorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = export_catalog(ROOT, HOME)
        cls.settings = json.loads((HOME / 'config/style.json').read_text())
        cls.template = (HOME / 'config/prompt.txt').read_text()
        cls.image = (ROOT / 'assets/images/themes/japan/japan_01.webp').read_bytes()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / 'tools/card-image-generator'
        (self.root / 'lib/data').mkdir(parents=True)
        (self.root / 'lib/data/approved_card_art.dart').write_text('const approvedCardArtIds = <String>{};\n')
        (self.root / 'pubspec.yaml').write_text('flutter:\n  assets:\n    - assets/images/cards/\n')
        # Test fixtures must not depend on which production cards were approved.
        self.cards = [dict(card, isPlaceholderImage=True, finalArtPath=None)
                      for card in self.catalog[:2]]
        self.flow = Workflow(self.root, self.home, self.cards, self.settings, self.template, 'secret-for-test')
        self.addCleanup(self.temp.cleanup)
        self.addCleanup(self.flow.close)

    def test_two_card_review_apply_and_real_catalog_reload(self):
        provider = FixtureProvider(self.image)
        result = self.flow.generate(provider, limit=2)
        self.assertEqual((result['generated'], result['failed']), (2, 0))
        first, second = [c['id'] for c in self.cards]
        self.assertNotIn(self.cards[1]['name'], provider.prompts[0])
        self.assertNotIn(self.cards[0]['name'], provider.prompts[1])
        self.assertFalse((self.root / self.cards[0]['imagePath']).exists())
        with self.assertRaises(ValueError):
            self.flow.apply(first)
        self.flow.review(first, True)
        self.flow.review(second, False, 'Teste de rejeição')
        path = self.flow.apply(first)
        with Image.open(self.root / path) as im:
            self.assertEqual(im.format, 'WEBP')
            self.assertEqual(im.size, (1000, 1024))
        self.assertIn(Path(path).parent.as_posix() + '/', (self.root / 'pubspec.yaml').read_text())
        # Execute the real catalog against the applied static manifest in isolation.
        shutil.copy(ROOT / 'lib/data/cards_data.dart', self.root / 'lib/data/cards_data.dart')
        shutil.copytree(ROOT / 'lib/models', self.root / 'lib/models')
        shutil.copytree(HOME / 'scripts', self.home / 'scripts')
        reloaded = export_catalog(self.root, self.home)
        self.assertFalse(reloaded[0]['isPlaceholderImage'])
        self.assertTrue(reloaded[1]['isPlaceholderImage'])
        self.assertEqual(reloaded[0]['imagePath'], path)
        # New approved versions preserve the previous approval and require --replace.
        previous = self.flow.state(first)['approvedPath']
        self.flow.generate(provider, card_id=first, mode='regenerate')
        self.assertTrue((self.home / previous).exists())
        with self.assertRaises(ValueError):
            self.flow.apply(first)
        self.flow.review(first, True)
        (self.root / path).write_bytes(b'existing asset')
        with self.assertRaises(ValueError):
            self.flow.apply(first)
        self.flow.apply(first, replace=True)
        backup = Path(self.flow.state(first)['backupPath']) / Path(path).name
        self.assertEqual(backup.read_bytes(), b'existing asset')

    def test_failure_continues_and_daily_limit_survives_reopen(self):
        result = self.flow.generate(FixtureProvider(self.image, fail_first=True), limit=2, daily_limit=2)
        self.assertEqual((result['failed'], result['generated']), (1, 1))
        self.assertNotIn('secret-for-test', (self.home / 'logs/events.jsonl').read_text())
        other = Workflow(self.root, self.home, self.cards, self.settings, self.template)
        try:
            result = other.generate(FixtureProvider(self.image), mode='retry-failed', daily_limit=2)
            self.assertEqual(result['attempted'], 0)
            result = other.generate(FixtureProvider(self.image), mode='retry-failed', daily_limit=3)
            self.assertEqual(result['generated'], 1)
        finally:
            other.close()

    def test_corruption_upscale_and_modified_approval_are_blocked(self):
        with self.assertRaises(Exception):
            optimize(b'not an image', self.settings)
        small = io.BytesIO()
        Image.new('RGB', (10, 10)).save(small, 'PNG')
        with self.assertRaises(ValueError):
            optimize(small.getvalue(), self.settings)
        cid = self.cards[0]['id']
        self.flow.generate(FixtureProvider(self.image), card_id=cid)
        self.flow.review(cid, True)
        (self.home / self.flow.state(cid)['approvedPath']).write_bytes(b'changed')
        with self.assertRaises(ValueError):
            self.flow.apply(cid)

    def test_interruption_and_exclusive_lock(self):
        cid = self.cards[0]['id']
        state = self.flow.state(cid)
        state['generationStatus'] = 'generating'
        self.flow.save(cid, state, 'generating')
        other = Workflow(self.root, self.home, self.cards, self.settings, self.template)
        self.assertEqual(other.state(cid)['generationStatus'], 'failed')
        other.close()
        with workflow_lock(self.home):
            with self.assertRaises(RuntimeError):
                with workflow_lock(self.home):
                    pass

    def test_inspection_matches_current_game(self):
        report = inspect_project(ROOT, self.catalog)
        self.assertEqual(report['cards'], 768)
        self.assertEqual(report['format'], 'WEBP')
        self.assertAlmostEqual(report['artworkAspectRatio'], 164 / 168, places=5)

    def test_cli_has_no_paid_api_provider(self):
        import providers
        self.assertFalse(hasattr(providers, 'OpenAIProvider'))
        self.assertNotIn('create_provider', (HOME / 'cards.py').read_text())


if __name__ == '__main__':
    unittest.main()
