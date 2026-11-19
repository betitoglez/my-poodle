import * as THREE from 'three';

const radius = 0.685;
const oval = 0.57;
const mattress = 0.132;
const smooth = THREE.MathUtils.smoothstep;

function upholstery(profile, color, weave) {
  const mesh = new THREE.Mesh(
    new THREE.LatheGeometry(profile.map(([r, y]) => new THREE.Vector2(r * .89, y)), 72),
    new THREE.MeshStandardMaterial({ color, roughness: 0.92, bumpMap: weave, bumpScale: 0.016 }),
  );
  mesh.scale.x = oval;
  return mesh;
}

function fabricWeave() {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 64;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#777';
  ctx.fillRect(0, 0, 64, 64);
  for (let y = 0; y < 64; y += 4) {
    for (let x = 0; x < 64; x += 4) {
      ctx.fillStyle = (x + y) % 8 ? '#8d8d8d' : '#606060';
      ctx.fillRect(x, y, 2, 3);
      ctx.fillRect(x + 2, y + 1, 2, 3);
    }
  }
  const map = new THREE.CanvasTexture(canvas);
  map.wrapS = map.wrapT = THREE.RepeatWrapping;
  map.repeat.set(12, 3);
  return map;
}

function contactShadow() {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 64;
  const ctx = canvas.getContext('2d');
  const falloff = ctx.createRadialGradient(32, 32, 18, 32, 32, 31);
  falloff.addColorStop(0, 'rgba(67, 35, 35, 0.52)');
  falloff.addColorStop(0.64, 'rgba(67, 35, 35, 0.29)');
  falloff.addColorStop(1, 'rgba(67, 35, 35, 0)');
  ctx.fillStyle = falloff;
  ctx.fillRect(0, 0, 64, 64);
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(1.05, 1.78),
    new THREE.MeshBasicMaterial({ map: new THREE.CanvasTexture(canvas), transparent: true, depthWrite: false }));
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.y = 0.013;
  return mesh;
}

function piping(r, y, thickness, color) {
  const points = Array.from({ length: 72 }, (_, i) => {
    const angle = i / 72 * Math.PI * 2;
    return new THREE.Vector3(Math.cos(angle) * r * oval * .89, y, Math.sin(angle) * r * .89);
  });
  return new THREE.Mesh(
    new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points, true), 84, thickness, 8, true),
    new THREE.MeshStandardMaterial({ color, roughness: 0.88 }),
  );
}

function textile() {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 384;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#ddad91';
  ctx.fillRect(0, 0, 384, 384);
  for (let t = 0; t < 384; t += 3) {
    ctx.fillStyle = t % 2 ? '#ffe9cd47' : '#8c524a21';
    ctx.fillRect(t, 0, 1, 384);
    ctx.fillRect(0, t + 1, 384, 1);
  }
  ctx.strokeStyle = '#f6d7b4bb';
  ctx.lineWidth = 1.8;
  ctx.setLineDash([5, 4]);
  for (let t = -384; t <= 768; t += 54) {
    ctx.beginPath();
    ctx.moveTo(t, 0);
    ctx.lineTo(t + 384, 384);
    ctx.moveTo(t, 0);
    ctx.lineTo(t - 384, 384);
    ctx.stroke();
  }
  ctx.setLineDash([]);
  ctx.strokeStyle = '#ba796a';
  ctx.lineWidth = 19;
  ctx.strokeRect(0, 0, 384, 384);
  ctx.strokeStyle = '#f4d4ba';
  ctx.lineWidth = 2;
  ctx.strokeRect(11, 11, 362, 362);
  const map = new THREE.CanvasTexture(canvas);
  map.colorSpace = THREE.SRGBColorSpace;
  map.anisotropy = 4;
  return map;
}

function makeBlanket() {
  const cols = 38, rows = 34;
  const vertices = new Float32Array((cols + 1) * (rows + 1) * 3);
  const uvs = new Float32Array((cols + 1) * (rows + 1) * 2);
  const triangles = [];
  for (let i = 0; i <= rows; i++) {
    for (let j = 0; j <= cols; j++) {
      const vertex = i * (cols + 1) + j;
      uvs.set([j / cols, i / rows], vertex * 2);
      if (i > 0 && j > 0) {
        const left = vertex - 1, back = vertex - cols - 1;
        triangles.push(vertex, back, left, left, back, back - 1);
      }
    }
  }
  const geometry = new THREE.BufferGeometry();
  const positions = new THREE.BufferAttribute(vertices, 3);
  positions.setUsage(THREE.DynamicDrawUsage);
  geometry.setAttribute('position', positions);
  geometry.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
  geometry.setIndex(triangles);
  const mesh = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({
    map: textile(), side: THREE.DoubleSide, roughness: 0.93,
  }));
  mesh.frustumCulled = false;
  mesh.visible = false;
  let last = -1;
  let lastBreath = 0;

  function update(amount, breath) {
    mesh.visible = amount > 0.015;
    if (!mesh.visible || (last === amount && lastBreath === breath)) return;
    last = amount;
    lastBreath = breath;
    for (let i = 0; i <= rows; i++) {
      const v = i / rows;
      for (let j = 0; j <= cols; j++) {
        const u = (j / cols) * 2 - 1;
        const side = Math.abs(u);
        // The two curved hems leave room for the tail and the lowered neck.
        const rear = -0.327 - 0.177 * smooth(side, 0.30, 0.77);
        const front = 0.043 + 0.141 * smooth(side, 0.43, 0.85);
        const z = THREE.MathUtils.lerp(rear, front + 0.012 * Math.sin(u * 11), v * amount);
        const width = 0.320 - 0.020 * (1 - smooth(z, -0.51, -0.27));
        const support = 0.576 + 0.015 * Math.exp(-Math.pow((z - 0.03) * 6.5, 2));
        const drop = 1 - smooth(side, 0.24, 0.82);
        const crease = (Math.sin(u * 17 + z * 7) + Math.sin(u * 28 - z * 13) * 0.4) * 0.008;
        const hem = 0.017 * Math.exp(-Math.pow((v - 0.973) * 41, 2));
        const ridge = mattress + 0.020 + (support - mattress) * drop;
        positions.setXYZ(i * (cols + 1) + j, width * u,
          ridge + crease * (0.44 + side) + hem + breath * drop, z);
      }
    }
    positions.needsUpdate = true;
    geometry.computeVertexNormals();
  }
  return { mesh, update };
}

