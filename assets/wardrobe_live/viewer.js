import * as THREE from 'three';
import { GLTFLoader } from './vendor/loaders/GLTFLoader.js';
import { makeFeedingBowl } from './feeding.js';
import { makeBath } from './bathing.js';
import { makeVet, vetTableHeight } from './veterinary.js';
import { makeGroom } from './grooming.js';
import { makeSleep, makeSleepPose } from './sleeping.js';
import { makeWalk, makeWalkPose, walkWidth } from './walking.js';
import { makeOrchard, makeOrchardPose } from './orchard.js';
import { makeFrisbee } from './frisbee.js';
import { patchCoat, fitCollar, makeIdle } from './appearance.js';

// Colourways share one fitted mesh and its baked fabric maps.
const colourways = {
  'outfit.overalls_red': ['outfit.teal', '#a73836', '#68292c'],
  'outfit.overalls_yellow': ['outfit.teal', '#c7982d', '#866023'],
  'outfit.sweater_blue': ['outfit.sweater_red', '#365d99', '#294471'],
  'outfit.sweater_mustard': ['outfit.sweater_red', '#bd8d29', '#886020'],
  'outfit.raincoat_yellow': ['outfit.raincoat_blue', '#d8aa2e', '#826122'],
  'outfit.raincoat_pink': ['outfit.raincoat_blue', '#c25c83', '#7f3956'],
  'outfit.dress_lilac': ['outfit.dress_pink', '#ab83b8', '#785389'],
  'outfit.dress_turquoise': ['outfit.dress_pink', '#64acaa', '#378481'],
};

const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.35));
renderer.setClearColor(0, 0);
renderer.domElement.addEventListener('webglcontextlost', () => PoodleHost.failed());
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 20);
camera.position.set(0, 0.85, 4);
camera.lookAt(0, 0, 0);
const ambient = new THREE.HemisphereLight(0xfff4e5, 0xb8a094, 2.30);
scene.add(ambient);
const key = new THREE.DirectionalLight(0xffeee2, 2.35);
key.position.set(-2, 3, 3);
scene.add(key);
const rim = new THREE.DirectionalLight(0xd8e7ff, 0.9);
rim.position.set(2, 2, -1);
scene.add(rim);
const turntable = new THREE.Group();
scene.add(turntable);
const bowl = makeFeedingBowl();
turntable.add(bowl.group);
const bath = makeBath();
turntable.add(bath.group);
const vet = makeVet();
turntable.add(vet.table);
scene.add(vet.tools);
const groom = makeGroom();
const bed = makeSleep();
turntable.add(bed.group);
let trail;
let orchard;
let frisbee;

