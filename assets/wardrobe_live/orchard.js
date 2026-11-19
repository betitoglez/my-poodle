import * as THREE from 'three';

function seeded(seed) {
  return () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed / 4294967296;
  };
}

function texture(width, height, paint) {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  paint(canvas.getContext('2d'));
  const map = new THREE.CanvasTexture(canvas);
  map.colorSpace = THREE.SRGBColorSpace;
  map.wrapS = map.wrapT = THREE.RepeatWrapping;
  map.anisotropy = 4;
  return map;
}

function material(color, roughness = 0.86) {
  return new THREE.MeshStandardMaterial({ color, roughness });
}

function soilTexture(brick) {
  return texture(512, 512, ctx => {
    const random = seeded(brick ? 41 : 13);
    const strata = ctx.createLinearGradient(0, 0, 0, 512);
    for (const [offset, color] of [[0,'#705339'],[0.14,'#926445'],[0.28,'#825539'],
      [0.44,'#a27451'],[0.62,'#895b42'],[0.75,'#704b36'],[1,'#4b382e']]) {
      strata.addColorStop(offset, color);
    }
    ctx.fillStyle = strata;
    ctx.fillRect(0, 0, 512, 512);
    if (brick) {
      for (let row = -1; row < 9; row++) {
        for (let col = -1; col < 6; col++) {
          const x = col * 108 + (row % 2) * 54;
          const y = row * 51;
          ctx.fillStyle = ['#ae8666','#9b7458','#8d684f','#a77d61'][Math.floor(random() * 4)];
          ctx.beginPath();
          ctx.roundRect(x + 3, y + 3, 101, 45, 6);
          ctx.fill();
          ctx.strokeStyle = '#e2bb864d';
          ctx.stroke();
        }
      }
    } else {
      for (let band = 0; band < 8; band++) {
        ctx.beginPath();
        for (let x = 0; x <= 512; x += 4) {
          const y = 20 + 47 * band + 7 * Math.sin(x * 0.023 + band) + 4 * Math.sin(x * 0.067);
          if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.strokeStyle = band % 2 ? '#d5a87b5c' : '#59402977';
        ctx.lineWidth = 3 + random() * 8;
        ctx.stroke();
      }
    }
    for (let i = 0; i < 4500; i++) {
      const x = random() * 512, y = random() * 512;
      ctx.fillStyle = i % 3 ? '#2c211a43' : '#e5c09175';
      ctx.beginPath();
      ctx.ellipse(x, y, 1 + random() * 4, 0.6 + random() * 2, i, 0, Math.PI * 2);
      ctx.fill();
    }
  });
}

function turfTexture() {
  return texture(384, 192, ctx => {
    const random = seeded(81);
    ctx.fillStyle = '#6b8f43';
    ctx.fillRect(0, 0, 384, 192);
    for (let i = 0; i < 2700; i++) {
      const x = random() * 384, y = random() * 192;
      ctx.strokeStyle = ['#9fba6bb5','#486736ad','#789744da','#c6c18377'][i % 4];
      ctx.lineWidth = 1 + random() * 2.9;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + random() * 7 - 3, y + 1 + random() * 6);
      ctx.stroke();
    }
  });
}

function tiled(map, across, down = 1) {
  const repeat = map.clone();
  repeat.repeat.set(across, down);
  return new THREE.MeshStandardMaterial({ map: repeat, roughness: 0.94 });
}

function slab(x0, x1, top, earthy, brick, turf, blade, leaf) {
  const group = new THREE.Group();
  const width = x1 - x0;
  const side = tiled(top > 0 ? brick : earthy, width * 0.63);
  const end = tiled(top > 0 ? brick : earthy, 0.85);
  const crown = tiled(turf, width * 1.45, 1.25);
  const depth = 3.4;
  const terrace = new THREE.Mesh(new THREE.BoxGeometry(width, depth, 1.42),
    [end, end, crown, side, side, side]);
  terrace.position.set(x0 + width / 2, top - depth / 2 - 0.052, 0);
  const grass = new THREE.Mesh(new THREE.BoxGeometry(width, 0.055, 1.43), crown);
  grass.position.set(x0 + width / 2, top - 0.026, 0);
  group.add(terrace, grass);
  const sprigs = new THREE.InstancedMesh(blade, leaf, Math.ceil(width * 29));
  const hues = ['#8cae54', '#59783c', '#a7b96f', '#6d9c47'].map(c => new THREE.Color(c));
  const random = seeded(Math.round(x1 * 123)), strand = new THREE.Object3D();
  for (let i = 0; i < sprigs.count; i++) {
    const length = 0.045 + random() * 0.09;
    strand.position.set(x0 + 0.02 + random() * (width - 0.04), top + length * 0.38,
      (i % 2 ? 1 : -1) * (0.43 + random() * 0.26));
    strand.rotation.set((random()-0.5)*0.42, random()*Math.PI, (random()-0.5)*0.52);
    strand.scale.set(0.016 + random() * 0.018, length, 0.018);
    strand.updateMatrix();
    sprigs.setMatrixAt(i, strand.matrix);
    sprigs.setColorAt(i, hues[i % hues.length]);
  }
  group.add(sprigs);
  return { x0, x1, top, group };
}

