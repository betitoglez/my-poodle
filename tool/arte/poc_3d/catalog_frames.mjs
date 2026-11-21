const frames = {
  body: {y:.94, size:.78, yaw:23*.013},
  head: {y:1.96, size:1.71, yaw:9*.013},
  neck: {y:1.68, size:1.85, yaw:7*.013},
  paws: {y:.87, size:2.04, yaw:29*.013},
  profile: {y:.94, size:.78, yaw:Math.PI/2},
};

export function frameForItem(id, slot) {
  const zone = id.startsWith('cut.') ? id.split('.')[1] : null;
  if (zone === 'back' || zone === 'tail') return frames.profile;
  if (zone === 'head' || slot === 'head' || slot === 'eyes') return frames.head;
  if (zone === 'legs' || slot === 'paws') return frames.paws;
  if (slot === 'neck' || slot === 'collar') return frames.neck;
  return frames.body;
}