const gltf = await new GLTFLoader().loadAsync('caniche.glb');
turntable.add(gltf.scene);
const items = [];
const restingShells = [];
const bootCuffs = [];
const shoeHems = [];
const bones = new Map();
let tail, head;
gltf.scene.traverse(object => {
  if (object.isBone) bones.set(object.name, object);
  if (object.userData.wear) items.push(object);
  if (object.isBone && object.name === 'cola') tail = object;
  if (object.isBone && object.name === 'cabeza') head = object;
  if (object.isSkinnedMesh) object.frustumCulled = false;
  const fit = object.morphTargetDictionary?.['Holgura tumbado'];
  if (fit !== undefined) restingShells.push([object, fit]);
  const cuff = object.morphTargetDictionary?.['Caña bajo la pernera'];
  if (cuff !== undefined) bootCuffs.push([object, cuff]);
});
const sleepPose = makeSleepPose(gltf.scene, bones);
const walkPose = makeWalkPose(gltf.scene, bones);
const orchardPose = makeOrchardPose(gltf.scene, bones);
const idle = makeIdle(gltf.scene, bones);
const idleOrigin = performance.now();
for (const item of items) {
  item.traverse(mesh => {
    const hem = mesh.morphTargetDictionary?.['Dobladillo con calzado'];
    if (hem !== undefined) shoeHems.push([mesh, hem, item.userData.wear === 'outfit.teal']);
  });
}
const fabricAnisotropy = Math.min(renderer.capabilities.getMaxAnisotropy(), 4);
const dyes = new Map();
for (const item of items.filter(item => item.userData.wear !== 'base')) {
  item.traverse(object => {
    if (!object.isMesh) return;
    for (const material of [object.material].flat()) {
      if (material.map) material.map.anisotropy = fabricAnisotropy;
      if (material.normalMap) material.normalMap.anisotropy = fabricAnisotropy;
      const { catalogDye, creamPattern } = material.userData;
      if (!catalogDye || dyes.has(material)) continue;
      const tint = { value: new THREE.Color(1, 1, 1) };
      dyes.set(material, tint);
      if (!creamPattern) continue;
      material.onBeforeCompile = shader => {
        shader.uniforms.poodleDye = tint;
        shader.fragmentShader = 'uniform vec3 poodleDye;\n' +
          shader.fragmentShader.replace('#include <map_fragment>', `
            #include <map_fragment>
            float cream = smoothstep(0.44, 0.65, diffuseColor.g / max(diffuseColor.r, 0.001));
            diffuseColor.rgb *= mix(poodleDye, vec3(1.0), cream);
          `);
      };
      material.customProgramCacheKey = () => 'poodle-dyed-knit';
    }
  });
}
const tailRest = tail?.quaternion.clone();
const tailAxis = new THREE.Vector3(0, 0, 1);
const headPose = new THREE.Quaternion();
let resetHead = false;
const clip = THREE.AnimationClip.findByName(gltf.animations, 'Tumbarse');
const rainClip = THREE.AnimationClip.findByName(gltf.animations, 'Tumbarse con botas');
const eatClip = THREE.AnimationClip.findByName(gltf.animations, 'Comer');
if (!tail || !clip || !rainClip || !eatClip || !items.some(item => item.userData.wear === 'base')) {
  throw new Error('El modelo no incluye el esqueleto y la animación esperados');
}
const mixer = new THREE.AnimationMixer(gltf.scene);
const action = mixer.clipAction(clip).play();
const rainAction = mixer.clipAction(rainClip).play();
const eatAction = mixer.clipAction(eatClip).play();
const poses = [action, rainAction, eatAction];

const shade = { silver: '#9693a1', lightgray: '#b6b3bf', white: '#e4ded4', black: '#586078' };
const furColor = { value: new THREE.Color(1, 1, 1) };
const recolor = { value: 0 };
const wetness = { value: 0 };
const coatDirt = { value: 0 };
let dailyDirt = 0;
const cuts = { value: new THREE.Vector2() };
const collars = [];
for (const root of items) {
  const wear = root.userData.wear;
  root.traverse(object => {
    if (!object.isMesh) return;
    if (wear.startsWith('collar.')) {
      fitCollar(object);
      collars.push(object);
    }
    if (wear !== 'base') return;
    for (const material of [object.material].flat()) {
      patchCoat(material, {poodleFur: furColor, poodleRecolor: recolor,
        poodleWet: wetness, poodleDirt: coatDirt, poodleCuts: cuts});
    }
  });
}

function setCuts(teddy, showCut) {
  cuts.value.set(teddy, showCut);
  for (const collar of collars) collar.morphTargetInfluences[0] = showCut;
}

