#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform float u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;

out vec4 fs_Pos;

float random1( vec3 p ) {
    return fract(sin((dot(p, vec3(127.1,
                                  311.7,
                                  191.999)))) *
                 43758.5453);
}

void main()
{
    vec3 pos = vs_Pos.xyz * vec3(
        mix(0.9, 1.1, sin(u_Time * 2.5 + 3. * random1(vs_Pos.xyz))),
        mix(0.9, 1.1, sin(u_Time * 3.0 + 3. * random1(vs_Pos.xyz))),
        mix(0.9, 1.1, sin(u_Time * 3.5 + 3. * random1(vs_Pos.xyz)))
    );
    fs_Pos = vec4(pos, 1);
    gl_Position = u_ViewProj * u_Model * fs_Pos;
}
