// Patterns use rest coordinates so they follow the fitted mesh while it moves.
export const patternCodes = { zebra: 1, redwhite: 2, dalmatian: 3, tiger: 4, greenwhite: 5, dots: 6 };
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
  vec3 surfaceNormal = abs(cross(dFdx(p), dFdy(p)));
  vec2 surface = surfaceNormal.z >= surfaceNormal.x ? p.xy : p.zy;
  vec2 cell = floor(surface*24.0);
  float choice = mod(cell.x+cell.y*3.0,4.0);
  vec3 dotColor = choice < .5 ? vec3(.8,.025,.055) : choice < 1.5 ? vec3(.96,.69,.025) : choice < 2.5 ? vec3(.025,.57,.19) : vec3(.025,.25,.85);
  float dotMask = 1.0-smoothstep(.28,.32,length(fract(surface*24.0)-.5));
  return mix(vec3(.94,.91,.86),dotColor,dotMask);
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
  material.customProgramCacheKey = () => cacheKey + '-patterns-v1';
  return pattern;
}