let configuration = {x: 0.5, y: 0.8, size: 0.55};
let wear = new Set();
let shoeClearance = false;
let target = 0, phase = 0, wagUntil = 0, last = 0, pending = false;
let biteProgress = 0, bowlBoundsSent = false, bathTargetsSent = false;
let vetTargetsSent = false;
let groomTargetsSent = false;
let sleepBoundsSent = false;
let sleepState = [0, 0, 0];
let walkState = [0.22, 0, 0, -1];
let orchardState = [1, 0, 0, -0.344, 0, 0, 0];
let frisbeeState = [];
let vetState = [0, 0, 0.85, 0.55, 0, -1, 0];
let renderWidth = 0, renderHeight = 0;
function draw() {
  const width = innerWidth;
  const height = innerHeight;
  if (!width || !height) return;
  if (width !== renderWidth || height !== renderHeight) {
    renderer.setSize(width, height, false);
    renderWidth = width;
    renderHeight = height;
  }
  const unit = Math.max(1, configuration.size * height);
  camera.left = -configuration.x * width / unit;
  camera.right = (1 - configuration.x) * width / unit;
  camera.top = configuration.y * height / unit;
  camera.bottom = -(1 - configuration.y) * height / unit;
  camera.updateProjectionMatrix();
  if (configuration.frisbee) frisbee.update(frisbeeState,camera,gltf.scene,turntable,configuration.reduced);
  if (configuration.orchardLevel) {
    orchard.update(orchardState, camera.right - camera.left, configuration.reduced);
  }
  if (configuration.veterinary) {
    vet.update(camera, vetState, configuration.reduced);
    vet.tools.visible = false; // The illustrated instrument is rendered by Flutter.
  }
  renderer.render(scene, camera);
  if (configuration.feeding && !bowlBoundsSent) {
    bowlBoundsSent = true;
    PoodleHost.bowlBounds?.(...bowl.screenBounds(camera));
  }
  if (configuration.bathing && !bathTargetsSent) {
    bathTargetsSent = true;
    PoodleHost.bathTargets?.(JSON.stringify(bath.screenTargets(camera)));
  }
  if (configuration.veterinary && !vetTargetsSent) {
    vetTargetsSent = true;
    PoodleHost.vetTargets?.(JSON.stringify(vet.screenTargets(camera)));
  }
  if (configuration.grooming && !groomTargetsSent) {
    groomTargetsSent = true;
    PoodleHost.groomTargets?.(JSON.stringify(groom.screenTargets(gltf.scene, camera)));
  }
  if (configuration.sleeping && !sleepBoundsSent) {
    sleepBoundsSent = true;
    PoodleHost.sleepBounds?.(JSON.stringify(bed.screenBounds(camera)));
  }
}

