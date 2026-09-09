import { test } from 'node:test';
import assert from 'node:assert/strict';
import { schedule, counterPending, popReady, resolveImpact, resolveReadyStack } from '@caps/game-core/stack';
import { decodeStack } from '@caps/game-core/decode';
import { getLayout } from '@caps/game-core/board';
import { previewTurn } from '@caps/game-core/preview';
import type { AbilityStack, ChainCap, CapTypeDef, DelayedImpact, ChainGame } from '@caps/game-core/types';
const layout = getLayout(0);
const empty = ():AbilityStack => ({gameId:1,nextId:0,entries:[]});
const impact = (kind:DelayedImpact['kind']='Damage',amount=4):DelayedImpact => ({kind,amount,selection:{kind:'Row',index:0},relation:'Any'});
const piece = (id:number,slot:number,x:number|null,y:number|null):ChainCap => ({id,owner:'0x123',playerSlot:slot,capType:id,setId:0,x,y,health:6,shield:0,dead:false,stunnedTurns:0,availableTurn:0});
const def = (id:number):CapTypeDef => ({id,name:'Test',description:'',maxHealth:6,attack:1,moveRange:1,attackRange:1,playCost:0,moveCost:0,abilityCost:3,abilityDescription:'',abilityTarget:5,abilityRange:3,passives:[]});
const defs = new Map([1,2,3,4].map(id=>[id,def(id)]));

test('one-turn delay gives a full opponent turn; newer unready responses block older effects',()=>{
 const stack=empty();schedule(stack,1,0,0,1,impact(),layout);
 assert.equal(popReady(stack,1),null);assert.equal(stack.entries[0].readyTurn,2);
 schedule(stack,2,1,1,1,impact('Shield'),layout);
 assert.equal(popReady(stack,2),null);
 assert.equal(popReady(stack,3)!.id,2);assert.equal(popReady(stack,3)!.id,1);assert.equal(popReady(stack,3),null);
});
test('newest shield resolves before older damage; resolution does not mutate input',()=>{
 const stack=empty();schedule(stack,1,0,0,1,impact(),layout);schedule(stack,2,1,1,1,impact('Shield'),layout);
 const caps=[piece(1,0,1,0),piece(2,1,3,0)];
 const result=resolveReadyStack(stack,caps,defs,layout,3);
 assert.deepEqual(result.resolved,[2,1]);assert.equal(result.caps[0].health,6);assert.equal(result.caps[0].shield,0);
 assert.equal(stack.entries.length,2);assert.equal(caps[0].shield,0);
});
test('row targets are chosen at resolution, even if source is gone',()=>{
 const stack=empty();schedule(stack,99,0,0,1,impact(),layout);
 const escaped=piece(1,1,0,1),arrived=piece(2,1,3,0),friend=piece(3,0,1,0);
 const result=resolveImpact(stack.entries[0],[escaped,arrived,friend],defs,layout);
 assert.deepEqual(result.map(c=>c.health),[6,2,2]);
});
test('counter removes an item permanently and IDs are not reused',()=>{
 const stack=empty();schedule(stack,1,0,0,1,impact(),layout);schedule(stack,2,1,1,1,impact(),layout);
 counterPending(stack,2);counterPending(stack,500);
 assert.equal(popReady(stack,2)!.id,1);
 schedule(stack,1,0,2,1,impact(),layout);assert.equal(stack.entries[0].id,3);
});
test('missing or captured piece targets fizzle; friendly filtering uses slots',()=>{
 const stack=empty();schedule(stack,1,0,0,1,{...impact(),selection:{kind:'Piece',id:3}},layout);
 const bench=piece(3,1,null,null);assert.equal(resolveImpact(stack.entries[0],[bench],defs,layout)[0].health,6);
 stack.entries[0].impact={...impact(),relation:'Enemy'};
 assert.deepEqual(resolveImpact(stack.entries[0],[piece(1,0,1,0),piece(2,1,3,0)],defs,layout).map(c=>c.health),[6,2]);
});
test('area mitigation uses one snapshot even when its aura source dies first',()=>{
 const stack=empty();schedule(stack,99,1,0,1,impact('Damage',8),layout);
 const source=piece(1,0,0,0),target=piece(2,0,1,0);
 const aura={...def(1),passives:[{kind:'DamageReduction' as const,amount:4,target:{kind:'AlliesWithin' as const,radius:1},conditions:[]}]};
 const result=resolveImpact(stack.entries[0],[source,target],new Map([[1,aura],[2,def(2)]]),layout);
 assert.equal(result[0].dead,true);assert.equal(result[1].health,2);
});
test('stack decoder handles stored ordering and structured target payloads',()=>{
 const stack=decodeStack([1,2,2,1,11,0,0,2,0,1,4,2,4,2,12,1,1,3,2,3,2,2,2,0,3].map(String));
 assert.equal(stack.entries[0].impact.selection.kind,'Row');
 assert.deepEqual(stack.entries[1].impact,{kind:'Shield',selection:{kind:'Within',x:2,y:2,radius:2},relation:'Ally',amount:3});
 assert.throws(()=>decodeStack(['1','0','1']),/Truncated/);
});
test('Blaster preview schedules the row instead of applying immediate damage',()=>{
 const caps=[piece(4,0,1,0),piece(2,1,3,0)];
 const game:ChainGame={id:1,player1:'0x1',player2:'0x2',layout:0,setId:0,turnCount:0,over:false,winner:'0x0',winnerSlot:2,energy:3,p1Energy:3,p2Energy:0,effectIds:[],caps};
 const result=previewTurn(game,null,defs,layout,[{capId:4,kind:'Ability',x:3,y:0}],empty());
 assert.equal(result.caps[1].health,6);assert.equal(result.energy,0);assert.equal(result.actions,1);
 assert.equal(result.stack.entries[0].readyTurn,2);assert.deepEqual(result.stack.entries[0].impact,impact());
});
test('limits reject zero delay and stack growth beyond 32 entries',()=>{
 const stack=empty();assert.throws(()=>schedule(stack,1,0,0,0,impact(),layout),/Delay/);
 for(let i=0;i<32;i++)schedule(stack,1,0,0,1,impact(),layout);
 assert.throws(()=>schedule(stack,1,0,0,1,impact(),layout),/full/);
});