export function makeSleep() {
  const group = new THREE.Group();
  group.visible = false;
  const weave = fabricWeave();
  group.add(contactShadow());
  group.add(upholstery([
    [0, 0.015], [0.50, 0.015], [0.66, 0.022], [0.73, 0.052],
    [0.765, 0.110], [0.765, 0.145], [0.733, 0.174], [0.690, 0.184],
    [0.642, 0.177], [0.604, 0.155], [0.57, 0.133], [0.53, 0.096], [0, 0.082],
  ], '#956761', weave));
  group.add(upholstery([
    [0, 0.089], [0.54, 0.084], [0.63, 0.11], [0.62, 0.129],
    [0.49, mattress + 0.013], [0, mattress],
  ], '#e3c3a8', weave));
  group.add(piping(0.694, 0.183, 0.0065, '#deb29d'));
  group.add(piping(0.737, 0.064, 0.005, '#80554c'));

  const throwCloth = makeBlanket();
  group.add(throwCloth.mesh);

  const point = new THREE.Vector3();
  function screenBounds(camera) {
    const bounds = new THREE.Box2();
    for (let i = 0; i < 36; i++) {
      const a = i / 36 * 2 * Math.PI;
      for (const y of [0.02, 0.27]) {
        point.set(Math.cos(a) * radius * oval, y, Math.sin(a) * radius);
        group.localToWorld(point).project(camera);
        bounds.expandByPoint(new THREE.Vector2((point.x + 1) / 2, (1 - point.y) / 2));
      }
    }
    return [bounds.min.x - 0.015, bounds.min.y - 0.044, bounds.max.x + 0.015, bounds.max.y + 0.015];
  }

  return { group, screenBounds, blanket: throwCloth.update };
}

// The rig uses bone-local axes. Convert the lateral axis of the dog into that space.
export function makeSleepPose(body, bones) {
  const originals = new Map();
  const bodyRotation = new THREE.Quaternion();
  const boneRotation = new THREE.Quaternion();
  const axis = new THREE.Vector3();

  function turn(bone, angle) {
    if (!bone) return;
    originals.set(bone, bone.quaternion.clone());
    body.getWorldQuaternion(bodyRotation);
    bone.getWorldQuaternion(boneRotation).invert();
    axis.set(1, 0, 0).applyQuaternion(bodyRotation).applyQuaternion(boneRotation);
    bone.rotateOnAxis(axis, angle);
  }

  function reset() {
    for (const [bone, rotation] of originals) bone.quaternion.copy(rotation);
    originals.clear();
  }

  function update(arrival, breath, reduced, fromBeside = true) {
    const approach = smooth(arrival, 0, 0.68);
    const curl = smooth(arrival, 0.43, 1);
    const gait = Math.sin(approach * Math.PI * 6) * Math.sin(approach * Math.PI);
    body.scale.setScalar(fromBeside ? 0.79 + approach * 0.21 : 1);
    body.rotation.y = fromBeside ? -0.30 * (1 - approach) : 0;
    body.position.set(fromBeside ? -0.34 * (1 - approach) : 0,
      0.205 * (fromBeside ? approach : curl) + (fromBeside && !reduced ? Math.abs(gait) * 0.032 : 0),
      fromBeside ? -0.54 * (1 - approach) : 0);
    if (fromBeside && !reduced && approach < 1) {
      for (const side of ['der', 'izq']) {
        const motion = 0.18 * gait * (side === 'der' ? 1 : -1);
        turn(bones.get(`muslo.del.${side}`), motion);
        turn(bones.get(`muslo.tras.${side}`), -motion);
      }
    }
    turn(bones.get('cuello'), curl * 0.71 + breath * 1.1);
    turn(bones.get('cabeza'), curl * -0.19);
    turn(bones.get('cola'), -0.60 * curl);
  }

  return { reset, update };
}
