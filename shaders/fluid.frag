#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms (set from Dart via FragmentShader.setFloat)
// Index 0: u_time
// Index 1-2: u_resolution (x, y)
// Index 3-4: u_mouse (x, y)
// Index 5: u_isLightMode
uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_isLightMode;

out vec4 fragColor;

// ===== Simplex Noise (port from original WebGL shader) =====
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }

float snoise(vec2 v) {
  const vec4 C = vec4(
    0.211324865405187,
    0.366025403784439,
    -0.577350269189626,
    0.024390243902439
  );
  vec2 i = floor(v + dot(v, C.yy));
  vec2 x0 = v - i + dot(i, C.xx);
  vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod289(i);
  vec3 p = permute(
    permute(i.y + vec3(0.0, i1.y, 1.0)) +
    i.x + vec3(0.0, i1.x, 1.0)
  );
  vec3 m = max(
    0.5 - vec3(
      dot(x0, x0),
      dot(x12.xy, x12.xy),
      dot(x12.zw, x12.zw)
    ),
    0.0
  );
  m = m * m;
  m = m * m;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
  vec3 g;
  g.x = a0.x * x0.x + h.x * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// Second octave of noise for richer distortion
float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    v += a * snoise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

void main() {
  // Use FlutterFragCoord for pixel coordinates
  vec2 uv = FlutterFragCoord().xy / u_resolution.xy;
  vec2 st = uv - 0.5;
  st.x *= u_resolution.x / u_resolution.y;

  // Mouse offset for interactivity
  vec2 mouseOffset = (u_mouse - 0.5) * 0.05;
  st += mouseOffset;

  // ===== Domain Warping (the key to liquid effect) =====
  // First warp: large-scale noise distortion
  float n1 = snoise(st * 1.2 + u_time * 0.18);
  vec2 warpedUV = uv + vec2(n1 * 0.15);

  // Second warp: finer detail for more organic flow
  float n2 = snoise(st * 2.5 + u_time * 0.25 + n1 * 0.5);
  warpedUV += vec2(n2 * 0.06);

  // ===== Color palette (exact match from original) =====
  vec3 colOrange = vec3(0.68, 0.25, 0.06);
  vec3 colYellow = vec3(0.68, 0.52, 0.12);
  vec3 colPurple = vec3(0.28, 0.07, 0.52);
  vec3 colPink = vec3(0.66, 0.10, 0.34);

  // ===== Blob positions with organic movement =====
  vec2 pYellow  = vec2(0.2 + sin(u_time * 0.32) * 0.12, 0.78 + cos(u_time * 0.26) * 0.08);
  vec2 pOrange  = vec2(0.8 + cos(u_time * 0.38) * 0.12, 0.86 + sin(u_time * 0.30) * 0.08);
  vec2 pPink    = vec2(0.7 + sin(u_time * 0.20) * 0.16, 0.64 + cos(u_time * 0.44) * 0.09);
  vec2 pPurple  = vec2(0.3 + cos(u_time * 0.26) * 0.16, 0.70 + sin(u_time * 0.34) * 0.09);

  // ===== Smoothstep color weights (additive blending in shader) =====
  float wYellow = 1.0 - smoothstep(0.0, 0.68, distance(warpedUV, pYellow));
  float wOrange = 1.0 - smoothstep(0.0, 0.72, distance(warpedUV, pOrange));
  float wPink   = 1.0 - smoothstep(0.0, 0.58, distance(warpedUV, pPink));
  float wPurple = 1.0 - smoothstep(0.0, 0.64, distance(warpedUV, pPurple));

  vec3 color = colYellow * (wYellow * 0.72)
             + colOrange * (wOrange * 0.70)
             + colPink * (wPink * 0.68)
             + colPurple * (wPurple * 0.82);
  color = color / (vec3(1.0) + color * 0.45);

  // ===== Vertical breathing fade =====
  float breath = 0.5 + 0.5 * sin(u_time * 0.55);
  float lowerReveal = smoothstep(
    0.16 + breath * 0.03,
    0.62 + breath * 0.03,
    uv.y
  );
  float bottomFade = 1.0 - smoothstep(0.96, 1.08, uv.y);
  float vFade = lowerReveal * bottomFade;

  // ===== Background mix =====
  vec3 bg = mix(vec3(0.059), vec3(0.94, 0.95, 0.96), u_isLightMode);
  if (u_isLightMode > 0.5) {
    color = color * 0.5 + 0.3;
    color = mix(bg, color, vFade * 0.6);
  } else {
    color = mix(bg, color, vFade);
  }

  // ===== Film grain =====
  color += (fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.015;

  fragColor = vec4(color, 1.0);
}
