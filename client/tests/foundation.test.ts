import { test } from 'node:test';
import assert from 'node:assert/strict';
const expect = (actual: unknown) => ({ toBe: (expected: unknown) => assert.equal(actual, expected) });
import { createLayout, getLayout, pathDistance, LAYOUTS } from '@caps/game-core/board';
import { passiveBonus, passiveActive, conditionMet } from '@caps/game-core/passives';
import { previewTurn } from '@caps/game-core/preview';
import type { ChainCap, CapTypeDef, Passive, ChainGame } from '@caps/game-core/types';
const piece = (id: number, slot: number, x: number|null, y: number|null): ChainCap => ({id,playerSlot:slot,owner:'0x1',setId:0,capType:id,x,y,health:10,shield:0,stunnedTurns:0,availableTurn:0,dead:false});
const passive = (conditions: Passive['conditions'] = []): Passive => ({kind:'AttackBonus',amount:3,target:{kind:'SelfCap'},conditions});
const def = (id: number, passives: Passive[] = []): CapTypeDef => ({id,name:'Test',description:'',maxHealth:20,attack:1,moveRange:1,attackRange:1,playCost:0,moveCost:0,abilityCost:0,abilityDescription:'',abilityTarget:0,abilityRange:1,passives});
const layout = getLayout(0);

