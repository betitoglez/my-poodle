import * as THREE from 'three';

const smooth = THREE.MathUtils.smoothstep;
const riseSeconds = .42;
const holdSeconds = 5;
const fallSeconds = .44;

export function makeRoomMotion(turntable, walkPose) {
  let rearStart = null, wagStart = null, reactionYaw = null;
  let segment = null, direction = 1, distance = 0, nextWalk = 0;
  let lift = 0, wag = 0;

  function pause(now, milliseconds) {
    segment = null;
    nextWalk = now + milliseconds;
    reactionYaw = null;
  }

  function reset(now) {
    pause(now, 2700);
    rearStart = null;
    wagStart = null;
    lift = 0;
    wag = 0;
    turntable.position.x = 0;
    direction = 1;
    distance = 0;
  }

  function react(now, roaming) {
    if (rearStart !== null) return false;
    pause(now, (riseSeconds + holdSeconds + fallSeconds + 1.9) * 1000);
    rearStart = now;
    wagStart = now;
    if (roaming) reactionYaw = Math.sin(turntable.rotation.y) < 0 ? -.91 : .91;
    return true;
  }

  function face(yaw, delta) {
    const difference = yaw - turntable.rotation.y;
    const shortest = Math.atan2(Math.sin(difference), Math.cos(difference));
    turntable.rotation.y += shortest * Math.min(1, 8 * delta);
  }

  function update(now, delta, configuration, limit, available) {
    lift = 0;
    wag = 0;
    if (!available) rearStart = null;
    if (wagStart !== null) {
      const elapsed = (now - wagStart) / 1000;
      if (configuration.reduced || !available || elapsed >= 20) {
        wagStart = null;
      } else {
        wag = Math.sin(elapsed * 19.5) * .87 * smooth(elapsed, 0, .25) *
          (1 - smooth(elapsed, 19.5, 20));
      }
    }
    if (rearStart !== null) {
      const elapsed = Math.max(0, (now - rearStart) / 1000);
      const reduced = configuration.reduced;
      const finish = reduced ? holdSeconds : riseSeconds + holdSeconds + fallSeconds;
      if (elapsed < finish) {
        lift = reduced ? 1 : smooth(elapsed, 0, riseSeconds) *
          (1 - smooth(elapsed, finish - fallSeconds, finish));
        if (!reduced) {
          if (reactionYaw !== null) face(reactionYaw, delta);
        }
        walkPose.rear(lift, reduced ? 0 : Math.sin(elapsed * 3.4));
        return;
      }
      rearStart = null;
    }

    if (!configuration.roaming || configuration.reduced || !available) {
      walkPose.update(0, false, -1, false);
      return;
    }
    if (now < nextWalk) {
      walkPose.update(distance, false, -1, false);
      return;
    }
    if (!segment) {
      const from = turntable.position.x;
      if (Math.abs(direction * limit - from) < .035) direction *= -1;
      const to = direction * limit;
      segment = { from, to, duration: .60 + Math.abs(to - from) / .40, time: 0 };
    }
    const step = Math.min(1, (segment.time += delta) / segment.duration);
    const position = THREE.MathUtils.lerp(segment.from, segment.to, smooth(step, 0, 1));
    distance += Math.abs(position - turntable.position.x);
    turntable.position.x = position;
    const turning = smooth(step, 0, .19) * (1 - smooth(step, .72, 1));
    face(direction * 1.52 * turning, delta);
    walkPose.update(distance, true, -1, false, 1 - smooth(step, .76, 1));
    if (step === 1) {
      direction *= -1;
      pause(now, 2500);
    }
  }

  return { pause, reset, react, update,
    get active() { return rearStart !== null; },
    get wagging() { return wagStart !== null; },
    get lift() { return lift; },
    get wag() { return wag; } };
}

export function makePetHitTest(body, bones) {
  const targets = [];
  function attach(name, center, scale) {
    const target = new THREE.Object3D();
    target.position.set(...center);
    target.scale.set(...scale);
    body.add(target);
    bones.get(name).attach(target);
    targets.push(target);
  }
  attach('tronco', [0,.48,-.06], [.17,.17,.38]);
  attach('cuello', [0,.65,.28], [.15,.14,.15]);
  attach('cabeza', [0,.83,.36], [.22,.18,.19]);
  attach('cola', [0,.745,-.48], [.115,.14,.13]);
  for (const suffix of ['del.der','del.izq','tras.der','tras.izq']) {
    for (const [bone, child] of [['muslo','pierna'], ['pierna','pata']]) {
      const length = bones.get(`${child}.${suffix}`).position.length();
      const target = new THREE.Object3D();
      target.position.y = length / 2;
      target.scale.set(.083, length / 2 + .045, .083);
      bones.get(`${bone}.${suffix}`).add(target);
      targets.push(target);
    }
  }
  const cursor = new THREE.Vector2(), raycaster = new THREE.Raycaster();
  const ray = new THREE.Ray(), matrix = new THREE.Matrix4();
  const sphere = new THREE.Sphere(new THREE.Vector3(), 1);
  return (x, y, camera) => {
    raycaster.setFromCamera(cursor.set(2*x - 1, 1 - 2*y), camera);
    return targets.some(target => {
      target.updateWorldMatrix(true, false);
      ray.copy(raycaster.ray).applyMatrix4(matrix.copy(target.matrixWorld).invert());
      return ray.intersectsSphere(sphere);
    });
  };
}
