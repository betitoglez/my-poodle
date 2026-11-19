import * as THREE from 'three';

export const walkWidth = 2.6;
const stops = [0.82, 1.67, 2.52].map(value => value * walkWidth);
const range = 11;

function seeded() {
  let state = 0x7f251eab;
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

function texture(paint, repeats) {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 512;
  paint(canvas.getContext('2d'), seeded());
  const map = new THREE.CanvasTexture(canvas);
  map.colorSpace = THREE.SRGBColorSpace;
  map.wrapS = map.wrapT = THREE.RepeatWrapping;
  map.repeat.set(...repeats);
  map.anisotropy = 4;
  return map;
}

function grassTexture() {
  return texture((ctx, random) => {
    ctx.fillStyle = '#577448';
    ctx.fillRect(0, 0, 512, 512);
    const tints = ['#e9d58f2c', '#b3c46f2d', '#28452d40', '#60845060'];
    for (let i = 0; i < 650; i++) {
      const x = random() * 512, y = random() * 512, w = 5 + random() * 37;
      ctx.fillStyle = tints[i % tints.length];
      ctx.beginPath();
      ctx.ellipse(x, y, w, w * 0.48, i, 0, 2 * Math.PI);
      ctx.fill();
    }
    for (let i = 0; i < 10000; i++) {
      ctx.fillStyle = tints[i % tints.length];
      ctx.fillRect(random() * 512, random() * 512, 1 + random() * 3, 1 + random() * 6);
    }
  }, [9, 3]);
}

function gravelTexture() {
  return texture((ctx, random) => {
    ctx.fillStyle = '#a99073';
    ctx.fillRect(0, 0, 512, 512);
    const colors = ['#c7b493', '#d2bfa0', '#c9b39a', '#d6bf9d', '#bba98f'];
    for (let y = -60; y < 560; y += 52) {
      let x = y % 104 === 0 ? -28 : -70;
      while (x < 540) {
        const w = 46 + random() * 26;
        const h = 42 + random() * 6;
        ctx.fillStyle = colors[Math.floor(random() * colors.length)];
        ctx.beginPath();
        ctx.moveTo(x + 7, y + 2);
        ctx.lineTo(x + w - 6, y + 1);
        ctx.lineTo(x + w - 2, y + 8);
        ctx.lineTo(x + w - 3, y + h - 4);
        ctx.lineTo(x + w - 9, y + h + 1);
        ctx.lineTo(x + 4, y + h - 1);
        ctx.lineTo(x, y + h - 7);
        ctx.lineTo(x + 1, y + 8);
        ctx.closePath();
        ctx.fill();
        ctx.strokeStyle = '#efe0bd73';
        ctx.lineWidth = 1.5;
        ctx.stroke();
        x += w + 2;
      }
    }
    for (let i = 0; i < 14000; i++) {
      ctx.fillStyle = i % 2 ? '#4e3c3336' : '#fff4d242';
      const s = 0.6 + random() * 1.6;
      ctx.fillRect(random() * 512, random() * 512, s * 1.5, s);
    }
  }, [11, 1.35]);
}

function material(color, roughness = 0.89) {
  return new THREE.MeshStandardMaterial({ color, roughness });
}

function block(group, mat, dims, position, angle = 0) {
  const object = new THREE.Mesh(new THREE.BoxGeometry(...dims), mat);
  object.position.set(...position);
  object.rotation.x = angle;
  group.add(object);
  return object;
}

function ground(width, depth, centerZ, height, map) {
  const object = new THREE.Mesh(new THREE.PlaneGeometry(width, depth),
    new THREE.MeshStandardMaterial({ map, roughness: 0.93 }));
  object.rotation.x = -Math.PI / 2;
  object.position.set(4.2, height, centerZ);
  return object;
}

function shadowTexture() {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 64;
  const ctx = canvas.getContext('2d');
  const shade = ctx.createRadialGradient(32, 32, 8, 32, 32, 31.5);
  shade.addColorStop(0, 'rgba(53, 42, 28, 0.57)');
  shade.addColorStop(0.5, 'rgba(58, 51, 38, 0.32)');
  shade.addColorStop(1, 'rgba(48, 39, 33, 0)');
  ctx.fillStyle = shade;
  ctx.fillRect(0, 0, 64, 64);
  return new THREE.CanvasTexture(canvas);
}

function shadow(map, x, z, width, depth, y = 0.015) {
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(width, depth),
    new THREE.MeshBasicMaterial({ map, transparent: true, depthWrite: false }));
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.set(x, y, z);
  return mesh;
}

