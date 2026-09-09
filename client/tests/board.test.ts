import { test } from 'node:test';
import assert from 'node:assert/strict';
import { LAYOUTS, isValidStep } from '@caps/game-core/board';

test('every track rejects off-board and fractional coordinates', () => {
  for (const layout of Object.values(LAYOUTS)) {
    for (const [x, y] of [[-1, 0], [0, -1], [layout.width, 0], [0, layout.height], [1.5, 0]]) {
      assert.equal(layout.isWalkable(x, y), false);
    }
    assert.equal(isValidStep(layout.id, [0, 0], [-1, 0]), false);
    assert.equal(isValidStep(layout.id, [4, 4], [5, 4]), false);
  }
});

test('all layouts retain bases, objectives, and explicit valid moves', () => {
  for (const layout of Object.values(LAYOUTS)) {
    for (const [x, y] of [layout.p1Deploy, layout.p2Deploy, ...(layout.energySpaces ?? [])]) {
      assert.equal(layout.isWalkable(x, y), true);
    }
    for (const next of layout.neighbors(layout.p1Deploy)) assert.equal(isValidStep(layout.id, layout.p1Deploy, next), true);
    assert.equal(isValidStep(layout.id, [0, 0], [0, 0]), false);
    assert.equal(isValidStep(layout.id, [0, 0], [2, 0]), false);
  }
});