function tick(now) {
  pending = false;
  if (configuration.idle && !configuration.reduced && last && now-last < 35 &&
      phase === target && wagUntil <= now) {
    schedule();
    return;
  }
  const delta = last ? Math.min((now - last) / 1000, 0.05) : 1 / 60;
  last = now;
  phase += Math.sign(target - phase) * Math.min(Math.abs(target - phase), delta * 1.35);
  sleepPose.reset();
  walkPose.reset();
  orchardPose.reset();
  idle.reset();
  tail.quaternion.copy(tailRest);
  if (resetHead) {
    head.quaternion.copy(headPose);
    resetHead = false;
  }
  const [walkX, walkPan, traveling, sniff] = walkState;
  const sniffing = configuration.walking && sniff >= 0;
  const activePose = configuration.feeding || sniffing ? eatAction : shoeClearance ? rainAction : action;
  const passive = configuration.passiveBed && (phase > 0 || target > 0);
  const [arrival, blanket, dark] = passive ? [phase, 0, 0] : sleepState;
  const restingInBed = configuration.sleeping || passive;
  const poseProgress = configuration.sleeping ? THREE.MathUtils.smoothstep(arrival, 0.38, 1) : phase;
  for (const pose of poses) {
    pose.setEffectiveWeight(pose === activePose ? 1 : 0);
    const duration = pose.getClip().duration;
    const position = pose === eatAction
      ? (sniffing ? (configuration.reduced ? 0.52 : sniff) : biteProgress)
      : poseProgress;
    pose.time = Math.min(position * duration, duration - 0.0001);
  }
  mixer.update(0);
  if (configuration.frisbee && frisbeeState.length >= 13) {
    orchardPose.update(frisbeeState[12]*3,2,frisbeeState[4],configuration.reduced);
  }
  if (configuration.orchardLevel) {
    const [x,y,vy,pan,pose] = orchardState;
    turntable.position.set(x-pan,y,0);
    orchardPose.update(x,vy,pose,configuration.reduced);
  }
  if (configuration.walking) {
    turntable.position.x = (walkX - walkPan) * walkWidth;
    const investigate = sniffing ? THREE.MathUtils.smoothstep(sniff, 0, 0.34) *
      (1 - THREE.MathUtils.smoothstep(sniff, 0.68, 1)) : 0;
    turntable.rotation.y = 1.22 + 0.30 * investigate;
    trail.update(walkX * walkWidth, walkPan * walkWidth, now * 0.001);
    walkPose.update(walkX * walkWidth, traveling, sniff, configuration.reduced);
  }
  const asleep = (configuration.sleeping && dark > 0 || passive && phase >= .99) && !configuration.reduced;
  bed.group.visible = restingInBed;
  if (restingInBed) {
    const breath = asleep ? 0.004 * Math.sin(now / 425) : 0;
    sleepPose.update(arrival, breath, configuration.reduced,!passive);
    bed.blanket(blanket, breath);
    ambient.intensity = THREE.MathUtils.lerp(2.30, 1.02, dark);
    ambient.color.set(0xfff4e5).lerp(nightBlue, dark * 0.66);
    key.intensity = THREE.MathUtils.lerp(2.35, 0.35, dark);
    rim.intensity = THREE.MathUtils.lerp(0.9, 0.69, dark);
  }
  idle.update(configuration, (now-idleOrigin)*.001,configuration.reduced,restingInBed || phase>.04);
  if (configuration.veterinary && !configuration.reduced && vetState[0] === 2 &&
      vetState[5] >= 0 && head) {
    headPose.copy(head.quaternion);
    resetHead = true;
    head.rotateX(0.16 * Math.sin(Math.PI * vetState[5]));
  }
  const rest = THREE.MathUtils.smoothstep(phase, 0, 1);
  for (const [shell, index] of restingShells) {
    shell.morphTargetInfluences[index] = rest;
  }
  const cuffFit = wear.has('outfit.teal') ? 1 : shoeClearance ? rest : 0;
  for (const [boot, index] of bootCuffs) {
    boot.morphTargetInfluences[index] = cuffFit;
  }
  const skirt = THREE.MathUtils.smoothstep(phase, 0, 0.625) * (wear.has('paws.rain') ? 1 : 0.62);
  for (const [mesh, index, overalls] of shoeHems) {
    mesh.morphTargetInfluences[index] = shoeClearance ? (overalls ? rest : skirt) : 0;
  }
  const remaining = Math.max(0, wagUntil - now);
  if (remaining) {
    const strength = Math.min(remaining / 420, 1) * (configuration.reduced ? 0.20 : 0.58);
    tail.rotateOnAxis(tailAxis, Math.sin(now * 0.024) * strength);
  }
  draw();
  const flowing = configuration.walking && walkX > 1.4 && !configuration.reduced;
  if (phase !== target || remaining || asleep || flowing || (configuration.idle && !configuration.reduced)) schedule();
  else last = 0;
}

function schedule() {
  if (pending) return;
  pending = true;
  requestAnimationFrame(tick);
}

const nightBlue = new THREE.Color(0x7985cf);