const berrySurface = ['#bb3839', '#b8be4b', '#e38527', '#d73e58', '#5d64a6', '#efc44a'].map(c => material(c, 0.52));
const sphere = new THREE.SphereGeometry(1, 22, 14);
const leaf = material('#527744');
const stalk = material('#6e4a2e');

function ellipse(group, shape, size, position) {
  const mesh = new THREE.Mesh(sphere, shape);
  mesh.scale.set(...size);
  mesh.position.set(...position);
  group.add(mesh);
  return mesh;
}

function sculpt(group, surface, profile) {
  const mesh = new THREE.Mesh(new THREE.LatheGeometry(profile.map(([r,y]) => new THREE.Vector2(r,y)), 28), surface);
  group.add(mesh);
  return mesh;
}

function fruitModel(kind) {
  const group = new THREE.Group();
  const skin = berrySurface[kind];
  if (kind === 0) {
    sculpt(group, skin, [[0,-.166],[.10,-.185],[.157,-.16],[.203,-.08],[.222,.035],
      [.203,.134],[.15,.178],[.091,.177],[.035,.136],[0,.126]]);
  } else if (kind === 1) {
    sculpt(group, skin, [[0,-.191],[.085,-.200],[.153,-.172],[.185,-.107],[.180,-.045],
      [.137,.035],[.093,.091],[.072,.169],[.033,.205],[0,.209]]);
  } else if (kind === 2) {
    ellipse(group, skin, [.194,.19,.194], [0,0,0]);
  } else if (kind === 3) {
    sculpt(group, skin, [[0,-.212],[.048,-.195],[.116,-.121],[.159,-.061],[.192,.055],
      [.177,.116],[.128,.159],[.059,.161],[0,.153]]);
    const seed = material('#f8cd91');
    const pips = new THREE.InstancedMesh(new THREE.SphereGeometry(1, 6, 4), seed, 30);
    const point = new THREE.Object3D();
    for (let i = 0; i < pips.count; i++) {
      const row = Math.floor(i / 10), angle = (i % 10) / 10 * Math.PI * 2 + row * .43;
      const radius = [0.119, 0.168, 0.191][row];
      point.position.set(Math.cos(angle) * radius, -0.112 + row * .077, Math.sin(angle) * radius);
      point.scale.set(.009,.013,.009);
      point.updateMatrix();
      pips.setMatrixAt(i, point.matrix);
    }
    group.add(pips);
    for (let i = 0; i < 4; i++) {
      const a = i * Math.PI / 2;
      const sepal = ellipse(group, leaf, [.092,.015,.031], [Math.cos(a)*.044,.16,Math.sin(a)*.044]);
      sepal.rotation.y = -a;
    }
  } else if (kind === 4) {
    for (const [x,y,z,r] of [[-.097,-.049,.035,.116],[.094,-.038,.029,.117],[.008,.097,-.034,.121]]) {
      ellipse(group, skin, [r,r*.90,r], [x,y,z]);
      ellipse(group, material('#373e73'), [r*.33,.014,r*.33], [x,y+r*.86,z]);
    }
  } else {
    const points = [[-.213,.102,0],[-.170,-.039,0],[-.063,-.115,0],
      [.063,-.129,0],[.174,-.074,0],[.222,.016,0]].map(v => new THREE.Vector3(...v));
    const path = new THREE.CatmullRomCurve3(points);
    const tube = new THREE.TubeGeometry(path, 26,.078,12);
    const vertices = tube.attributes.position, p = new THREE.Vector3();
    for (let i = 0; i <= 26; i++) {
      const t = i / 26;
      const center = path.getPointAt(t);
      const taper = .36 + .64 * Math.pow(Math.sin(t*Math.PI),.45);
      for (let j = 0; j <= 12; j++) {
        const v = i * 13 + j;
        p.fromBufferAttribute(vertices, v).lerp(center, 1-taper);
        vertices.setXYZ(v, p.x,p.y,p.z);
      }
    }
    tube.computeVertexNormals();
    group.add(new THREE.Mesh(tube, skin));
    ellipse(group, stalk, [.030,.014,.026], [-.213,.102,0]);
    ellipse(group, stalk, [.019,.011,.024], [.222,.016,0]);
  }
  if (kind < 3) {
    const heights = [.185,.207,.182];
    const sprout = ellipse(group, stalk, [.013,.059,.012], [.026,heights[kind]+.021,0]);
    sprout.rotation.z = -.29;
    const greenery = ellipse(group, leaf, [.102,.015,.041], [.081,heights[kind]+.039,0]);
    greenery.rotation.z = -.30;
  }
  return group;
}

