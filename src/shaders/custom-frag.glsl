#version 300 es

#define M_PI 3.14159265358979323846

precision highp float;

uniform vec4 u_Color; 
uniform float u_Time;

in vec4 fs_Pos;

out vec4 out_Col;

// Code from: https://www.shadertoy.com/view/mdy3R1
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
    vec3 t = 4. * vec3(sin(u_Time / 15.), sin(u_Time / 25.), sin(u_Time / 10.));
    vec3 pos = (fs_Pos.xyz + t) * vec3(.05, .15, .15);
    float noise = mix(0.8, 1.0, musgraveFbm(waveFbm(pos) * vec3(100, 6, 20), 8, 0., 3.));
    out_Col = u_Color * vec4(vec3(noise), 1);
}
