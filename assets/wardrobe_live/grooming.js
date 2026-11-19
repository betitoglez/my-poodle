import * as THREE from 'three';

// Forelock, near ear and back, matching the order of Strand in the activity.
const anchors = [
  new THREE.Vector3(-0.030, 0.950, 0.368),
  new THREE.Vector3(-0.166, 0.786, 0.343),
  new THREE.Vector3(-0.098, 0.615, -0.180),
];

export function makeGroom() {
  const enabled = { value: 0 };
  const source = { value: new THREE.Vector2() };
  const target = { value: new THREE.Vector2() };
  const comb = { value: new THREE.Vector3() };
  const cut = { value: new THREE.Vector3() };
  const dry = { value: new THREE.Vector3() };
  const smooth = THREE.MathUtils.smoothstep;
  const point = new THREE.Vector3();

  function prepare(mesh) {
    const geometry = mesh.geometry;
    if (geometry.hasAttribute('salonRegions')) return;
    const positions = geometry.attributes.position;
    const regions = new Float32Array(positions.count * 3);
    for (let i = 0; i < positions.count; i++) {
      const x = positions.getX(i), y = positions.getY(i), z = positions.getZ(i);
      const crown = smooth(z, 0.14, 0.25) * smooth(y, 0.853, 0.964);
      const ear = smooth(Math.abs(x), 0.095, 0.183) * smooth(z, 0.14, 0.24) *
        (1 - smooth(z, 0.36, 0.465)) * smooth(y, 0.67, 0.75) * (1 - smooth(y, 0.83, 0.92));
      const back = smooth(z, -0.48, -0.30) * (1 - smooth(z, 0.064, 0.185)) *
        smooth(y, 0.42, 0.62) * (1 - smooth(y, 0.69, 0.78));
      regions[3 * i] = crown;
      regions[3 * i + 1] = ear;
      regions[3 * i + 2] = back;
    }
    const morphs = geometry.morphAttributes.position;
    geometry.setAttribute('salonRegions', new THREE.BufferAttribute(regions, 3));
    geometry.setAttribute('salonPom', morphs[mesh.morphTargetDictionary['Corte pompón']]);
    geometry.setAttribute('salonPuppy', morphs[mesh.morphTargetDictionary['Corte cachorro']]);
    for (const material of [mesh.material].flat()) {
      const compileCoat = material.onBeforeCompile;
      material.onBeforeCompile = (shader, renderer) => {
        compileCoat(shader, renderer);
        Object.assign(shader.uniforms, { salonEnabled: enabled, salonSource: source, salonTarget: target,
          salonComb: comb, salonCut: cut, salonDry: dry });
        shader.vertexShader = `
          attribute vec3 salonRegions, salonPom, salonPuppy;
          uniform vec2 salonSource, salonTarget;
          uniform vec3 salonComb, salonCut, salonDry;
          uniform float salonEnabled;
        ` + shader.vertexShader.replace('#include <morphtarget_vertex>', `
          #include <morphtarget_vertex>
          float crownCut = mix(salonCut.x, salonCut.y, salonRegions.y);
          vec2 style = mix(salonSource, salonTarget, crownCut);
          float textureWave = 0.75 + 0.25 * sin(position.y * 38.0 + position.z * 32.0);
          vec3 loose = 0.052 * salonRegions * (vec3(1.0) - salonComb) * textureWave;
          vec3 volume = 0.023 * salonRegions * salonDry * textureWave;
          vec3 trim = salonRegions * salonCut * vec3(0.0, 0.017, 0.023);
          vec3 tuft = loose - trim + volume;
          vec3 crownLift = vec3(position.x * 3.0, 0.9, (position.z - 0.35) * 1.8);
          vec3 earLift = vec3(position.x * 5.8, -0.12, -0.04);
          vec3 backLift = vec3(position.x * 2.4, 0.75, 0.0);
          transformed += salonEnabled * (salonPom * style.x + salonPuppy * style.y
            + tuft.x * crownLift + tuft.y * earLift + tuft.z * backLift);
        `);
      };
      material.customProgramCacheKey = () => 'poodle-coat-salon';
      material.needsUpdate = true;
    }
  }

  function setSource(pom, puppy, active) {
    source.value.set(Number(Boolean(pom)), Number(Boolean(puppy)));
    enabled.value = Number(Boolean(active));
  }

  function update([pom, puppy, ...progress]) {
    target.value.set(pom, puppy);
    comb.value.fromArray(progress, 0);
    cut.value.fromArray(progress, 3);
    dry.value.fromArray(progress, 6);
  }

  function screenTargets(body, camera) {
    return anchors.flatMap(anchor => {
      body.localToWorld(point.copy(anchor)).project(camera);
      return [(point.x + 1) / 2, (1 - point.y) / 2];
    });
  }

  return { prepare, setSource, update, screenTargets };
}
