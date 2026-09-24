import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import test from 'node:test';

const catalog = JSON.parse(
  readFileSync(new URL('../src/catalog.json', import.meta.url)),
);

test('playable countries expose every level accepted by the client', () => {
  for (const country of ['brazil', 'japan', 'united_states', 'egypt']) {
    const levels = new Set(catalog.countries[country]);
    for (let phase = 1; phase <= 4; phase++) {
      assert.ok(levels.has(`${country}_${String(phase).padStart(2, '0')}`));
    }
    for (const difficulty of ['easy', 'medium', 'hard', 'veryHard']) {
      assert.ok(levels.has(`jigsaw_${country}_${difficulty}`));
      assert.ok(levels.has(`blocks_${country}_${difficulty}`));
    }
  }
});