export function makePetShadow() {
  return shadow(shadowTexture(), 0, -.035, .59, 1.13, .004);
}

function flowers(group, random) {
  const greenery = material('#608a52'), stem = material('#456b43');
  const center = material('#dca64e');
  const palettes = ['#c46f99', '#ecc2cf', '#a881bd', '#f1dbce', '#705497'].map(color => material(color));
  const petals = new THREE.SphereGeometry(1, 9, 6);
  const leaf = new THREE.SphereGeometry(1, 8, 5);
  const branch = new THREE.CylinderGeometry(0.009, 0.012, 1, 6);
  const blooms = new THREE.Group();
  for (let i = 0; i < 23; i++) {
    const px = (random() - 0.5) * 0.75, pz = (random() - 0.5) * 0.42;
    const py = 0.17 + random() * 0.28;
    const stick = new THREE.Mesh(branch, stem);
    stick.position.set(px, py * 0.5, pz);
    stick.rotation.z = (random() - 0.5) * 0.41;
    stick.scale.y = py;
    blooms.add(stick);
    for (const edge of [-1, 1]) {
      const foliage = new THREE.Mesh(leaf, greenery);
      foliage.position.set(px + edge * 0.045, py * (edge < 0 ? 0.38 : 0.62), pz);
      foliage.scale.set(0.070, 0.015, 0.030);
      foliage.rotation.z = 0.42 * edge;
      blooms.add(foliage);
    }
    const head = new THREE.Group();
    head.position.set(px + Math.sin(-stick.rotation.z) * py * 0.45, py, pz);
    head.rotation.x = 0.50 + random() * 0.45;
    const color = palettes[i % palettes.length];
    for (let k = 0; k < 5; k++) {
      const a = k * 2 * Math.PI / 5;
      const blade = new THREE.Mesh(petals, color);
      blade.position.set(Math.cos(a) * 0.036, 0, Math.sin(a) * 0.036);
      blade.scale.set(0.037, 0.012, 0.025);
      blade.rotation.y = -a;
      head.add(blade);
    }
    const button = new THREE.Mesh(leaf, center);
    button.scale.set(0.023, 0.017, 0.022);
    head.add(button);
    blooms.add(head);
  }
  blooms.position.set(stops[0] + 0.10, 0.022, -0.68);
  blooms.updateMatrixWorld(true);
  const batches = new Map();
  blooms.traverse(object => {
    if (!object.isMesh) return;
    const key = `${object.geometry.id}:${object.material.id}`;
    if (!batches.has(key)) batches.set(key, []);
    batches.get(key).push(object);
  });
  for (const batch of batches.values()) {
    const [first] = batch;
    const instance = new THREE.InstancedMesh(first.geometry, first.material, batch.length);
    batch.forEach((object, index) => instance.setMatrixAt(index, object.matrixWorld));
    group.add(instance);
  }
}

