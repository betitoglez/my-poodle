import * as THREE from 'three';
import { patternGLSL } from './patterns.js';

export function bindTail(mesh, trunk, tail) {
  if (!mesh.isSkinnedMesh) return;
  const trunkIndex = mesh.skeleton.bones.indexOf(trunk);
  const tailIndex = mesh.skeleton.bones.indexOf(tail);
  const { position, skinIndex, skinWeight } = mesh.geometry.attributes;
  const smooth = THREE.MathUtils.smoothstep;
  for (let i = 0; i < position.count; i++) {
    // Blend the base into the rump and bind the full pom-pom to the tail joint.
    const weight = smooth(position.getY(i), .575, .660) *
      smooth(-position.getZ(i), .326, .382);
    if (weight === 0) continue;
    skinIndex.setXYZW(i, trunkIndex, tailIndex, 0, 0);
    skinWeight.setXYZW(i, 1 - weight, weight, 0, 0);
  }
  skinIndex.needsUpdate = true;
  skinWeight.needsUpdate = true;
}

export function patchCoat(material, uniforms) {
  material.onBeforeCompile = shader => {
    Object.assign(shader.uniforms, uniforms);
    shader.vertexShader = `
      uniform vec2 poodleCuts;
      uniform vec3 poodleCover;
      uniform vec4 poodleZones;
      uniform vec4 poodleWet;
      uniform float poodleDirt, poodleMouthOpen, poodleExtraCurl;
      varying vec3 poodleRestPosition;
      varying float poodleShortCoat, poodleHatHeight;
      varying float poodleMouthInterior;
      varying float poodleDampness;
    ` + shader.vertexShader.replace('#include <morphtarget_vertex>', `
      #include <morphtarget_vertex>
      poodleRestPosition = position;
      vec3 p = position;
      float head = smoothstep(.76,.96,p.y) * smoothstep(.15,.25,p.z);
      float ear = smoothstep(.095,.186,abs(p.x)) * smoothstep(.655,.735,p.y)
        * (1.0 - smoothstep(.81,.925,p.y)) * smoothstep(.15,.25,p.z);
      transformed += poodleCuts.x * vec3(-p.x*.14*ear, -head*.045 + ear*.025, -head*.012);

      float leg = (1.0 - smoothstep(.25,.49,p.y)) * smoothstep(.025,.09,p.y);
      float cuffs = smoothstep(.067,.135,p.y) * (1.0-smoothstep(.206,.291,p.y));
      float hind = (1.0-smoothstep(-.14,.015,p.z)) * smoothstep(.27,.39,p.y)
        * (1.0-smoothstep(.69,.75,p.y));
      float throat = smoothstep(.27,.345,p.z) * smoothstep(.50,.56,p.y) * (1.0-smoothstep(.64,.706,p.y));
      float muzzle = smoothstep(.448,.517,p.z) * (1.0-smoothstep(.715,.77,p.y));
      float hipPom = smoothstep(.085,.142,abs(p.x)) * smoothstep(.44,.51,p.y) * (1.0-smoothstep(.59,.652,p.y))
        * smoothstep(-.435,-.36,p.z) * (1.0-smoothstep(-.275,-.22,p.z));
      float shave = leg*(1.0-cuffs);
      poodleShortCoat = clamp(max(max(shave,hind*(1.0-hipPom)),max(throat,muzzle))*poodleCuts.y,0.0,1.0);
      vec3 legCenter = vec3(sign(p.x)*.098,p.y,p.z > .0 ? .258 : -.355);
      vec3 rearCenter = vec3(0.0,.44,-.335);
      vec3 contour = (legCenter-p)*shave*vec3(.43,0.0,.31)
        + (rearCenter-p)*hind*(1.0-hipPom)*vec3(.45,.095,.10)
        + vec3(-p.x*.19*throat,0.0,-.038*throat)
        + vec3(-p.x*.19*muzzle,0.0,-.016*muzzle);
      contour += (p-legCenter)*vec3(.46,0.0,.15)*cuffs;
      contour += vec3(p.x*.24,.075,0.0)*head;
      transformed += poodleCuts.y * contour;
      // Independent styles for head, legs, back and tail (0 natural, 1 teddy,
      // 2 pom, 3 puppy, 4 contest, 5 modern, 6 uniform tail). Feathered masks hide seams.
      if (poodleZones.x >= 0.0) {
        float tailZone = smoothstep(.575,.660,p.y) * smoothstep(.326,.382,-p.z);
        float headZone = max(head,ear);
        float backZone = smoothstep(.40,.52,p.y) * (1.0-smoothstep(.70,.79,p.y))
          * (1.0-smoothstep(.10,.24,p.z)) * (1.0-tailZone);
        float legsZone = (1.0-smoothstep(.38,.49,p.y)) * (1.0-tailZone);
        vec4 masks = vec4(headZone, legsZone, backZone, tailZone);
        float shorter = 0.0;
        for (int region = 0; region < 4; region++) {
          float style = poodleZones[region];
          float mask = masks[region];
          vec3 center = region == 0 ? vec3(0.0,.82,.32) : region == 1 ? legCenter : region == 2 ? vec3(0.0,.55,-.10) : vec3(0.0,.71,-.40);
          vec3 radial = p - center;
          if (style > .5 && style < 1.5) transformed += mask * (radial*vec3(.12,.07,.10) + vec3(0.0,.015,0.0));
          else if (style < 2.5 && style > 1.5) {
            float puff = region == 1 ? cuffs : region == 2 ? .15 : 1.0;
            transformed += mask * radial * (.24*puff-.17*(1.0-puff));
            shorter += mask*(1.0-puff)*.65;
          } else if (style < 3.5 && style > 2.5) {
            transformed -= mask * radial * vec3(.27,.12,.22);
            shorter += mask*.85;
          } else if (style < 4.5 && style > 3.5) {
            if (region == 0) transformed += mask * (vec3(p.x*.24,.075,0.0)*head + vec3(-p.x*.19,0.0,-.016)*muzzle);
            else if (region == 1) transformed += mask * ((legCenter-p)*vec3(.43,0.0,.31)*(1.0-cuffs) + radial*vec3(.46,0.0,.15)*cuffs);
            else if (region == 2) transformed += mask * (rearCenter-p)*vec3(.45,.095,.10)*(1.0-hipPom);
            else transformed += mask * radial * vec3(.27,.23,.20);
            shorter += mask * (region == 1 ? 1.0-cuffs : region == 2 ? 1.0-hipPom : 0.0);
          } else if (style > 4.5) {
            if (region == 3 && style > 5.5) {
              vec3 root = vec3(0.0,.604,-.345);
              vec3 axis = normalize(vec3(0.0,.80,-.60));
              float along = clamp(dot(p-root,axis),0.0,.245);
              vec3 perpendicular = p-root-axis*dot(p-root,axis);
              vec3 uniformTail = root + axis*along + perpendicular / max(length(perpendicular),.0001)*.021;
              transformed += mask*(uniformTail-p);
              shorter += mask*.75;
              continue;
            }
            float crest = 1.0-smoothstep(.025,.095,abs(p.x));
            transformed += mask * (region == 0 ? vec3(-p.x*.12, .09*crest*head, 0.0) : region == 1 ? radial*vec3(.23,0.0,.16)*cuffs : region == 2 ? vec3(-p.x*.10,.045*crest,0.0) : vec3(p.x*.28,.035,-.045));
          }
        }
        poodleShortCoat = clamp(shorter,0.0,1.0);
      }
      float tousled = clamp((poodleDirt-1.0)*.2,0.0,1.0) * (.023*ear+.019*head);
      transformed += vec3(p.x*3.0,.68,.30) * tousled * sin(p.y*68.0-p.z*53.0);

      // Blend neighbouring bath areas in rest coordinates, even as the rig moves.
      float faceWet = smoothstep(.64,.76,p.y) * smoothstep(.10,.28,p.z);
      float pawsWet = 1.0 - smoothstep(.27,.40,p.y);
      float chestArea = smoothstep(.015,.24,p.z);
      float bodyArea = 1.0 - faceWet - pawsWet;
      poodleDampness = dot(poodleWet,
        vec4(bodyArea*(1.0-chestArea),pawsWet,bodyArea*chestArea,faceWet));
      transformed -= normal * (.007*poodleDampness);
      float crownAndBack = max(head, smoothstep(.48,.66,p.y) *
        (1.0-smoothstep(-.08,.21,p.z)) * (1.0-smoothstep(.68,.76,p.y)));
      float curlRidges = sin(89.0*p.z + 2.5*sin(p.y*66.0)) *
        sin(91.0*p.x + 2.5*sin(p.z*73.0));
      transformed += normal * (.013 + .008*curlRidges) * crownAndBack * poodleExtraCurl;

      poodleHatHeight = transformed.y;
      // Seat every cut inside the hat, after granular styles, curls and dirt.
      // The hat follows the same head joint, so clearance holds while moving.
      if (poodleCover.x > .5 && p.y > .84 && p.z > .06) {
        bool beanie = poodleCover.x < 1.5;
        vec3 center = vec3(-.0015,beanie ? .89 : .93,.296);
        vec3 radius = beanie ? vec3(.154,.140,.164) : vec3(.130,.045,.118);
        vec3 delta = transformed-center;
        float fit = length(delta/radius);
        float seated = smoothstep(beanie ? .855 : .90,beanie ? .890 : .939,p.y);
        if (fit > 1.0) transformed = mix(transformed,center+delta/fit,seated);
      }

      // Stretch the lip seam while lowering just the jaw in front of the throat.
      float lipWidth = abs(p.x+.008);
      float lip = p.y - (.704 - .003*smoothstep(.022,.075,lipWidth));
      float jaw = smoothstep(.414,.482,p.z) * (1.0-smoothstep(.049,.092,lipWidth))
        * smoothstep(.644,.673,p.y) * (1.0-smoothstep(-.012,.003,lip));
      transformed += poodleMouthOpen * jaw * vec3(0.0,-.033,-.006);
      poodleMouthInterior = smoothstep(.465,.493,p.z) * (1.0-smoothstep(.055,.080,lipWidth))
        * smoothstep(-.017,-.009,lip) * (1.0-smoothstep(-.004,.003,lip));
    `);
    shader.fragmentShader = `
      uniform vec3 poodleFur;
      uniform vec3 poodleCover;
      uniform float poodlePatternCode;
      uniform float poodleRecolor, poodleDirt, poodleMouthOpen, poodleExtraCurl;
      varying vec3 poodleRestPosition;
      varying float poodleShortCoat, poodleHatHeight;
      varying float poodleMouthInterior;
      varying float poodleDampness;
    ` + patternGLSL + shader.fragmentShader.replace('#include <clipping_planes_fragment>', `
      #include <clipping_planes_fragment>
      if (poodleCover.x > .5 && poodleCover.x < 1.5 &&
          poodleRestPosition.z > .06 && poodleHatHeight > .894) discard;
      if (poodleCover.z > 0.0 && poodleRestPosition.y < poodleCover.z) discard;
      // Same rest-space opening planes as garments.py::hem_limit. Hide only
      // covered fur, instead of drawing enlarged cuffs through the fabric.
      // Fore/rear landmarks are the averaged root joints of the bundled GLB.
      if (poodleCover.y > .5) {
        vec3 p = poodleRestPosition;
        float along = -p.z;
        float lower = .168;
        if (poodleCover.y > 1.5 && poodleCover.y < 2.5)
          lower = .220 + .025*smoothstep(-.22,.17,along);
        else if (poodleCover.y > 2.5 && poodleCover.y < 3.5)
          lower = .238 + .045*smoothstep(-.2,.2,along);
        else if (poodleCover.y > 3.5)
          lower = .420 + .065*smoothstep(-.28,-.16,along);
        float tailOpening = .705-1.53*max(along-.439827+.083,0.0)
          + .037*smoothstep(.065,.140,abs(p.x));
        float neckOpening = .642+.20*max(along+.180323,0.0);
        if (p.y > lower+.002 && p.y < min(tailOpening,neckOpening)-.006) discard;
      }
    `).replace('#include <map_fragment>', `
      #include <map_fragment>
      float tone = dot(diffuseColor.rgb, vec3(.24,.65,.11));
      // Remove the original chroma even in deep shadows while keeping the darkest features dark.
      float pigment = smoothstep(.006,.099,tone);
      vec3 dyed = mix(vec3(tone*.68), poodleFur * pow(tone, .90) * 1.26, pigment);
      if (poodlePatternCode > .5) dyed = mix(vec3(tone*.68), poodlePattern(poodleRestPosition, poodlePatternCode, poodleFur) * pow(tone,.90)*1.26, pigment);
      diffuseColor.rgb = mix(diffuseColor.rgb,dyed,poodleRecolor);
      diffuseColor.rgb *= 1.0-.13*poodleShortCoat*smoothstep(.012,.09,tone);
      vec3 p = poodleRestPosition;
      float patches = sin(p.z*38.0 + p.x*31.0 + sin(p.y*43.0)) * cos(p.x*49.0-p.y*31.0);
      float onCoat = (1.0-smoothstep(.79,1.01,p.y)*.65) * smoothstep(.006,.077,tone);
      float dirt = smoothstep(.9-poodleDirt*.145,.93,patches)*onCoat*min(1.0,poodleDirt*.27);
      diffuseColor.rgb = mix(diffuseColor.rgb, diffuseColor.rgb*.31+vec3(.084,.043,.017), dirt*.93);
      diffuseColor.rgb *= mix(vec3(1.0),vec3(.64,.70,.74),poodleDampness);
      float curlLight = smoothstep(.54,.75,p.y) * smoothstep(.020,.095,tone);
      diffuseColor.rgb *= 1.0 + (tone-.20) * .32 * curlLight * poodleExtraCurl;
      diffuseColor.rgb = mix(diffuseColor.rgb,vec3(.021,.006,.008),
        poodleMouthInterior*smoothstep(.10,.62,poodleMouthOpen));
    `).replace('#include <roughnessmap_fragment>', `
      #include <roughnessmap_fragment>
      roughnessFactor *= mix(1.0,.50,poodleDampness);
    `);
  };
  material.customProgramCacheKey = () => 'poodle-coat';
}

