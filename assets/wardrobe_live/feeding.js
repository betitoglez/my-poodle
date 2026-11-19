import * as THREE from 'three';

// The resting muzzle in the Blender clip lies 0.47 units ahead of the rig.
const centerZ = 0.473;
const rimHeight = 0.157;
const rimRadius = 0.161;

export function makeFeedingBowl() {
  const group = new THREE.Group();
  group.position.set(-0.013, 0, centerZ);
  group.visible = false;

  const profile = [
    [0, 0.012], [0.111, 0.012], [0.129, 0.017], [0.141, 0.036],
    [0.154, 0.088], [0.159, 0.137], [rimRadius, 0.147], [0.157, rimHeight],
    [0.148, rimHeight + 0.002], [0.143, 0.151], [0.140, 0.129],
    [0.128, 0.082], [0.109, 0.049], [0.090, 0.041], [0, 0.041],
  ].map(([radius, height]) => new THREE.Vector2(radius, height));
  const dish = new THREE.Mesh(
    new THREE.LatheGeometry(profile, 64),
    new THREE.MeshStandardMaterial({ color: '#be754d', roughness: 0.39 }),
  );
  group.add(dish);

  const lip = new THREE.Mesh(
    new THREE.TorusGeometry(0.151, 0.0046, 8, 64),
    new THREE.MeshStandardMaterial({ color: '#e6bb8d', roughness: 0.43 }),
  );
  lip.rotation.x = -Math.PI / 2;
  lip.position.y = rimHeight;
  group.add(lip);

  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 64;
  const context = canvas.getContext('2d');
  const gradient = context.createRadialGradient(32, 32, 8, 32, 32, 31);
  gradient.addColorStop(0, 'rgba(46, 27, 28, 0.44)');
  gradient.addColorStop(1, 'rgba(46, 27, 28, 0)');
  context.fillStyle = gradient;
  context.fillRect(0, 0, 64, 64);
  const shadow = new THREE.Mesh(
    new THREE.PlaneGeometry(0.43, 0.38),
    new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(canvas), transparent: true, depthWrite: false }),
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = 0.001;
  group.add(shadow);

  const count = 110;
  const food = new THREE.InstancedMesh(
    new THREE.IcosahedronGeometry(1, 1),
    new THREE.MeshStandardMaterial({ color: '#ffffff', roughness: 0.93 }),
    count,
  );
  food.frustumCulled = false;
  group.add(food);
  const sample = new THREE.Object3D();
  const shades = ['#765031', '#a47146', '#95613a', '#b27d50', '#825337'].map(value => new THREE.Color(value));
  for (let i = 0; i < count; i++) food.setColorAt(i, shades[i % shades.length]);
  let lastFill;

  function fill(amount) {
    if (amount === lastFill) return;
    lastFill = amount;
    food.count = Math.round(count * amount);
    for (let i = 0; i < food.count; i++) {
      const phi = i * 2.399963 + (i % 3) * 0.09;
      // Keep the remaining pieces on the same spiral so the pile also shrinks in area.
      const fraction = (i + 0.5) / count;
      const r = 0.121 * Math.sqrt(fraction);
      const height = 0.065 + amount * (0.022 + 0.046 * (1 - fraction));
      const jitter = 0.011 * ((i * 73) % 19) / 18;
      sample.position.set(Math.cos(phi) * r, height + jitter, Math.sin(phi) * r);
      sample.rotation.set(phi * 1.2, phi * 0.7, i * 0.5);
      const scale = 0.009 + (i % 4) * 0.00125;
      sample.scale.set(scale, scale * 0.70, scale * 0.87);
      sample.updateMatrix();
      food.setMatrixAt(i, sample.matrix);
    }
    food.instanceMatrix.needsUpdate = true;
  }

  function screenBounds(camera) {
    const point = new THREE.Vector3();
    let left = 1, top = 1, right = 0, bottom = 0;
    for (const height of [0.012, rimHeight + 0.005]) {
      for (let i = 0; i < 24; i++) {
        const a = i * Math.PI / 12;
        const radius = height === 0.012 ? 0.126 : rimRadius;
        point.set(Math.cos(a) * radius, height, Math.sin(a) * radius);
        group.localToWorld(point).project(camera);
        const x = (point.x + 1) / 2;
        const y = (1 - point.y) / 2;
        left = Math.min(left, x);
        top = Math.min(top, y);
        right = Math.max(right, x);
        bottom = Math.max(bottom, y);
      }
    }
    return [left, top, right, bottom];
  }
  fill(1);
  return { group, fill, screenBounds };
}
