#version 460
#extension GL_EXT_ray_tracing : enable
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_scalar_block_layout : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int64 : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_buffer_reference2 : require

layout(location = 0) rayPayloadInEXT vec3 hitValue;
hitAttributeEXT vec2 attribs;

// Create buffer references for positions and indices
layout(buffer_reference, std430, scalar) buffer Positions { vec3 v[]; };
layout(buffer_reference, std430, scalar) buffer Indices { uint i[]; };

// Struct containing the buffer references
struct InstanceData
{
	Positions positions;
	Indices indices;
};

// Actual buffer containing the Instance data
layout(binding = 3, set = 0) buffer InstanceDataBuffer
{
	InstanceData data[];
} instanceDataBuffer;

// This doesn't work
vec3 unpackVertexData(uint index, inout Positions positions)
{
	return positions.v[index];
}

// This does work
vec3 unpackVertexData(uint index, inout InstanceData instanceData)
{
	return instanceData.positions.v[index];
}

// in data/shaders/glsl/raytracingbasic
// glslangValidator.exe -V --target-env spirv1.4 closesthit.rchit -o closesthit.rchit.spv
void main()
{
  const vec3 barycentricCoords = vec3(1.0f - attribs.x - attribs.y, attribs.x, attribs.y);
  
  InstanceData instanceData = instanceDataBuffer.data[gl_InstanceCustomIndexEXT];

  // Crash in vkCreateShaderModule on AMD
  vec3 p0 = unpackVertexData(gl_PrimitiveID * 3 + 0, instanceData.positions);
  vec3 p1 = unpackVertexData(gl_PrimitiveID * 3 + 1, instanceData.positions);
  vec3 p2 = unpackVertexData(gl_PrimitiveID * 3 + 2, instanceData.positions);

  // Works fine
  /*
  vec3 p0 = unpackVertexData(gl_PrimitiveID * 3 + 0, instanceData);
  vec3 p1 = unpackVertexData(gl_PrimitiveID * 3 + 1, instanceData);
  vec3 p2 = unpackVertexData(gl_PrimitiveID * 3 + 2, instanceData);
  */

  vec3 position = p0 * barycentricCoords.x + p1 * barycentricCoords.y + p2 * barycentricCoords.z;
  hitValue = position;
}