function finishGate(x) {
  const marker = new THREE.Group();
  const wood = material('#8a6747');
  const cloth = material('#b94755');
  for (const z of [-.62,.73]) {
    const post = new THREE.Mesh(new THREE.CylinderGeometry(.044,.067,1.7,12),wood);
    post.position.set(0,.85,z);
    marker.add(post);
  }
  const bar = new THREE.Mesh(new THREE.BoxGeometry(.11,.08,1.43),wood);
  bar.position.set(0,1.72,.05);
  marker.add(bar);
  const pennant = new THREE.Shape();
  pennant.moveTo(-.34,.20); pennant.lineTo(.34,.20);
  pennant.lineTo(.34,-.12); pennant.lineTo(0,-.20);
  pennant.lineTo(-.34,-.12); pennant.closePath();
  const panel = new THREE.Mesh(new THREE.ShapeGeometry(pennant),cloth);
  panel.position.set(.07,1.55,.68);
  marker.add(panel);
  const word = texture(256,128, ctx => {
    ctx.fillStyle = '#fff2d2'; ctx.font = 'bold 58px sans-serif';
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('META',128,56);
  });
  const caption = new THREE.Mesh(new THREE.PlaneGeometry(.61,.31),
    new THREE.MeshBasicMaterial({map:word,transparent:true,depthWrite:false}));
  caption.position.set(.07,1.55,.683);
  marker.add(caption);
  marker.position.x = x;
  return marker;
}

export function makeOrchard(level) {
  const group = new THREE.Group();
  const soil = soilTexture(false), brick = soilTexture(true), turf = turfTexture();
  const blade = new THREE.ConeGeometry(1,1,3), grass = material('#ffffff');
  const platforms = level.platforms.map(p => slab(...p, soil, brick, turf, blade, grass));
  for (const platform of platforms) group.add(platform.group);
  const fruit = level.fruit.map(([x,y,kind]) => {
    const mesh = fruitModel(kind);
    mesh.position.set(x,y,.12);
    group.add(mesh);
    return { x,y,mesh };
  });
  const gate = finishGate(level.goal);
  group.add(gate);
  const shade = texture(64,64, ctx => {
    const g = ctx.createRadialGradient(32,32,5,32,32,31.5);
    g.addColorStop(0,'#3e3b2bb3'); g.addColorStop(.58,'#3e3b2b52'); g.addColorStop(1,'#3e3b2b00');
    ctx.fillStyle = g; ctx.fillRect(0,0,64,64);
  });
  const shadow = new THREE.Mesh(new THREE.PlaneGeometry(1.04,.53),
    new THREE.MeshBasicMaterial({map:shade,transparent:true,depthWrite:false}));
  shadow.rotation.x = -Math.PI/2;
  group.add(shadow);
  const pit = texture(32,256, ctx => {
    const g = ctx.createLinearGradient(0,0,0,256);
    g.addColorStop(0,'#76594045'); g.addColorStop(.09,'#513a2cb0');
    g.addColorStop(.40,'#372921'); g.addColorStop(1,'#211c1b');
    ctx.fillStyle = g; ctx.fillRect(0,0,32,256);
  });
  const undergrowth = new THREE.Mesh(new THREE.PlaneGeometry(85,3.6),
    new THREE.MeshBasicMaterial({map:pit,transparent:true,depthWrite:false}));
  undergrowth.position.set(26,-1.92,-.76);
  undergrowth.renderOrder = -1;
  group.add(undergrowth);

  function update([x,y,,camera,,mask,time], width, reduced) {
    group.position.x = -camera;
    for (const platform of platforms) {
      platform.group.visible = platform.x1 >= camera - 1 && platform.x0 <= camera + width + 1;
    }
    for (const [i, entry] of fruit.entries()) {
      const { mesh } = entry;
      mesh.visible = (mask & (1 << i)) === 0 && entry.x >= camera - .4 && entry.x <= camera + width + .4;
      if (mesh.visible && !reduced) {
        mesh.position.y = entry.y + .022 * Math.sin(time * 4 + i);
        mesh.rotation.y = .58 + .51 * Math.sin(time * 1.35 + i);
      }
    }
    gate.visible = level.goal >= camera - 1 && level.goal <= camera + width + 1;
    const support = platforms.find(p => p.x0 <= x && p.x1 >= x);
    shadow.visible = Boolean(support && y > support.top-.04);
    if (shadow.visible) {
      shadow.position.set(x,support.top+.017,0);
      shadow.material.opacity = THREE.MathUtils.clamp(0.75 - (y-support.top)*.50,.16,.75);
    }
  }
  return { group, update };
}