window.poodle = {
  configure(newConfiguration) {
    const wasFeeding = configuration.feeding;
    const wasBathing = configuration.bathing;
    const wasVeterinary = configuration.veterinary;
    const wasGrooming = configuration.grooming;
    const wasSleeping = configuration.sleeping;
    const wasWalking = configuration.walking;
    const wasOrchard = Boolean(configuration.orchardLevel);
    const wasFrisbee = configuration.frisbee;
    const wasBed = configuration.passiveBed && configuration.resting;
    configuration = { ...configuration, ...newConfiguration };
    const inOrchard = Boolean(configuration.orchardLevel);
    const atHomeInBed = configuration.passiveBed && configuration.resting;
    if (configuration.feeding !== wasFeeding || configuration.bathing !== wasBathing ||
        configuration.veterinary !== wasVeterinary || configuration.grooming !== wasGrooming ||
        configuration.sleeping !== wasSleeping || configuration.walking !== wasWalking ||
        inOrchard !== wasOrchard || configuration.frisbee !== wasFrisbee || wasBed !== atHomeInBed) {
      turntable.rotation.y = configuration.feeding ? 1.10 : configuration.bathing ? 0.91 :
        configuration.veterinary ? 0.70 : configuration.grooming ? 0.72 :
        configuration.sleeping || atHomeInBed ? 0.93 : configuration.walking || inOrchard ? 1.26 : 0;
      camera.position.y = configuration.feeding ? 2.22 : configuration.bathing ? 1.50 :
        configuration.veterinary ? 1.38 : configuration.grooming ? 1.26 :
        configuration.sleeping || atHomeInBed ? 2.52 : configuration.walking ? 2.22 : inOrchard ? 1.05 :
        configuration.frisbee ? 2.05 : 0.85;
      camera.lookAt(0, 0, 0);
      camera.updateMatrixWorld();
    }
    bowl.group.visible = Boolean(configuration.feeding);
    bath.group.visible = Boolean(configuration.bathing);
    vet.table.visible = Boolean(configuration.veterinary);
    bed.group.visible = Boolean(configuration.sleeping);
    if (configuration.walking && !trail) {
      trail = makeWalk();
      scene.add(trail.group);
    }
    if (trail) trail.group.visible = Boolean(configuration.walking);
    if (configuration.orchardLevel && !orchard) {
      orchard = makeOrchard(configuration.orchardLevel);
      scene.add(orchard.group);
    }
    if (orchard) orchard.group.visible = inOrchard;
    if (configuration.frisbee && !frisbee) {
      frisbee = makeFrisbee();
      scene.add(frisbee.group);
    }
    if (frisbee) frisbee.group.visible = Boolean(configuration.frisbee);
    if (wasFrisbee && !configuration.frisbee) {
      gltf.scene.scale.setScalar(1);
      turntable.position.set(0,0,0);
    }
    if (wasOrchard || inOrchard) {
      gltf.scene.scale.setScalar(inOrchard ? 0.88 : 1);
      if (!inOrchard) turntable.position.set(0,0,0);
    }
    if (wasWalking && !configuration.walking) turntable.position.x = 0;
    if (wasSleeping && !configuration.sleeping) {
      gltf.scene.scale.setScalar(1);
      gltf.scene.rotation.y = 0;
      gltf.scene.position.set(0, 0, 0);
      ambient.intensity = 2.30;
      ambient.color.set(0xfff4e5);
      key.intensity = 2.35;
      rim.intensity = 0.9;
    }
    if (!configuration.veterinary) vet.tools.visible = false;
    gltf.scene.position.y = configuration.bathing ? 0.042 :
      configuration.veterinary ? vetTableHeight : 0;
    if (!configuration.bathing) wetness.value = 0;
    bowlBoundsSent = false;
    bathTargetsSent = false;
    vetTargetsSent = false;
    groomTargetsSent = false;
    sleepBoundsSent = false;
    target = configuration.resting ? 1 : 0;
    if (configuration.reduced) phase = target;
    turntable.visible = configuration.visible !== false;
    const selected = configuration.wear || [];
    const variants = new Map(selected.filter(id => colourways[id]).map(id => {
      const [model, fabric, binding] = colourways[id];
      return [model, { fabric, binding }];
    }));
    wear = new Set(selected.map(id => colourways[id]?.[0] ?? id));
    const neckwear = selected.some(id => id.startsWith('neck.'));
    const layeredBoots = wear.has('outfit.teal') && wear.has('paws.rain');
    shoeClearance = !layeredBoots && selected.some(id => id.startsWith('outfit.')) &&
      selected.some(id => id.startsWith('paws.'));
    const coat = shade[configuration.coat];
    setCuts(Number(Boolean(configuration.teddy)), Number(Boolean(configuration.showCut)));
    const hygiene = configuration.hygiene ?? 100;
    dailyDirt = hygiene >= 65 ? 0 : Math.min(5,Math.ceil((65-hygiene)/13));
    coatDirt.value = dailyDirt;
    groom.setSource(configuration.pom, configuration.puppy, configuration.grooming);
    furColor.value.set(coat || '#ffffff');
    recolor.value = coat ? 1 : 0;
    for (const item of items) {
      const part = item.userData.wear;
      item.visible = (part === 'base' || wear.has(part)) &&
        !(neckwear && item.userData.underNeckwear);
      if (!item.visible) continue;
      const palette = variants.get(part);
      item.traverse(mesh => {
        for (const material of [mesh.material].flat()) {
          const tint = dyes.get(material);
          if (!tint) continue;
          const { catalogDye, dyeRole, creamPattern } = material.userData;
          const color = palette?.[dyeRole];
          if (color) {
            tint.value.set(color);
            const [r, g, b] = catalogDye;
            tint.value.setRGB(tint.value.r / r, tint.value.g / g, tint.value.b / b);
          } else {
            tint.value.setRGB(1, 1, 1);
          }
          if (!creamPattern) material.color.copy(tint.value);
        }
        const keys = mesh.morphTargetDictionary;
        if (!keys) return;
        const salonBody = configuration.grooming && part === 'base';
        if (salonBody) groom.prepare(mesh);
        const pomp = keys['Corte pompón'];
        if (pomp !== undefined) mesh.morphTargetInfluences[pomp] =
          !salonBody && configuration.pom ? (wear.has('head.beanie') || wear.has('head.crown') ? 0.1 : 1) : 0;
        const puppy = keys['Corte cachorro'];
        if (puppy !== undefined) mesh.morphTargetInfluences[puppy] = !salonBody && configuration.puppy ? 1 : 0;
      });
    }
    schedule();
  },
  rotate(delta) {
    turntable.rotation.y -= delta * 0.013;
    schedule();
  },
  front() {
    turntable.rotation.y = 0;
    schedule();
  },
  pet() {
    wagUntil = performance.now() + 1800;
    schedule();
  },
  feed([progress, fill]) {
    biteProgress = THREE.MathUtils.clamp(progress, 0, 1);
    bowl.fill(THREE.MathUtils.clamp(fill, 0, 1));
    schedule();
  },
  bath([phase, progress, ...suds]) {
    wetness.value = phase === 0 ? progress : phase === 3 ? 1 - progress : phase === 4 ? 0 : 1;
    coatDirt.value = phase < 2 ? dailyDirt : phase === 2 ? dailyDirt*(1-progress) : 0;
    bath.update(phase, progress, suds);
    schedule();
  },
  vet(state) {
    if (state[0] === 2 && state[5] >= 0 && vetState[5] < 0) {
      wagUntil = performance.now() + 1250;
    }
    vetState = state;
    schedule();
  },
  groom(state) {
    groom.update(state);
    if (state.length >= 13) {
      const cut = (state[5]+state[6]+state[7])/3;
      setCuts(THREE.MathUtils.lerp(Number(Boolean(configuration.teddy)),state[11],cut),
        THREE.MathUtils.lerp(Number(Boolean(configuration.showCut)),state[12],cut));
    }
    schedule();
  },
  sleep(state) {
    sleepState = state;
    schedule();
  },
  walk(state) {
    walkState = state;
    schedule();
  },
  orchard(state) {
    orchardState = state;
    schedule();
  },
  frisbee(state) {
    frisbeeState = state;
    schedule();
  }
};
window.addEventListener('resize', () => {
  bowlBoundsSent = false;
  bathTargetsSent = false;
  vetTargetsSent = false;
  groomTargetsSent = false;
  sleepBoundsSent = false;
  schedule();
});
schedule();
PoodleHost.ready();
