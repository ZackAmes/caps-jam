import {test} from 'node:test';
import assert from 'node:assert/strict';
import {consistentSnapshot, submissionHasLanded} from '../src/lib/game/sync';
test('a turn advancing midway through RPC reads never installs mixed state', async()=>{
 const turns=[0,1,1,1]; const detailsRead:number[]=[];
 const result=await consistentSnapshot(async()=>({turnCount:turns.shift()!,over:false}),async game=>{detailsRead.push(game.turnCount);return {stackTurn:game.turnCount};});
 assert.deepEqual(detailsRead,[0,1]);assert.equal(result.game.turnCount,1);assert.equal(result.details.stackTurn,1);
});
test('confirmation with stale RPC state keeps the submission pending',async()=>{
 await assert.rejects(()=>consistentSnapshot(async()=>({turnCount:3,over:false}),async()=>({}),4),/waiting for the RPC/);
 assert.equal(submissionHasLanded({turn:3,confirmed:true},3),false);
 assert.equal(submissionHasLanded({turn:3,confirmed:false},4),false);
 assert.equal(submissionHasLanded({turn:3,confirmed:true},4),true);
});