export function fitCollar(mesh) {
  mesh.geometry = mesh.geometry.clone();
  const position = mesh.geometry.attributes.position;
  const showCut = position.clone();
  const overGarment = position.clone();
  for (let i = 0; i < position.count; i++) {
    const x = position.getX(i) * .91;
    const originalDepth = position.getZ(i);
    const nape = 1 - THREE.MathUtils.smoothstep(originalDepth, .12, .44);
    const y = .624 + (position.getY(i) - .704) * .48 + .062 * nape;
    const depth = .230 + (originalDepth - .277) * .77;
    // Follow the throat without pulling the sides or nape forward.
    const front = THREE.MathUtils.smoothstep(depth, .293, .370);
    const shoulder = THREE.MathUtils.smoothstep(Math.abs(x), .025, .082);
    const z = depth - front * (.033 + .022 * shoulder);
    // The contest cut shaves the throat more deeply at the center than at the sides.
    const shaved = THREE.MathUtils.lerp(.037, .018,
      THREE.MathUtils.smoothstep(Math.abs(x), .046, .100));
    position.setXYZ(i, x, y, z);
    showCut.setXYZ(i, x, y, z - front * shaved);
    // Follow the bound opening at the sides and lay the front across the fabric.
    const neckline = THREE.MathUtils.smoothstep(depth, .20, .36);
    const sides = THREE.MathUtils.smoothstep(depth, .20, .29)
      * (1 - THREE.MathUtils.smoothstep(depth, .32, .372));
    const sideClearance = THREE.MathUtils.smoothstep(depth, .18, .21)
      * (1 - THREE.MathUtils.smoothstep(depth, .27, .35));
    const hanging = mesh.userData.underNeckwear
      ? 1 - THREE.MathUtils.smoothstep(y, .594, .613) : 0;
    overGarment.setXYZ(i, x + Math.sign(x) * .040 * sideClearance,
      y + .018 * neckline + .026 * sides,
      z + neckline * (.030 + .034 * shoulder + .018 * hanging));
  }
  mesh.geometry.morphAttributes.position = [showCut, overGarment];
  mesh.updateMorphTargets();
  position.needsUpdate = true;
  mesh.geometry.computeVertexNormals();
  mesh.geometry.computeBoundingSphere();
}

