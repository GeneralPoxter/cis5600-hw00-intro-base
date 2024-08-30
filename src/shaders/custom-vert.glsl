#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform float u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;

out vec4 fs_Pos;

float hash( vec3 p ) {
    return fract(sin((dot(p, vec3(127.1,
                                  311.7,
                                  191.999)))) *
                 43758.5453);
}

// 3D value noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise3D(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);

    vec3 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(mix( hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), u.x),
                   mix( hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), u.x), u.y),
               mix(mix( hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), u.x),
                   mix( hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), u.x), u.y), u.z);
}

void main()
{
    float n = 3. * noise3D(3. * vs_Pos.xyz);
    vec3 pos = vs_Pos.xyz * vec3(
        mix(0.8, 1.4, smoothstep(-0.8, 0.8, sin(2.8 * u_Time + n))),
        mix(0.8, 1.4, smoothstep(-0.8, 0.8, sin(3.0 * u_Time + n))),
        mix(0.8, 1.4, smoothstep(-0.8, 0.8, sin(3.2 * u_Time + n)))
    );
    fs_Pos = vec4(pos, 1);
    gl_Position = u_ViewProj * u_Model * fs_Pos;
}