function bench(group) {
  const prop = new THREE.Group();
  const wood = ['#845e45', '#ac7950', '#967053'].map(color => material(color));
  const iron = material('#40534d');
  for (let row = 0; row < 4; row++) {
    block(prop, wood[row % 3], [1.10, 0.040, 0.083], [0, 0.35, row * 0.083 - 0.125]);
  }
  for (let row = 0; row < 3; row++) {
    block(prop, wood[(row + 1) % 3], [1.12, 0.087, 0.035], [0, 0.48 + row * 0.093, -0.16 - row * 0.018], 0.12);
  }
  for (const side of [-1, 1]) {
    const x = side * 0.455;
    block(prop, iron, [0.055, 0.34, 0.054], [x, 0.17, 0.109], 0.10);
    block(prop, iron, [0.055, 0.65, 0.056], [x, 0.33, -0.16], -0.08);
    block(prop, iron, [0.043, 0.033, 0.35], [x, 0.50, -0.024], 0.09);
    block(prop, iron, [0.042, 0.19, 0.042], [x, 0.415, 0.12], 0.17);
  }
  prop.position.set(stops[1] + 0.11, 0.02, -0.87);
  prop.rotation.y = -0.12;
  group.add(prop);
}

function fountain(group) {
  const stone = material('#b3a99a', 0.78);
  const trim = material('#d2c7ad', 0.69);
  const prop = new THREE.Group();
  const lathe = (profile, mat) => new THREE.Mesh(
    new THREE.LatheGeometry(profile.map(([r,y]) => new THREE.Vector2(r,y)), 42), mat,
  );
  prop.add(lathe([
    [0, 0], [0.37, 0], [0.44, 0.035], [0.44, 0.10], [0.50, 0.13],
    [0.52, 0.20], [0.51, 0.26], [0.47, 0.29], [0.43, 0.265],
    [0.42, 0.22], [0.38, 0.15], [0, 0.145],
  ], stone));
  prop.add(lathe([[0.47, 0.275], [0.49, 0.302], [0.46, 0.312], [0.435, 0.282]], trim));
  prop.add(lathe([[0.16, 0.17], [0.17, 0.235], [0.086, 0.45], [0.13, 0.51],
    [0.14, 0.550], [0.102, 0.572], [0.062, 0.558], [0, 0.535]], stone));
  const water = new THREE.Mesh(new THREE.CircleGeometry(0.435, 42),
    new THREE.MeshStandardMaterial({ color: '#8ac2c6', roughness: 0.23, metalness: 0.10 }));
  water.rotation.x = -Math.PI / 2;
  water.position.y = 0.238;
  prop.add(water);
  const drops = new THREE.InstancedMesh(new THREE.SphereGeometry(1, 7, 5),
    material('#bedce0', 0.19), 38);
  drops.frustumCulled = false;
  prop.add(drops);
  prop.position.set(stops[2] + 0.10, 0.012, -0.73);
  group.add(prop);
  const drop = new THREE.Object3D();
  return seconds => {
    for (let i = 0; i < drops.count; i++) {
      const age = (seconds * 1.18 + i * 0.137) % 1;
      const a = i * 2.399963;
      const r = age * (0.25 + i % 7 * 0.014);
      drop.position.set(Math.cos(a) * r, 0.55 + 0.23 * Math.sin(age * 3.3) - 0.33 * age * age,
        Math.sin(a) * r);
      drop.scale.set(0.010, 0.018, 0.010);
      drop.updateMatrix();
      drops.setMatrixAt(i, drop.matrix);
    }
    drops.instanceMatrix.needsUpdate = true;
  };
}

function verge(group, random) {
  const blades = new THREE.InstancedMesh(new THREE.ConeGeometry(1, 1, 3),
    material('#ffffff'), 550);
  const leaf = new THREE.Object3D();
  const colors = ['#637c46', '#88a35a', '#9dac68', '#526f47', '#718644'].map(hex => new THREE.Color(hex));
  for (let i = 0; i < blades.count; i++) {
    const x = (random() - 0.12) * range, edge = i % 2 === 0 ? 1 : -1;
    const z = edge * (0.56 + random() * 0.60);
    const height = 0.043 + 0.10 * random();
    leaf.position.set(x, height * 0.45, z);
    leaf.rotation.set((random() - 0.5) * 0.52, random() * 3.14, (random() - 0.5) * 0.46);
    leaf.scale.set(0.012 + random() * 0.016, height, 0.013);
    leaf.updateMatrix();
    blades.setMatrixAt(i, leaf.matrix);
    blades.setColorAt(i, colors[i % colors.length]);
  }
  group.add(blades);
}

