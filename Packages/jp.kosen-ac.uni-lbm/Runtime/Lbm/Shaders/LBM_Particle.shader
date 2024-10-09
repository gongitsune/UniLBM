﻿Shader "Unlit/LBM_Particle"
{
    Properties
    {
        size ("Size", Float) = 100
        min_velocity ("Min Velocity", Float) = 0.00001
        max_velocity ("Max Velocity", Float) = 0.25
        hue_speed ("Hue Speed", Float) = 10
        particle_width ("Particle Width", Float) = 0.1
        particle_length ("Particle Length", Float) = 0.1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
            "PreviewType"="Plane"
        }
        LOD 100

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal//ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/jp.kosen-ac.uni-lbm/ShaderLibraly/lbm_utility.hlsl"

        StructuredBuffer<lbm_particle_data> particles;

        float size;
        float min_velocity;
        float max_velocity;
        float hue_speed;
        float particle_length;
        float particle_width;
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float4 prev_and_vel : TEXCOORD1;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            v2g vert(uint id: SV_VertexID)
            {
                v2g o;
                lbm_particle_data p = particles[id];
                o.vertex = float4(p.pos_lifetime.xyz, 1);
                o.prev_and_vel = p.prev_pos_vel;
                o.uv = float2(0, 0);
                o.color = float4(hsv_2_rgb(float3(saturate(p.prev_pos_vel.w * hue_speed), 1, 1)), 1);
                return o;
            }

            [maxvertexcount(4)]
            void geom(point v2g input[1], inout TriangleStream<g2f> out_stream)
            {
                // 全ての頂点で共通の値を計算しておく
                float4 pos = input[0].vertex;
                float4 prev_pos = input[0].prev_and_vel;
                float4 col = input[0].color;

                // パーティクルの長さ調整
                float3 dir = pos.xyz - prev_pos.xyz;
                prev_pos.xyz -= dir * particle_length;

                // 速度が範囲外の場合は描画しない
                bool is_out_of_velocity = prev_pos.w <= min_velocity || prev_pos.w >= max_velocity;
                [flatten]
                if (is_out_of_velocity)
                    return;

                // 四角形になるように頂点を生成
                float4x4 billboard_matrix = UNITY_MATRIX_V;
                billboard_matrix._m03 = billboard_matrix._m13 = billboard_matrix._m23 = billboard_matrix._m33 = 0;

                g2f o;
                o.color = col;
                [unroll]
                for (uint x = 0; x < 2; x++)
                    [unroll]
                    for (uint y = 0; y < 2; y++)
                    {
                        float2 uv = float2(x, y);
                        float2 s = float2(particle_width, particle_length);
                        o.vertex = mul(float4(uv * 2 - 1, 0, 1) * s, billboard_matrix);
                        o.vertex += y <= 1 ? pos : prev_pos;

                        o.vertex = TransformObjectToHClip(o.vertex.xyz * size);

                        out_stream.Append(o);
                    }

                out_stream.RestartStrip();
            }

            float4 frag(g2f i) : SV_Target
            {
                return i.color;
            }
            ENDHLSL
        }
    }
}