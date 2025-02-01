Shader "RoXami/CustomRenderFeature/VolumetricLighting" {
	Properties {
	_VolumetricColor("VolumetricColor" , Color) = (1,1,1,1)
	_MaxDistance("MaxDistance" , Float) = 1000
	_StepSize("StepSize" , Range(0 , 0.1)) = 0.01
	_MaxStepSize("MaxStepSize" , Float) = 200
	_LightIntensity("LightIntensity" , Range(0 , 0.01)) = 0.001
	_LightPower("Power" , Float) = 1
    _BlurInt("BlurInt" , Float) = 1

	_FinalTex("FinalTex" , 2D) = "white" {}
	}
	SubShader {
            Tags { "LightMode"="SRPDefaultUnlit"}
		Pass {
			
 
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT

			CBUFFER_START(UnityPerMaterial)

				float _MaxDistance;
				float _StepSize;
				float _MaxStepSize;
				float _LightIntensity;
				float _LightPower;
				//float4 _VolumetricColor;

			CBUFFER_END

			float4 GetTheWorldPos(float2 ScreenUV, float Depth)
            {

                float3 ScreenPos = float3(ScreenUV, Depth);                                  // 获取屏幕空间位置
                float4 normalScreenPos = float4(ScreenPos * 2.0 - 1.0, 1.0);                 // 映射到屏幕中心点
                float4 ndcPos = mul(unity_CameraInvProjection, normalScreenPos);             // 计算到ndc空间下的位置
                ndcPos = float4(ndcPos.xyz / ndcPos.w, 1.0);

                float4 sencePos = mul(unity_CameraToWorld, ndcPos * float4(1,1,-1,1));      // 反推世界空间位置
                sencePos = float4(sencePos.xyz, 1.0);
                return sencePos;
            }

			 float GetShadow(float3 posWorld)
            {
                float4 shadowCoord = TransformWorldToShadowCoord(posWorld);
                float shadow = MainLightRealtimeShadow(shadowCoord);
                return shadow;
            }
 
			half4 frag(Varyings IN) : SV_Target {

				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
#if UNITY_REVERSED_Z
				real Depth = SampleSceneDepth(IN.texcoord.xy);
#else
				// Adjust Z to match NDC for OpenGL ([-1, 1])
				real Depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(IN.texcoord.xy));
#endif

				float3 CameraWS = _WorldSpaceCameraPos.xyz;                    // 相机在世界空间中的位置
				float3 WS = GetTheWorldPos(IN.texcoord, 1 - Depth).xyz;         // 屏幕纹理坐标和深度值重构出当前像素在世界空间中的位置
				float3 RayMarchDirection = normalize(WS - CameraWS);
				float3 RayMarchCurrentWS = CameraWS;
				float RayMarchMaxLength = min(length(WS - CameraWS), _MaxDistance);
				float RayMarchStepSize = _StepSize;
				float TotalInt = 0;
				float CurrentStep = 0;
				[loop]
				for(int j = 0 ; j < _MaxStepSize ; j++)
				{
					CurrentStep += RayMarchStepSize;
					if(CurrentStep > RayMarchMaxLength) break;

					RayMarchCurrentWS += CurrentStep * RayMarchDirection;
					TotalInt += GetShadow(RayMarchCurrentWS) * _LightIntensity;
				}

				TotalInt = pow(saturate(TotalInt) , _LightPower);
 
				return TotalInt;
			}
			ENDHLSL
		}

		 //高斯模糊
        Pass
        {

            HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            CBUFFER_START(UnityPerMaterial)

				float _BlurInt;

			CBUFFER_END

			TEXTURE2D(_VolumetricTex);
			SAMPLER(sampler_VolumetricTex);

            half4 frag (Varyings IN) : SV_Target
            {

                half blurrange = _BlurInt / 300;
				half col = 0;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(0.0, 0.0)).r * 0.147716f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(blurrange, 0.0)).r * 0.118318f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(0.0, -blurrange)).r * 0.118318f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(0.0, blurrange)).r * 0.118318f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(-blurrange, 0.0)).r * 0.118318f;

                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(blurrange, blurrange)).r * 0.0947416f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(-blurrange, -blurrange)).r * 0.0947416f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(blurrange, -blurrange)).r * 0.0947416f;
                col += SAMPLE_TEXTURE2D(_VolumetricTex, sampler_VolumetricTex, IN.texcoord + float2(-blurrange, blurrange)).r * 0.0947416f;

                return col;

            }

            ENDHLSL
        }

		Pass
        {

            HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

			CBUFFER_START(UnityPerMaterial)

				half3 _VolumetricColor;

			CBUFFER_END

			TEXTURE2D(_BlurTex);
			SAMPLER(sampler_BlurTex);

            float4 frag (Varyings IN) : SV_Target
            {
                
				half3 Volumetric = SAMPLE_TEXTURE2D(_BlurTex, sampler_BlurTex, IN.texcoord).r * _VolumetricColor;
				float4 Col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, IN.texcoord);
				Col += float4(Volumetric , 0);
                return Col;

            }

            ENDHLSL
        }

	}
}