﻿#define FLUID_TYPE 0
#define BOUNDARY_TYPE 1
#define OUTFLOW_BOUNDARY_TYPE 2

uint get_index(uint3 index, uint3 size)
{
    return index.x + index.y * size.x + index.z * size.x * size.y;
}

float3 hsv_2_rgb(float3 hsv)
{
    static const float4 k = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(hsv.xxx + k.xyz) * 6.0 - k.www);
    return hsv.z * lerp(k.xxx, clamp(p - k.xxx, 0.0, 1.0), hsv.y);
}

float3 random3(float3 s)
{
    return frac(
        sin(float3(
            dot(s, float3(127.1, 311.7, 524.3)),
            dot(s, float3(513.4, 124.1, 153.1)),
            dot(s, float3(269.5, 183.3, 536.1))
        )) * 43758.5453123
    );
}

float length2(in float3 v)
{
    return dot(v, v);
}