test('distance follows path bends, diagonal edges, and junctions without corner shortcuts', () => {
 expect(pathDistance(layout,[1,0],[0,1])).toBe(2);
 expect(pathDistance(layout,[2,0],[2,4])).toBe(8);
 expect(pathDistance(getLayout(1),[2,0],[2,4])).toBe(4);
 expect(pathDistance(getLayout(2),[0,0],[1,1])).toBe(1);
 expect(pathDistance(getLayout(3),[2,0],[3,2])).toBe(2);
 expect(pathDistance(layout,[1,1],[1,1])).toBe(Infinity);
});
test('an explicit edge counts once regardless of coordinates; disconnected tiles stay unreachable', () => {
 const custom=createLayout({id:99,name:'Test',description:'',width:10,height:10,p1Deploy:[0,0],p2Deploy:[9,9]},[[[0,0],[8,7],[9,9]],[[1,0]]]);
 expect(pathDistance(custom,[0,0],[8,7])).toBe(1);
 expect(pathDistance(custom,[0,0],[9,9])).toBe(2);
 expect(pathDistance(custom,[0,0],[1,0])).toBe(Infinity);
});
test('every layout has symmetric distances, exactly one-step edges, and no unreachable path nodes', () => {
 for(const l of Object.values(LAYOUTS)) for(let x=0;x<l.width;x++) for(let y=0;y<l.height;y++) {
  if(!l.isWalkable(x,y))continue;
  expect(pathDistance(l,[x,y],[x,y])).toBe(0);
  for(let a=0;a<l.width;a++)for(let b=0;b<l.height;b++)if(l.isWalkable(a,b)) {
   const d=pathDistance(l,[x,y],[a,b]);
   expect(Number.isFinite(d)).toBe(true);expect(d).toBe(pathDistance(l,[a,b],[x,y]));
   expect(d===1).toBe(l.neighbors([x,y]).some(p=>p[0]===a&&p[1]===b));
  }
 }
});
test('continuous passive exists only on board; stun does not disable it', () => {
 const c=piece(1,0,1,0),p=passive();
 expect(passiveActive(p,c,20,[c],layout)).toBe(true);
 c.stunnedTurns=1; expect(passiveActive(p,c,20,[c],layout)).toBe(true);
 c.x=null;c.y=null;expect(passiveActive(p,c,20,[c],layout)).toBe(false);
 c.x=1;c.y=0;c.dead=true;expect(passiveActive(p,c,20,[c],layout)).toBe(false);
});
test('same-row requirement excludes self and uses side identity even with a shared account', () => {
 const c=piece(1,0,1,0),ally=piece(2,0,3,0),enemy=piece(3,1,4,0);
 const p=passive([{kind:'PieceInRow',relation:'Ally'}]);
 expect(passiveActive(p,c,20,[c,enemy],layout)).toBe(false);
 expect(passiveActive(p,c,20,[c,ally,enemy],layout)).toBe(true);
 ally.y=4;expect(passiveActive(p,c,20,[c,ally,enemy],layout)).toBe(false);
 expect(passiveActive(passive([{kind:'PieceInRow',relation:'Enemy'}]),c,20,[c,enemy],layout)).toBe(true);
});
test('all conditions apply; health threshold is a percentage and distance uses the path', () => {
 const c=piece(1,0,1,0),ally=piece(2,0,0,1);
 expect(conditionMet({kind:'AllyWithin',value:1},c,20,[c,ally],layout)).toBe(false);
 const p=passive([{kind:'AllyWithin',value:2},{kind:'HealthBelowPercent',value:50}]);
 expect(passiveActive(p,c,20,[c,ally],layout)).toBe(false);
 c.health=9;expect(passiveActive(p,c,20,[c,ally],layout)).toBe(true);
});
test('auras stack and disappear immediately on leaving range or losing a prerequisite', () => {
 const a=piece(1,0,0,0),b=piece(2,0,1,0),c=piece(3,0,0,1);
 const aura:Passive={...passive(),target:{kind:'AlliesWithin',radius:1}};
 const defs=new Map([[1,def(1,[aura])],[2,def(2)],[3,def(3,[{...aura,target:{kind:'AlliesWithin',radius:2}}])]]);
 expect(passiveBonus('AttackBonus',b,[a,b,c],defs,layout)).toBe(6);
 c.x=null;c.y=null;expect(passiveBonus('AttackBonus',b,[a,b,c],defs,layout)).toBe(3);
 b.x=2;expect(passiveBonus('AttackBonus',b,[a,b,c],defs,layout)).toBe(0);
});
test('queued movement removes a conditional bonus before the next attack', () => {
 const runner=piece(5,0,1,4),ally=piece(2,0,0,4),enemy=piece(3,1,2,4);
 const p=passive([{kind:'PieceInRow',relation:'Ally'}]);
 const defs=new Map([[5,{...def(5,[p]),abilityTarget:1}],[2,def(2)],[3,def(3)]]);
 const game:ChainGame={id:1,player1:'0x1',player2:'0x2',layout:0,setId:0,turnCount:0,over:false,winner:'0x0',winnerSlot:2,energy:3,p1Energy:3,p2Energy:3,effectIds:[],caps:[runner,ally,enemy]};
 const result=previewTurn(game,null,defs,layout,[{capId:5,kind:'Ability',x:1,y:4},{capId:2,kind:'Move',x:0,y:3},{capId:5,kind:'Move',x:2,y:4}]);
 expect(result.caps.find(c=>c.id===3)!.health).toBe(9);
});

test('large board uses path steps, its own goal, and its own enemy half', () => {
 const large=getLayout(4);
 expect(pathDistance(large,[3,0],[3,2])).toBe(1);
 const c=piece(1,0,3,6), defs=new Map([[1,def(1)]]);
 const game:ChainGame={id:1,player1:'0x1',player2:'0x2',layout:4,setId:0,turnCount:0,over:false,winner:'0x0',winnerSlot:2,energy:1,p1Energy:1,p2Energy:1,caps:[c],effectIds:[]};
 expect(previewTurn(game,null,defs,large,[{capId:1,kind:'Move',x:3,y:8}]).winnerSlot).toBe(0);
 c.y=3; expect(conditionMet({kind:'OnEnemyHalf'},c,20,[c],large)).toBe(false);
 c.y=6; expect(conditionMet({kind:'OnEnemyHalf'},c,20,[c],large)).toBe(true);
});
