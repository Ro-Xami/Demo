Shader "RoXami/CustomRenderFeature/SSAO" {
	Properties {

	}
	SubShader {
		Tags { "LightMode"="SRPDefaultUnlit"}

			HLSLINCLUDE
				
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
				CBUFFER_START(UnityPerMaterial)
					float _sampleCount;
					float _radius;
					float _RangeCheck;
					float _AOInt;
				CBUFFER_END

			ENDHLSL
		Pass {
			
 
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment frag
			
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			
		float3 GetRandomVecHalf(float2 p)
		{
			float3 vec = float3(0 ,0 ,0);
			vec.x = Hash(p) * 2 - 1;
			vec.y = Hash(p * p) * 2 - 1;
			vec.z = saturate(Hash(p * p * p) + 0.2);
			return normalize(vec);
		}


		float Hash(float2 p)
		{
			float hush = dot(p, float2(12.9898, 78.233));
			hush = sin(hush) * 43758.5453;
			return frac(hush);
		}

		// 随机向量
		float3 GetRandomVec(float2 p)
		{
			float3 vec = float3( 0 , 0 , 0 );
			vec.x = Hash(p) * 2 - 1;
			vec.y = Hash(p * p) * 2 - 1;
			vec.z = Hash(p * p * p) * 2 - 1;
			return normalize(vec);
		}
 
			half4 frag(Varyings IN) : SV_Target {

				float2 uv = IN.texcoord.xy;

				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
#if UNITY_REVERSED_Z
				real depth = SampleSceneDepth(uv);
#else
				// Adjust Z to match NDC for OpenGL ([-1, 1])
				real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
#endif
				//depth = LinearEyeDepth(depth,_ZBufferParams);

//-----------------------------------------------TBN-------------------------------------------------------
				float3 wsPosition = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
				float3 wsNormal = SampleSceneNormals(uv);
				float3 wsTangent = GetRandomVec(uv);//生成随机噪点
				float3 wsBiTangent = cross(wsNormal , wsTangent);
				wsTangent = cross(wsNormal , wsBiTangent);
				float3x3 TBN = float3x3(wsTangent , wsBiTangent , wsNormal);

//-------------------------------------------forLoop---------------------------------------------------------
				float ao = 0;
				float sampleCount = _sampleCount;
				float3 halfVec = float3(0,0,0);
				float scale = 0;
				float weight = 0;
				float4 offPosW = float4(0,0,0,0);
				float4 offPosC = float4(0,0,0,0);
				float2 offPosScr = float2(0,0);
				float sampleDepth = 0;
				float rangeCheck = 0;
				float selfCheck = 0;

				[loop]
				for(int j = 0 ; j < sampleCount ; j++)
				{
					//随机向量
					halfVec = GetRandomVecHalf(j * uv);
					scale = j / sampleCount;
					scale = lerp(0.01 , 1 , pow(scale , 2));
					//扩展半径
					halfVec *= scale * _radius;
					weight = smoothstep(0 , 0.02 , halfVec).x;
					halfVec = mul(halfVec , TBN);
					// 世界坐标转换成裁剪空间
					offPosC = mul(UNITY_MATRIX_VP, float4(halfVec, 0) + float4(wsPosition , 0));
					offPosScr = offPosC.xy / offPosC.w;
					offPosScr = offPosScr * 0.5 + 0.5;
					// 采样深度
					sampleDepth = SampleSceneDepth(offPosScr);
					//sampleDepth = LinearEyeDepth(sampleDepth,_ZBufferParams);
					// 采样AO
					rangeCheck = smoothstep(0, 1.0, _radius / abs(offPosC.w - sampleDepth) * _RangeCheck * 0.1);
					selfCheck = (sampleDepth < depth - 0.08) ?  1 : 0;
					ao += (sampleDepth < offPosC.w) ?  1 * rangeCheck * selfCheck * _AOInt * weight : 0;
				}
				ao = 1 - saturate((ao / sampleCount));
				return half4(sampleDepth.xxx,1);

			}
			ENDHLSL
		}
	}
}