// Gallop poses use the extension and collection from the project's Blender rig.
const gallop = [
  [0,.002,.015,-.02, [-.16,.12,.13,-.10], [.18,.15,-.11,-.13]],
  [.25,.096,.025,.04, [-.95,-.76,.87,.72], [.06,.19,-.06,-.22]],
  [.46,.05,-.07,.05, [-.27,-.06,.39,.15], [.34,.61,-.26,-.44]],
  [.67,.123,-.12,-.03, [.05,-.015,-.12,-.21], [1.02,.76,-.79,-.66]],
  [.83,.05,-.05,-.04, [.17,.06,-.33,-.14], [.71,.31,-.59,-.38]],
  [1,.002,.015,-.02, [-.16,.12,.13,-.10], [.18,.15,-.11,-.13]],
];

export function makeOrchardPose(body, bones) {
  const originals = new Map();
  const axes = new Map();
  const world = new THREE.Quaternion(), inverse = new THREE.Quaternion();
  const legs = ['del.der','del.izq','tras.der','tras.izq'];

  function rotate(name, angle) {
    const bone = bones.get(name);
    if (!bone) return;
    const axis = axes.get(name) ?? new THREE.Vector3(1,0,0)
      .applyQuaternion(body.getWorldQuaternion(world))
      .applyQuaternion(bone.getWorldQuaternion(inverse).invert());
    axes.set(name,axis);
    originals.set(bone,bone.quaternion.clone());
    bone.rotateOnAxis(axis,angle);
  }

  function reset() {
    for (const [bone, saved] of originals) bone.quaternion.copy(saved);
    originals.clear();
  }

  function update(x, vy, state, reduced) {
    body.position.y = 0;
    if (state === 0 || reduced) return;
    let pitch, nod, swing, bend;
    if (state === 1) {
      const phase = ((x * 1.02) % 1 + 1) % 1;
      const end = gallop.findIndex(frame => frame[0] > phase);
      const a = gallop[end-1], b = gallop[end];
      const t = THREE.MathUtils.smoothstep(phase,a[0],b[0]);
      const mix = (left,right) => THREE.MathUtils.lerp(left,right,t);
      body.position.y = mix(a[1],b[1]);
      pitch = mix(a[2],b[2]); nod = mix(a[3],b[3]);
      swing = a[4].map((n,i) => mix(n,b[4][i]));
      bend = a[5].map((n,i) => mix(n,b[5][i]));
    } else {
      const vertical = THREE.MathUtils.clamp(vy / 7,-1,1);
      const tuck = 1 - Math.abs(vertical);
      pitch = -.19*vertical;
      nod = .105*vertical;
      swing = [-.57+.31*tuck,-.40+.26*tuck,.39+.12*tuck,.28+.10*tuck];
      bend = [.50+.42*tuck,.69+.26*tuck,-.55-.23*tuck,-.68-.21*tuck];
    }
    for (const [i, name] of legs.entries()) {
      rotate(`muslo.${name}`,swing[i]);
      rotate(`pierna.${name}`,bend[i]);
      rotate(`pata.${name}`,-bend[i]*.32);
    }
    rotate('tronco',pitch);
    rotate('cabeza',nod);
    rotate('cola',-.35*pitch);
  }
  return { reset, update };
}