export function makeWalk() {
  const group = new THREE.Group();
  group.visible = false;
  const random = seeded();
  const grass = ground(range, 3.5, -0.12, 0, grassTexture());
  grass.material.onBeforeCompile = shader => {
    shader.vertexShader = 'varying float vergeDepth;\n' + shader.vertexShader.replace('#include <begin_vertex>',
      '#include <begin_vertex>\nvergeDepth = position.y;');
    shader.fragmentShader = 'varying float vergeDepth;\n' + shader.fragmentShader.replace('#include <alphatest_fragment>',
      '#include <alphatest_fragment>\ndiffuseColor.a *= 1.0 - smoothstep(0.96, 1.72, vergeDepth);');
  };
  grass.material.transparent = true;
  grass.material.depthWrite = false;
  grass.renderOrder = -5;
  group.add(grass, ground(range, 1.14, 0, 0.008, gravelTexture()));
  const shade = shadowTexture();
  const dogShadow = shadow(shade, 0, 0, 1.19, 0.64);
  group.add(dogShadow,
    shadow(shade, stops[0] + 0.10, -0.67, 0.93, 0.66),
    shadow(shade, stops[1] + 0.10, -0.85, 1.38, 0.74),
    shadow(shade, stops[2] + 0.10, -0.71, 1.23, 1.20));
  flowers(group, random);
  bench(group);
  const animateFountain = fountain(group);
  verge(group, random);
  function update(pet, camera, time) {
    group.position.x = -camera;
    dogShadow.position.x = pet;
    if (pet > stops[1] - 0.5) animateFountain(time);
  }
  return { group, update };
}