test('delayed zones use path distance and column selections span the board',()=>{
 const stack=empty();schedule(stack,99,0,0,1,{...impact(),selection:{kind:'Within',x:1,y:0,radius:1}},layout);
 const caps=[piece(1,0,0,1),piece(2,1,0,0)];
 assert.deepEqual(resolveImpact(stack.entries[0],caps,defs,layout).map(c=>c.health),[6,2]);
 stack.entries[0].impact.selection={kind:'Column',index:0};
 assert.deepEqual(resolveImpact(stack.entries[0],caps,defs,layout).map(c=>c.health),[2,2]);
});

// Svelte $state wraps objects and nested values in proxies, which structuredClone rejects.
function reactive<T extends object>(value: T): T {
 return new Proxy(value, { get(target, key, receiver) {
  const child = Reflect.get(target, key, receiver);
  return child !== null && typeof child === 'object' ? reactive(child) : child;
 } });
}
test('game loading previews an empty reactive stack without a DataCloneError', () => {
 const pending = reactive(empty());
 const game = {id:1,caps:[],energy:1,over:false,turnCount:0} as unknown as ChainGame;
 const result = previewTurn(game, null, defs, layout, [], pending);
 assert.deepEqual(result.stack, empty());
 assert.equal(result.energy, 1);
});
test('reactive delayed impacts can be copied, scheduled and resolved without mutating input', () => {
 const pending = empty();
 schedule(pending, 1, 0, 0, 1, reactive(impact()), layout);
 const before = JSON.stringify(pending);
 const game = {id:1,caps:[piece(1,0,1,0)],energy:1,over:false,turnCount:1} as unknown as ChainGame;
 const result = previewTurn(game, null, defs, layout, [], reactive(pending));
 if (result.stack.entries[0].impact.selection.kind === 'Row') result.stack.entries[0].impact.selection.index = 4;
 assert.equal(JSON.stringify(pending), before);
 const resolved = resolveReadyStack(reactive(pending), game.caps, defs, layout, 2);
 assert.equal(resolved.caps[0].health, 2);
 assert.equal(resolved.stack.entries.length, 0);
 assert.equal(JSON.stringify(pending), before);
});

test('stack-target abilities encode stable IDs and preserve the normal action',()=>{
 const negator=piece(13,0,0,0);negator.capType=6;
 const definitions=new Map(defs);definitions.set(6,{...def(6),abilityTarget:7,abilityCost:2});
 const game={id:1,caps:[negator],energy:5,over:false,turnCount:0} as unknown as ChainGame;
 const pending=empty();schedule(pending,2,1,0,1,impact(),layout);schedule(pending,3,1,0,1,impact(),layout);
 const result=previewTurn(game,null,definitions,layout,[{capId:13,kind:'StackAbility',targetId:1}],reactive(pending));
 assert.deepEqual(result.stack.entries.map(e=>e.id),[2]);assert.equal(result.energy,3);assert.equal(result.actions,1);
 assert.equal(pending.entries.length,2);
 assert.throws(()=>previewTurn(game,null,definitions,layout,[{capId:13,kind:'StackAbility',targetId:99}],pending),/Invalid pending/);
 assert.throws(()=>previewTurn(game,null,definitions,layout,[{capId:13,kind:'StackAbility',targetId:1},{capId:13,kind:'StackAbility',targetId:2}],pending),/once per turn/);
});

test('a winning preview clears pending effects without changing confirmed state',()=>{
 const pending=empty();schedule(pending,2,1,0,1,impact(),layout);
 const game={id:1,caps:[piece(1,0,1,4)],energy:1,over:false,turnCount:0} as unknown as ChainGame;
 const result=previewTurn(game,null,defs,layout,[{capId:1,kind:'Move',x:2,y:4}],pending);
 assert.equal(result.winnerSlot,0);assert.equal(result.stack.entries.length,0);assert.equal(pending.entries.length,1);
});
