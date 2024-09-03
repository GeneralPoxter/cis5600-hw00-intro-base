import { vec3, vec4 } from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import Drawable from './rendering/gl/Drawable';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import { setGL } from './globals';
import ShaderProgram, { Shader } from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Cube': loadCube,
  'Load Icosphere': loadIcosphere,
  'Load Square': loadSquare,
};

const palette = {
  color1: [0, 64, 128],
  alpha1: 1.0,
  color2: [255, 192, 128],
  alpha2: 1.0,
};

let activeDrawable: Drawable;
let prevTesselations: number = 5;
let time: number = 0;

function loadCube() {
  activeDrawable = new Cube(vec3.fromValues(0, 0, 0), 1);
  activeDrawable.create();
}

function loadIcosphere() {
  activeDrawable = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  activeDrawable.create();
}

function loadSquare() {
  activeDrawable = new Square(vec3.fromValues(0, 0, 0));
  activeDrawable.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.addColor(palette, 'color1');
  gui.add(palette, 'alpha1', 0, 1).step(.01);
  gui.addColor(palette, 'color2');
  gui.add(palette, 'alpha2', 0, 1).step(.01);
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Cube');
  gui.add(controls, 'Load Icosphere');
  gui.add(controls, 'Load Square');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement>document.getElementById('canvas');
  const gl = <WebGL2RenderingContext>canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadCube();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);
  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const custom = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);

  const shader = custom;

  const vec4FromColor = ((color: number[], alpha: number) => {
    return vec4.fromValues(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0, alpha);
  });

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if (activeDrawable instanceof Icosphere && controls.tesselations != prevTesselations) {
      prevTesselations = controls.tesselations;
      activeDrawable = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      activeDrawable.create();
    }

    shader.setGeometryColor(vec4FromColor(palette.color1, palette.alpha1));
    shader.setNoiseColor(vec4FromColor(palette.color2, palette.alpha2));
    shader.setTime(time);

    renderer.render(
      camera, shader,
      [activeDrawable]
    );
    stats.end();

    time += 1 / 60;

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function () {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
