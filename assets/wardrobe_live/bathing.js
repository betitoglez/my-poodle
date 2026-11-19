import * as THREE from 'three';

// This order matches BathZone.values in the activity.
const anchors = [
  [-0.106, 0.577, -0.183], // Back
  [-0.092, 0.258, 0.203],  // Paws
  [-0.090, 0.528, 0.252],  // Chest
  [-0.065, 0.908, 0.378],  // Head
];

const clusters = [
  [[-0.103, 0.589, -0.238], [-0.119, 0.614, -0.120], [-0.077, 0.668, -0.058], [0.02, 0.664, -0.20]],
  [[-0.115, 0.252, 0.213], [0.105, 0.249, 0.218], [-0.119, 0.250, -0.275], [0.115, 0.243, -0.284]],
  [[-0.119, 0.532, 0.206], [-0.096, 0.465, 0.242], [-0.032, 0.501, 0.283], [0.06, 0.510, 0.272]],
  [[-0.100, 0.955, 0.327], [-0.058, 0.998, 0.316], [0.023, 1.005, 0.299], [-0.115, 0.915, 0.369]],
];

function lathe(profile, material) {
  const mesh = new THREE.Mesh(
    new THREE.LatheGeometry(profile.map(([r, y]) => new THREE.Vector2(r, y)), 64),
    material,
  );
  mesh.scale.x = 0.67;
  return mesh;
}

export function makeBath() {
  const group = new THREE.Group();
  group.visible = false;

  const tub = new THREE.Group();
  tub.position.z = -0.016;
  const ceramic = new THREE.MeshStandardMaterial({
    color: '#b5a4c7', roughness: 0.43, metalness: 0.01,
  });
  const porcelain = new THREE.MeshStandardMaterial({
    color: '#f5eaf4', roughness: 0.32,
  });
  tub.add(lathe([
    [0, 0.015], [0.363, 0.014], [0.416, 0.024], [0.459, 0.050],
    [0.518, 0.111], [0.561, 0.164], [0.568, 0.192],
    [0.556, 0.212], [0.532, 0.215], [0.513, 0.207],
    [0.497, 0.178], [0.448, 0.095], [0.403, 0.042], [0, 0.042],
  ], ceramic));
  tub.add(lathe([
    [0.557, 0.204], [0.558, 0.213], [0.550, 0.224],
    [0.535, 0.225], [0.523, 0.216], [0.515, 0.207],
  ], porcelain));
  const water = new THREE.Mesh(
    new THREE.CircleGeometry(0.458, 64),
    new THREE.MeshStandardMaterial({
      color: '#a5d5df', roughness: 0.26, transparent: true, opacity: 0.62, depthWrite: false,
    }),
  );
  water.rotation.x = -Math.PI / 2;
  water.scale.x = 0.67;
  water.position.y = 0.116;
  tub.add(water);
  group.add(tub);

  const bubbleShape = new THREE.IcosahedronGeometry(1, 1);
  const bubbleSurface = new THREE.MeshStandardMaterial({
    color: '#ffffff', roughness: 0.31, metalness: 0.02,
  });
  const shades = ['#f7eef5', '#d9edf1', '#fff9f1', '#f8f9ff'].map(color => new THREE.Color(color));
  const n = 58;
  const sample = new THREE.Object3D();
  const foam = clusters.map((sources, zone) => {
    const bubbles = new THREE.InstancedMesh(bubbleShape, bubbleSurface, n);
    bubbles.frustumCulled = false;
    for (let i = 0; i < n; i++) {
      const [x, y, z] = sources[i % sources.length];
      const a = i * 2.399963;
      const r = 0.018 + 0.039 * (((i * 71) % n) / n);
      const h = ((i * 23) % 13) / 12 - 0.36;
      sample.position.set(x + Math.cos(a) * r * 0.65, y + h * r, z + Math.sin(a) * r);
      const size = 0.014 + 0.023 * (((i * 17 + zone * 5) % n) / n);
      sample.scale.set(size, size * 0.78, size * 0.95);
      sample.updateMatrix();
      bubbles.setMatrixAt(i, sample.matrix);
      bubbles.setColorAt(i, shades[i % shades.length]);
    }
    bubbles.count = 0;
    group.add(bubbles);
    return bubbles;
  });

  function update(phase, progress, suds) {
    for (let i = 0; i < foam.length; i++) {
      const amount = phase === 2 ? suds[i] * (1 - progress) : phase === 1 ? suds[i] : 0;
      foam[i].count = Math.round(n * amount);
    }
    water.material.opacity = phase === 3 ? 0.62 - progress * 0.15 : 0.62;
  }

  function screenTargets(camera) {
    const point = new THREE.Vector3();
    return anchors.flatMap(anchor => {
      group.localToWorld(point.fromArray(anchor)).project(camera);
      return [(point.x + 1) / 2, (1 - point.y) / 2];
    });
  }

  return { group, update, screenTargets };
}