export function makeIdle(body, bones) {
  const mouthOpen = { value: 0 };
  const muzzle = new THREE.Group();
  body.add(muzzle);
  // Most of the lower muzzle is bound to the neck, so the tongue follows it as well.
  bones.get('cuello').attach(muzzle);
  const tongue = new THREE.Mesh(new THREE.SphereGeometry(1,18,12),
    new THREE.MeshStandardMaterial({color:'#bd686e',roughness:.66}));
  muzzle.add(tongue);
  tongue.visible = false;
  const drops = [];
  const water = new THREE.MeshStandardMaterial({color:'#9bdaea', roughness:.28, metalness:.05});
  for (let i=0;i<3;i++) {
    const drop = new THREE.Mesh(new THREE.SphereGeometry(1,10,8),water);
    drop.visible = false;
    body.add(drop);
    drops.push(drop);
  }
  const saved = new Map();
  const rootRotation = new THREE.Quaternion(), boneRotation = new THREE.Quaternion();
  const axis = new THREE.Vector3();
  function turn(name,x,y,z,angle) {
    const bone = bones.get(name);
    if (!bone) return;
    if (!saved.has(bone)) saved.set(bone,bone.quaternion.clone());
    body.getWorldQuaternion(rootRotation);
    bone.getWorldQuaternion(boneRotation).invert();
    axis.set(x,y,z).applyQuaternion(rootRotation).applyQuaternion(boneRotation);
    bone.rotateOnAxis(axis,angle);
  }
  function reset() {
    for (const [bone,q] of saved) bone.quaternion.copy(q);
    saved.clear();
    mouthOpen.value = 0;
    tongue.visible = false;
    for (const drop of drops) drop.visible = false;
  }
  function update(config, seconds, still, resting, greetingWag) {
    if ((!config.idle && !config.sick) || resting) return;
    still = still || !config.idle;
    const sad = Math.max(0, (42-(config.mood??100))/42);
    const tired = Math.max(0,(28-(config.energy??100))/28);
    const sick = config.sick ? 1 : 0;
    const dejected = Math.max(sad,tired,sick*.80);
    const wave = still ? 0 : Math.sin(seconds*1.9);
    turn('cuello',1,0,0,.21*dejected+wave*.025);
    turn('cabeza',0,1,0,still ? 0 : Math.sin(seconds*.93)*.12*(1-dejected));
    const wag = still || greetingWag ? 0 : Math.sin(seconds*16)*(.08+.29*Math.max(0,Math.sin(seconds*1.6)))*(1-dejected);
    turn('cola',0,1,0,wag);
    turn('cola',1,0,0,-.31*dejected);
    const pant = seconds%6.1;
    if (!still && dejected < .5 && pant > 1.97 && pant < 3.87) {
      const open = THREE.MathUtils.smoothstep(pant,1.97,2.34)*(1-THREE.MathUtils.smoothstep(pant,3.48,3.87));
      const extend = THREE.MathUtils.smoothstep(pant,2.15,2.46)*(1-THREE.MathUtils.smoothstep(pant,3.26,3.65));
      mouthOpen.value = open * (.93 + .07 * Math.sin(seconds * 20));
      tongue.visible = extend > .025;
      tongue.position.set(-.008,.697-.020*extend,.479+.049*extend-(config.showCut ? .014 : 0));
      tongue.scale.set(.025,.010+.004*extend,.025+.024*extend);
      tongue.rotation.x = .52;
    }
    if (sick > 0) {
      drops.forEach((drop,i) => {
        const k = still ? .18+i*.17 : (seconds*.64+i*.28)%1;
        drop.visible = k < .83;
        drop.position.set((i-1)*.079,.931-k*.16,.477+.061*k);
        drop.scale.set(.017-.005*k,.031-.008*k,.014);
      });
    }
  }
  return { reset, update, mouthOpen };
}
