import test from 'node:test';
import assert from 'node:assert/strict';
import {frameForItem} from './catalog_frames.mjs';

test('back and tail thumbnails use a true lateral camera',()=>{
  for(const style of ['natural','teddy','pom','puppy','show','modern','standard']) {
    for(const zone of ['back','tail']) assert.equal(frameForItem(`cut.${zone}.${style}`,'hair').yaw,Math.PI/2);
  }
  assert.notEqual(frameForItem('cut.head.teddy','hair').yaw,Math.PI/2);
  assert.notEqual(frameForItem('coat.silver','coat').yaw,Math.PI/2);
});
