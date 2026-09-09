import {test} from 'node:test';
import assert from 'node:assert/strict';
import {decodeTurnRecord} from '@caps/game-core/decode';
import {encodeActions} from '@caps/game-core/encode';
import {actionLabel, turnOutcomes} from '../src/lib/game/history';
test('turn journal decodes passes, stable stack IDs and before/after piece changes',()=>{
 const before=[13,0,6,1,0,0,6,0,0,0], after=[13,0,6,1,1,0,4,2,0,0];
 const raw=[0,3,8,1,0, ...encodeActions([{capId:13,kind:'StackAbility',targetId:300}]),1,...before,1,...after,0,0,0,5,3].map(String);
 const record=decodeTurnRecord(raw)!;
 assert.equal(record.turn,8);assert.deepEqual(record.actions,[{capId:13,kind:'StackAbility',targetId:300}]);
 assert.match(actionLabel(record.actions[0],record.before,new Map()),/effect #300/);
 assert.deepEqual(turnOutcomes(record,new Map()),['P1 piece #13: A1 → B1','P1 piece #13: HP 6 → 4','P1 piece #13: shield 0 → 2']);
 assert.equal(decodeTurnRecord(['1']),null);
 assert.throws(()=>decodeTurnRecord(raw.slice(0,-1)),/Truncated/);
});
