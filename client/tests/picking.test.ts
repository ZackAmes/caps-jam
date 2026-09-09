import { test } from 'node:test';
import assert from 'node:assert/strict';
import { PerspectiveCamera, Vector3 } from 'three';
import { LAYOUTS } from '@caps/game-core/board';
import { boardPosition } from '../src/lib/game/presentation';
import { pickBoardCell } from '../src/lib/game/picking';

test('3D drops map to every canonical tile from either player view at mobile and desktop sizes', () => {
 const camera = new PerspectiveCamera(43,1,0.1,1000);
 camera.position.set(0,7.8,5.5); camera.lookAt(0,0,0); camera.updateMatrixWorld();
 for(const size of [280,390,800]) for(const layout of Object.values(LAYOUTS)) for(const viewer of [0,1]) {
  const rect={left:15,top:90,width:size,height:size},scale=5/Math.max(layout.width,layout.height);
  for(let y=0;y<layout.height;y++)for(let x=0;x<layout.width;x++) {
   const [sx,sy]=boardPosition(layout,x,y,viewer);
   const projected=new Vector3((sx-(layout.width-1)/2)*scale,0.08*scale,(sy-(layout.height-1)/2)*scale).project(camera);
   const hit=pickBoardCell(camera,rect,rect.left+(projected.x+1)*size/2,rect.top+(1-projected.y)*size/2,layout,viewer);
   assert.deepEqual(hit,layout.isWalkable(x,y)?{x,y}:null);
  }
  assert.equal(pickBoardCell(camera,rect,14,100,layout,viewer),null);
  assert.equal(pickBoardCell(camera,rect,20,90+size,layout,viewer),null);
 }
});
