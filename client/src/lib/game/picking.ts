import { Plane, Raycaster, Vector2, Vector3, type Camera } from 'three';
import { boardPosition } from './presentation';
import type { LayoutConfig } from '@caps/game-core/board';

/** Pointer coordinates to canonical map coordinates, including the player's view rotation. */
export function pickBoardCell(camera: Camera, rect: {left:number;top:number;width:number;height:number}, px:number, py:number, layout:LayoutConfig, viewer:number|null) {
    if (rect.width <= 0 || rect.height <= 0 || px < rect.left || py < rect.top || px >= rect.left+rect.width || py >= rect.top+rect.height) return null;
    const scale = 5 / Math.max(layout.width,layout.height);
    const ray = new Raycaster();
    camera.updateMatrixWorld();
    ray.setFromCamera(new Vector2((px-rect.left)/rect.width*2-1, 1-(py-rect.top)/rect.height*2),camera);
    const point = ray.ray.intersectPlane(new Plane(new Vector3(0,1,0),-0.08*scale),new Vector3());
    if (!point) return null;
    const x = Math.round(point.x/scale+(layout.width-1)/2), y = Math.round(point.z/scale+(layout.height-1)/2);
    const [cx,cy] = boardPosition(layout,x,y,viewer);
    return layout.isWalkable(cx,cy) ? {x:cx+0,y:cy+0} : null;
}