export function makeWalkPose(body, bones) {
  const originals = new Map();
  const legs = [];
  const axis = new THREE.Vector3(1, 0, 0);
  const bodyRotation = new THREE.Quaternion();
  const localRotation = new THREE.Quaternion();
  const smooth = THREE.MathUtils.smoothstep;
  let cadenceOrigin = null;
  const trunk = bones.get('tronco');
  const pivot = body.worldToLocal(trunk.getWorldPosition(new THREE.Vector3()));
  const raisedHip = new THREE.Vector3();

  const across = bone => axis.clone().applyQuaternion(body.getWorldQuaternion(bodyRotation))
    .applyQuaternion(bone.getWorldQuaternion(localRotation).invert());
  const angle = (dy, dz) => Math.atan2(dz, dy);
  function turn(bone, localAxis, value) {
    originals.set(bone, bone.quaternion.clone());
    bone.rotateOnAxis(localAxis, value);
  }
  function prepareLeg(place, side, offset) {
    const hip = bones.get(`muslo.${place}.${side}`);
    const knee = bones.get(`pierna.${place}.${side}`);
    const paw = bones.get(`pata.${place}.${side}`);
    if (!(hip && knee && paw)) return;
    const [a, b, c] = [hip, knee, paw].map(bone => body.worldToLocal(bone.getWorldPosition(new THREE.Vector3())));
    const direction = Math.sign((b.z - a.z) * (c.y - a.y) - (b.y - a.y) * (c.z - a.z));
    legs.push({ hip, knee, paw, a, c, direction, offset, front: place === 'del',
      axes: [hip, knee, paw].map(across),
      top: Math.hypot(b.y-a.y, b.z-a.z), bottom: Math.hypot(c.y-b.y, c.z-b.z),
      first: angle(b.y-a.y, b.z-a.z), second: angle(c.y-b.y, c.z-b.z) });
  }
  prepareLeg('tras', 'der', 0);
  prepareLeg('del', 'der', 0.27);
  prepareLeg('tras', 'izq', 0.5);
  prepareLeg('del', 'izq', 0.77);
  const [trunkAxis, neckAxis, headAxis] = [trunk, bones.get('cuello'), bones.get('cabeza')].map(across);
  function reset() {
    for (const [bone, saved] of originals) bone.quaternion.copy(saved);
    originals.clear();
  }
  function applyLeg(leg, stride, lift, bodyLift, root = leg.a, pitch = 0) {
    const dy = leg.c.y - root.y + lift - bodyLift;
    const dz = leg.c.z - root.z + stride;
    const hypotenuse = Math.hypot(dy, dz);
    const length = Math.min(hypotenuse, leg.top + leg.bottom - 0.001);
    const y = dy / hypotenuse, z = dz / hypotenuse;
    const along = (leg.top ** 2 - leg.bottom ** 2 + length ** 2) / (2 * length);
    const bend = leg.direction * Math.sqrt(Math.max(0, leg.top ** 2 - along ** 2));
    const kneeY = along * y - bend * z, kneeZ = along * z + bend * y;
    const hipTurn = angle(kneeY, kneeZ) - leg.first - pitch;
    const shinTurn = angle(y * length - kneeY, z * length - kneeZ) - leg.second;
    turn(leg.hip, leg.axes[0], hipTurn);
    turn(leg.knee, leg.axes[1], shinTurn - hipTurn - pitch);
    turn(leg.paw, leg.axes[2], -shinTurn + lift * 1.35);
  }
  function update(distance, moving, sniff, reduced, settle = 1) {
    if (!moving || reduced) {
      cadenceOrigin = null;
      body.position.y = 0;
      if (sniff >= 0 && !reduced) {
        const neck = bones.get('cuello');
        const dip = smooth(sniff, 0.04, 0.35) * (1 - smooth(sniff, 0.72, 0.99));
        turn(neck, across(neck), 0.13 * dip + Math.sin(sniff * Math.PI * 8) * 0.03 * dip);
      }
      return;
    }
    cadenceOrigin ??= distance;
    const traveled = Math.max(0, distance - cadenceOrigin);
    const mix = smooth(traveled, 0, 0.20) * settle;
    const cycleLength = 0.67;
    const cycle = distance / cycleLength;
    // Keep the supporting paws at ground height while the torso shifts weight.
    const bodyLift = -mix * 0.009 * (1 + Math.cos(cycle*4*Math.PI));
    body.position.y = bodyLift;
    for (const leg of legs) {
      const t = (cycle + leg.offset) % 1;
      const duty = 0.65;
      const swing = Math.max(0, (t - duty) / (1 - duty));
      const swingArc = smooth(swing, 0, 1);
      const path = t < duty ? 0.5 - t / duty : -0.5 + swingArc;
      applyLeg(leg, path * cycleLength * duty * mix, Math.sin(Math.PI * swing) * 0.133 * mix, bodyLift);
    }
  }

  function rear(amount, sway) {
    cadenceOrigin = null;
    const pitch = (-1.13 + sway * .018) * amount;
    const lift = -.052 * amount;
    body.position.y = lift;
    turn(trunk, trunkAxis, pitch);
    turn(bones.get('cuello'), neckAxis, .54 * amount);
    turn(bones.get('cabeza'), headAxis, .42 * amount);
    for (const leg of legs) {
      if (leg.front) {
        turn(leg.hip, leg.axes[0], .43 * amount);
        turn(leg.knee, leg.axes[1], .93 * amount);
        turn(leg.paw, leg.axes[2], -.54 * amount);
      } else {
        // Counter the torso rotation by solving back to the planted hind paws.
        raisedHip.copy(leg.a).sub(pivot).applyAxisAngle(axis, pitch).add(pivot);
        applyLeg(leg, 0, 0, lift, raisedHip, pitch);
      }
    }
  }
  return { reset, update, rear };
}
