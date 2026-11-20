import * as THREE from 'three';

export const vetTableHeight = 0.282;
const anchors = [
  new THREE.Vector3(-0.119, 0.54 + vetTableHeight, 0.269), // Chest
  new THREE.Vector3(-0.102, 0.105 + vetTableHeight, 0.238), // Near front paw
  new THREE.Vector3(-0.046, 0.775 + vetTableHeight, 0.528), // Muzzle
];

function surface(color, roughness, metalness = 0) {
  return new THREE.MeshStandardMaterial({ color, roughness, metalness });
}

function pad(width, length, y, depth, bevel, material) {
  const x = width / 2, z = length / 2, corner = 0.10;
  const shape = new THREE.Shape();
  shape.moveTo(-x + corner, -z);
  shape.lineTo(x - corner, -z);
  shape.quadraticCurveTo(x, -z, x, -z + corner);
  shape.lineTo(x, z - corner);
  shape.quadraticCurveTo(x, z, x - corner, z);
  shape.lineTo(-x + corner, z);
  shape.quadraticCurveTo(-x, z, -x, z - corner);
  shape.lineTo(-x, -z + corner);
  shape.quadraticCurveTo(-x, -z, -x + corner, -z);
  const geometry = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: true, bevelSize: bevel, bevelThickness: bevel,
    bevelSegments: 3, curveSegments: 6, steps: 1,
  });
  geometry.rotateX(-Math.PI / 2);
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(0, y, -0.05);
  return mesh;
}

function toolTube(points, radius, material) {
  const path = new THREE.CatmullRomCurve3(points.map(point => new THREE.Vector3(...point)));
  return new THREE.Mesh(new THREE.TubeGeometry(path, 28, radius, 8), material);
}

