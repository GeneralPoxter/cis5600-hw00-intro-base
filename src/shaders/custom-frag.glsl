#version 300 es

precision highp float;

uniform vec4 u_Color;
uniform vec4 u_ColorNoise;

in vec4 fs_Pos;

out vec4 out_Col;

//	Classic Perlin 3D Noise 
//	by Stefan Gustavson (https://github.com/stegu/webgl-noise)
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float perlin3D(vec3 P){
  vec3 Pi0 = floor(P); // Integer part for indexing
  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
  Pi0 = mod(Pi0, 289.0);
  Pi1 = mod(Pi1, 289.0);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 / 7.0;
  vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 / 7.0;
  vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
  return 2.2 * n_xyz;
}
// End of borrowed code

// Musgrave FBM noise from @deanthecoder
// https://www.shadertoy.com/view/mdy3R1
float sum2(vec2 v) { return dot(v, vec2(1)); }

float n31(vec3 p) {
        const vec3 s = vec3(7, 157, 113);
        vec3 ip = floor(p);
        p = fract(p);
        p = p * p * (3. - 2. * p);
        vec4 h = vec4(0, s.yz, sum2(s.yz)) + dot(ip, s);
        h = mix(fract(sin(h) * 43758.545), fract(sin(h + s.x) * 43758.545), p.x);
        h.xy = mix(h.xz, h.yw, p.y);
        return mix(h.x, h.y, p.z);
}

float fbm(vec3 p, int octaves, float roughness) {
        float sum = 0.,
              amp = 1.,
              tot = 0.;
        roughness = clamp(roughness, 0., 1.);
        for (int i = 0; i < octaves; i++) {
                sum += amp * n31(p);
                tot += amp;
                amp *= roughness;
                p *= 2.;
        }
        return sum / tot;
}

float musgraveFbm(vec3 p, int octaves, float dimension, float lacunarity) {
        float sum = 0.,
              amp = 1.,
              m = pow(lacunarity, -dimension);
        for (int i = 0; i < octaves; i++) {
                float n = n31(p) * 2. - 1.;
                sum += n * amp;
                amp *= m;
                p *= lacunarity;
        }
        return sum;
}
// End of borrowed code

vec3 waveFbm(vec3 p) {
    vec3 n = p * vec3(20, 30, 10);
    n += .4 * fbm(p * 3., 3, 3.);
    return sin(n) * .5 + .5;
}

void main()
{
    float noisePerlin = (perlin3D(5. * fs_Pos.xyz) + 1.) / 2.;
    float noiseFBM = mix(0.8, 1.0, musgraveFbm(waveFbm(fs_Pos.xyz * vec3(.05, .15, .15)) * vec3(100, 6, 20), 8, 0., 3.));
    out_Col = mix(u_Color, u_ColorNoise, smoothstep(0.6, 0.9, noisePerlin));
    out_Col.rgb *= vec3(noiseFBM);
}
