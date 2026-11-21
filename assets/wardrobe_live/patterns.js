// Patterns use rest coordinates so they follow the fitted mesh while it moves.
export const patternCodes = { zebra: 1, redwhite: 2, dalmatian: 3, tiger: 4, greenwhite: 5, dots: 6, elf: 7 };
export const patternGLSL = `
vec3 poodlePattern(vec3 p, float code, vec3 base) {
  float stripe = step(0.0, sin(p.y*57.0 + p.z*31.0 + 1.8*sin(p.x*39.0)));
  if (code < 0.5) return base;
  if (code < 1.5) return mix(vec3(.035,.039,.045), vec3(.94,.91,.86), stripe);
  if (code < 2.5) return mix(vec3(.72,.025,.045), vec3(.96,.93,.87), step(0.0,sin(p.y*52.0)));
  if (code < 3.5) {
    vec3 cell = floor(p*24.0);
    vec3 center = fract(sin(vec3(dot(cell,vec3(12.3,57.1,8.7)),dot(cell,vec3(7.1,31.9,17.3)),dot(cell,vec3(41.1,7.7,13.1))))*43758.5453)*.45+.275;
    float spot = 1.0-smoothstep(.23,.29,length(fract(p*24.0)-center));
    return mix(vec3(.94,.91,.86),vec3(.025,.028,.033),spot);
  }
  if (code < 4.5) return mix(vec3(.04,.025,.016),vec3(.93,.37,.045),stripe);
  if (code < 5.5) return mix(vec3(.025,.39,.17),vec3(.96,.93,.87),step(0.0,sin(p.y*52.0)));
  if (code < 6.5) {
    vec3 surfaceNormal = abs(cross(dFdx(p), dFdy(p)));
    vec2 surface = surfaceNormal.z >= surfaceNormal.x ? p.xy : p.zy;
    vec2 cell = floor(surface*24.0);
    float choice = mod(cell.x+cell.y*3.0,4.0);
    vec3 dotColor = choice < .5 ? vec3(.8,.025,.055) : choice < 1.5 ? vec3(.96,.69,.025) : choice < 2.5 ? vec3(.025,.57,.19) : vec3(.025,.25,.85);
    float dotMask = 1.0-smoothstep(.28,.32,length(fract(surface*24.0)-.5));
    return mix(vec3(.94,.91,.86),dotColor,dotMask);
  }
  // Elf knit: coordinates belong to the fitted rest mesh, so stripes, belt
  // and embroidered buttons follow the same skinning as the wool.
  vec3 green = vec3(.012,.27,.11), red = vec3(.72,.018,.033);
  vec3 cream = vec3(.96,.93,.83), gold = vec3(.95,.59,.065);
  vec3 black = vec3(.014,.019,.018);
  float t = (.34-p.z)/.80;
  float around = atan(p.x, (p.y-.49)*.95);
  float zigzag = 1.0-abs(fract(around*1.9+.5)*2.0-1.0);
  vec3 wool = mix(red, green, smoothstep(.20+zigzag*.105, .208+zigzag*.105, t));
  // Sleeves and rear hem have alternating green and ivory knitted bands.
  if (p.y < .37 || t > .84) {
    float band = p.y < .37 ? p.y*55.0 : t*47.0;
    wool = mix(green,cream,smoothstep(.46,.51,fract(band)));
  }
  if (p.y > .40) {
    float belt = 1.0-smoothstep(.045,.049,abs(t-.74));
    wool = mix(wool,black,belt);
    // Gold rectangular buckle centred on the back of the sweater.
    vec2 buckle = vec2(around*.075, (t-.74)*.8);
    float outer = max(abs(buckle.x)/.047,abs(buckle.y)/.052);
    float inner = max(abs(buckle.x)/.034,abs(buckle.y)/.038);
    float rim = (1.0-smoothstep(.96,1.02,outer))*smoothstep(.96,1.02,inner);
    wool = mix(wool,gold,rim);
    // Two embroidered toggles on each flank and on the back.
    float panel = mod(around+1.10,2.20)-1.10;
    for (int row=0;row<2;row++) {
      float height = .43+float(row)*.14;
      vec2 button = vec2(panel*.095,(t-height)*.8);
      float cord = (1.0-smoothstep(.005,.008,abs(button.y))) * (1.0-smoothstep(.052,.056,abs(button.x)));
      wool = mix(wool,black,cord);
      vec2 end = vec2(abs(button.x)-.055,button.y);
      float disk = 1.0-smoothstep(.017,.020,length(end));
      wool = mix(wool,gold,disk);
      float stitch = (1.0-smoothstep(.003,.005,min(abs(end.x),abs(end.y)))) * (1.0-smoothstep(.010,.012,length(end)));
      wool = mix(wool,red,stitch);
    }
  }
  return wool;
}
`;

export function patchFabric(material) {
  const pattern = {value: 0};
  const previous = material.onBeforeCompile;
  const cacheKey = material.customProgramCacheKey();
  material.onBeforeCompile = shader => {
    previous.call(material, shader);
    shader.uniforms.poodleFabricPattern = pattern;
    shader.vertexShader = 'varying vec3 poodleFabricPosition;\n' + shader.vertexShader.replace('#include <begin_vertex>', '#include <begin_vertex>\npoodleFabricPosition = position;');
    shader.fragmentShader = 'varying vec3 poodleFabricPosition;\nuniform float poodleFabricPattern;\n' + patternGLSL + shader.fragmentShader.replace('#include <alphamap_fragment>', `
      if (poodleFabricPattern > .5) {
        float lightness = clamp(dot(diffuseColor.rgb, vec3(.24,.65,.11)) * 2.8, .38, 1.1);
        diffuseColor.rgb = poodlePattern(poodleFabricPosition, poodleFabricPattern, vec3(1.0)) * lightness;
      }
      #include <alphamap_fragment>
    `);
  };
  material.customProgramCacheKey = () => cacheKey + '-patterns-v2';
  return pattern;
}