export function makeVet() {
  const table = new THREE.Group();
  table.visible = false;
  const steel = surface('#96a7a1', 0.38, 0.48);
  const rim = surface('#52766b', 0.49);
  const cushion = surface('#8ba696', 0.76);
  const column = new THREE.Mesh(new THREE.CylinderGeometry(0.059, 0.086, 0.19, 24), steel);
  column.position.set(0, 0.11, -0.05);
  table.add(column,
    pad(0.46, 0.69, 0.027, 0.024, 0.018, steel),
    pad(0.59, 1.22, 0.192, 0.034, 0.018, rim),
    pad(0.56, 1.19, 0.239, 0.027, 0.016, cushion),
  );
  const contactMap = document.createElement('canvas');
  contactMap.width = contactMap.height = 32;
  const ctx = contactMap.getContext('2d');
  const gradient = ctx.createRadialGradient(16, 16, 0, 16, 16, 16);
  gradient.addColorStop(0, 'rgba(28, 47, 42, 0.5)');
  gradient.addColorStop(1, 'rgba(28, 47, 42, 0)');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 32, 32);
  const contact = new THREE.MeshBasicMaterial({
    map: new THREE.CanvasTexture(contactMap), transparent: true, depthWrite: false,
  });
  const pawShadow = new THREE.PlaneGeometry(0.22, 0.23);
  for (const z of [0.21, -0.34]) {
    for (const x of [-0.114, 0.122]) {
      const shadow = new THREE.Mesh(pawShadow, contact);
      shadow.rotation.x = -Math.PI / 2;
      shadow.position.set(x, vetTableHeight + 0.001, z);
      table.add(shadow);
    }
  }

  const tools = new THREE.Group();
  tools.visible = false;
  const gray = surface('#d1dbe0', 0.28, 0.59);
  const rubber = surface('#5b3552', 0.68);
  const gold = surface('#b8874c', 0.33, 0.43);
  const wood = surface('#76503a', 0.68);
  const fonendo = new THREE.Group();
  const diaphragm = new THREE.Mesh(new THREE.CylinderGeometry(0.049, 0.053, 0.022, 24), gray);
  diaphragm.rotation.x = Math.PI / 2;
  fonendo.add(diaphragm, toolTube([
    [0.028, 0.02, -0.01], [0.12, 0.045, 0.002], [0.16, 0.125, 0.002],
    [0.124, 0.19, 0], [0.07, 0.203, 0],
  ], 0.012, rubber));
  for (const side of [-1, 1]) {
    const endX = 0.07 + 0.04 * side;
    fonendo.add(toolTube([
      [0.07, 0.2, 0], [endX, 0.235, 0], [endX, 0.27, 0.02],
    ], 0.007, gray));
    const tip = new THREE.Mesh(new THREE.SphereGeometry(0.013, 10, 8), rubber);
    tip.position.set(endX, 0.267, 0.02);
    fonendo.add(tip);
  }

  const magnifier = new THREE.Group();
  const glassRing = new THREE.Mesh(new THREE.TorusGeometry(0.088, 0.013, 10, 32), gold);
  const lens = new THREE.Mesh(new THREE.SphereGeometry(0.083, 20, 12),
    new THREE.MeshStandardMaterial({ color: '#d7eef2', transparent: true, opacity: 0.18,
      roughness: 0.14, depthWrite: false }));
  lens.scale.z = 0.2;
  const grip = new THREE.Mesh(new THREE.CapsuleGeometry(0.017, 0.112, 6, 12), wood);
  grip.position.set(0.112, -0.112, 0);
  grip.rotation.z = Math.PI / 4;
  magnifier.add(glassRing, lens, grip);

  const pill = new THREE.Group();
  const radius = 0.024, halfLength = 0.023;
  const capsuleHalf = new THREE.LatheGeometry([
    new THREE.Vector2(radius, 0), new THREE.Vector2(radius, halfLength),
    ...Array.from({ length: 9 }, (_, index) => {
      const angle = (index + 1) * Math.PI / 18;
      return new THREE.Vector2(radius * Math.cos(angle), halfLength + radius * Math.sin(angle));
    }),
  ], 20);
  const coral = new THREE.Mesh(capsuleHalf, surface('#c65366', 0.31));
  const cream = new THREE.Mesh(capsuleHalf, surface('#f8ecdb', 0.33));
  cream.rotation.z = Math.PI;
  pill.add(coral, cream);
  tools.add(fonendo, magnifier, pill);

  const anchor = new THREE.Vector3();
  const screen = new THREE.Vector3();
  const cameraOffset = new THREE.Vector3();
  const cameraRight = new THREE.Vector3();
  const cameraUp = new THREE.Vector3();

  function screenTargets(camera) {
    return anchors.flatMap(point => {
      table.localToWorld(screen.copy(point)).project(camera);
      return [(screen.x + 1) / 2, (1 - screen.y) / 2];
    });
  }

  function update(camera, state, reduced) {
    const [phase, selected, x, y, contact, effect, exam] = state;
    tools.visible = phase < anchors.length && Boolean(selected || effect >= 0);
    if (!tools.visible) return;
    [fonendo, magnifier, pill].forEach((tool, index) => { tool.visible = index === phase; });
    table.localToWorld(anchor.copy(anchors[phase]));
    cameraOffset.set(0, 0, 0.16).applyQuaternion(camera.quaternion);
    tools.quaternion.copy(camera.quaternion);
    tools.scale.setScalar(1);
    if (effect >= 0 || contact) {
      tools.position.copy(anchor).add(cameraOffset);
      if (phase === 0 && !reduced) tools.scale.setScalar(1 + 0.08 * Math.sin((effect >= 0 ? effect : exam) * 8 * Math.PI));
      if (phase === 1 && effect >= 0 && !reduced) {
        tools.position.add(cameraRight.set(0.06 * Math.sin(effect * 2 * Math.PI), 0, 0).applyQuaternion(camera.quaternion));
      }
      if (phase === 2 && effect >= 0) {
        const ease = THREE.MathUtils.smoothstep(effect, 0, 0.54);
        const distance = 1 - ease;
        tools.position.copy(anchor).addScaledVector(cameraOffset, distance);
        tools.position.add(cameraRight.set(0.13 * distance, 0, 0).applyQuaternion(camera.quaternion));
        tools.position.add(cameraUp.set(0, 0.055 * distance, 0).applyQuaternion(camera.quaternion));
        tools.scale.setScalar(distance);
        tools.visible = effect < 0.54;
      }
    } else {
      const depth = screen.copy(anchor).project(camera).z;
      tools.position.set(2 * x - 1, 1 - 2 * y, depth).unproject(camera).add(cameraOffset);
    }
    pill.rotation.z = effect >= 0 && !reduced ? -1.0 + effect * Math.PI : -1.0;
  }

  return { table, tools, screenTargets, update };
}
