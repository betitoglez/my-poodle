import * as THREE from 'three';

export function makeFrisbee() {
  const group = new THREE.Group();
  const ring = new THREE.Group();
  const edging = new THREE.MeshStandardMaterial({color: '#edd68e', roughness: .54, metalness: .12});
  const centerLine = new THREE.MeshStandardMaterial({color: '#fff2c7', roughness: .64});
  for (const [radius, width, surface] of [[1,.037,edging],[.51,.016,centerLine]]) {
    ring.add(new THREE.Mesh(new THREE.TorusGeometry(radius,width,10,52),surface));
  }
  const inset = new THREE.Mesh(new THREE.CircleGeometry(.98,48), new THREE.MeshBasicMaterial({
    color: '#fff1c3', transparent: true, opacity: .15, depthWrite: false,
  }));
  inset.position.z = -.055;
  ring.add(inset);
  group.add(ring);

  const disc = new THREE.Group();
  const plastic = new THREE.MeshStandardMaterial({color: '#d35941', roughness: .43});
  const raised = new THREE.MeshStandardMaterial({color: '#ff9963', roughness: .37});
  const model = new THREE.LatheGeometry([
    [0,-.045],[.64,-.044],[.86,-.075],[.97,-.073],[1,-.012],[.978,.049],
    [.87,.098],[.78,.124],[.52,.139],[0,.141],
  ].map(row => new THREE.Vector2(...row)),44);
  disc.add(new THREE.Mesh(model, plastic));
  const trim = new THREE.Mesh(new THREE.TorusGeometry(.77,.018,8,44),raised);
  trim.rotation.x = -Math.PI/2;
  trim.position.y = .108;
  disc.add(trim);
  const dash = new THREE.Mesh(new THREE.BoxGeometry(.72,.014,.10),raised);
  dash.position.set(0,.145,.01);
  disc.add(dash);
  group.add(disc);

  const plane = new THREE.Vector3(), mouth = new THREE.Vector3();
  const projected = new THREE.Vector3();
  function at(camera,x,y,z,point) {
    const depth = plane.set(0,0,z).project(camera).z;
    return point.set(x*2-1,1-y*2,depth).unproject(camera);
  }

  function update(state, camera, dog, turntable, reduced) {
    ring.visible = state.length >= 13;
    if (!ring.visible) {
      disc.visible = false;
      return;
    }
    const [x,y,height,face,,tx,ty,rx,ry,dx,dy,visible,time] = state;
    const wide = camera.right-camera.left, high = camera.top-camera.bottom;
    const depth = (1-y)*1.3;
    at(camera,x,y,-depth,turntable.position);
    turntable.rotation.y = face * 1.25;
    dog.scale.setScalar(height*high);
    at(camera,tx,ty,-depth-.12,ring.position);
    ring.quaternion.copy(camera.quaternion);
    ring.scale.set(rx*wide,ry*high,.32);
    disc.visible = visible > 0;
    if (!disc.visible) return;
    if (visible === 2) {
      dog.localToWorld(mouth.set(0,.735,.56));
      disc.position.copy(mouth);
      disc.scale.setScalar(Math.max(.11,height*high*.23));
    } else {
      at(camera,dx,dy,.2,projected);
      disc.position.copy(projected);
      disc.scale.setScalar(.34-.10*Math.min(1,Math.max(0,(.89-dy)*1.9)));
    }
    disc.rotation.set(.12, reduced ? 0 : time*7, visible === 2 ? -.11 : .11*Math.sin(time*4));
  }
  return { group, update };
}
