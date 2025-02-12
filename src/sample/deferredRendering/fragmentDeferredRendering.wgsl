[[group(0), binding(0)]] var mySampler: sampler;
[[group(0), binding(1)]] var gBufferPosition: texture_2d<f32>;
[[group(0), binding(2)]] var gBufferNormal: texture_2d<f32>;
[[group(0), binding(3)]] var gBufferAlbedo: texture_2d<f32>;

struct LightData {
  position : vec4<f32>;
  color : vec3<f32>;
  radius : f32;
};
[[block]] struct LightsBuffer {
  lights: array<LightData>;
};
[[group(1), binding(0)]] var<storage, read> lightsBuffer: LightsBuffer;

[[block]] struct Config {
  numLights : u32;
};
[[group(1), binding(1)]] var<uniform> config: Config;

[[block]] struct CanvasConstants {
  size: vec2<f32>;
};
[[group(2), binding(0)]] var<uniform> canvas : CanvasConstants;

[[stage(fragment)]]
fn main([[builtin(position)]] coord : vec4<f32>)
     -> [[location(0)]] vec4<f32> {
  var result = vec3<f32>(0.0, 0.0, 0.0);
  var c = coord.xy / canvas.size;

  var position = textureSample(
    gBufferPosition,
    mySampler,
    c
  ).xyz;

  if (position.z > 10000.0) {
    discard;
  }

  var normal = textureSample(
    gBufferNormal,
    mySampler,
    c
  ).xyz;

  var albedo = textureSample(
    gBufferAlbedo,
    mySampler,
    c
  ).rgb;

  for (var i : u32 = 0u; i < config.numLights; i = i + 1u) {
    var L = lightsBuffer.lights[i].position.xyz - position;
    var distance = length(L);
    if (distance > lightsBuffer.lights[i].radius) {
        continue;
    }
    var lambert = max(dot(normal, normalize(L)), 0.0);
    result = result + vec3<f32>(
      lambert * pow(1.0 - distance / lightsBuffer.lights[i].radius, 2.0) * lightsBuffer.lights[i].color * albedo);
  }

  // some manual ambient
  result = result + vec3<f32>(0.2, 0.2, 0.2);

  return vec4<f32>(result, 1.0);
}
