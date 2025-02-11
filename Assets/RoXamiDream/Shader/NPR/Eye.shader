Shader "RoXami/Girl/Eye"{
Properties {
		_BaseColor ("Color", Color) = (1, 1, 1, 1)
		[NoScaleOffest]_MainTex ("MainTex", 2D) = "white" {}
		[NoScaleOffest]_EyeMask ("EyeMask", 2D) = "white" {}
		[NoScaleOffest]_NormalMap ("NormalMap", 2D) = "Bump" {}
		_BlendNormal("BlendNormal" , Range(0,1)) = 1
		[NoScaleOffest]_MatCap ("MatCap", 2D) = "white" {}
		_MatCapIntensity ("_MatCapIntensity" ,Range(0,1)) = 1

		_ParallaxScale("ParallaxScale", Range(0,1)) = 0.1
		_Clip("Clip" , Range(0,1)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
			CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			float _ParallaxScale;
			float _BlendNormal;
			float _MatCapIntensity;
			float _Clip;
			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Eye_L"
			Tags { "LightMode"="UniversalForward" }

			ZTest LEqual
 
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
 
			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 WsPos : TEXCOORD2;
				float3 ViewDir : TEXCOORD3;
				float4 color : COLOR;
			};
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_EyeMask);
			SAMPLER(sampler_EyeMask);
			TEXTURE2D(_MatCap);
			SAMPLER(sampler_MatCap);
			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
 
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.normal = TransformObjectToWorldNormal(IN.normal);
				OUT.WsPos = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.ViewDir = normalize(GetWorldSpaceViewDir(OUT.WsPos));
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {

				//Varings in
				float3 WorldNormal = normalize(IN.normal);
				float3 LightDir = normalize(_MainLightPosition);
				float3 ViewDir = normalize(IN.ViewDir);
				float3 LocalViewDir = TransformWorldToObject(ViewDir);
				float4 LightColor = _MainLightColor;
				float2 OffestUV = IN.uv - (_ParallaxScale * LocalViewDir.xy);
				float3 NormalVS = normalize(TransformWorldToViewDir(WorldNormal, true));

				//Parallax
				float4 MaskMap = SAMPLE_TEXTURE2D(_EyeMask, sampler_EyeMask, IN.uv);
				OffestUV = lerp(IN.uv , OffestUV , MaskMap.b);

				//Texture
				float4 BaseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, OffestUV) * _BaseColor * _MainLightColor;
				float3 NormalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
				NormalVS = lerp(NormalVS , NormalMap , _BlendNormal);
				float4 MatCap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, NormalVS.xy * 0.5 + 0.5);
				BaseMap = saturate(BaseMap + MatCap * _MatCapIntensity);
 
				return BaseMap;
				//return float4(0,1,0,0);
			}
			ENDHLSL
		}

		Pass {
			Name "Eye_G"
			Tags { "LightMode"="SRPDefaultUnlit" }

			ZTest GEqual
 
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
 
			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 WsPos : TEXCOORD2;
				float3 ViewDir : TEXCOORD3;
				float4 color : COLOR;
			};
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_EyeMask);
			SAMPLER(sampler_EyeMask);
			TEXTURE2D(_MatCap);
			SAMPLER(sampler_MatCap);
			TEXTURE2D(_NormalMap);
			SAMPLER(sampler_NormalMap);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
 
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.normal = TransformObjectToWorldNormal(IN.normal);
				OUT.WsPos = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.ViewDir = normalize(GetWorldSpaceViewDir(OUT.WsPos));
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {

				//Varings in
				float3 WorldNormal = normalize(IN.normal);
				float3 LightDir = normalize(_MainLightPosition);
				float3 ViewDir = normalize(IN.ViewDir);
				float3 LocalViewDir = TransformWorldToObject(ViewDir);
				float4 LightColor = _MainLightColor;
				float2 OffestUV = IN.uv - (_ParallaxScale * LocalViewDir.xy);
				float3 NormalVS = normalize(TransformWorldToViewDir(WorldNormal, true));

				//Parallax
				float4 MaskMap = SAMPLE_TEXTURE2D(_EyeMask, sampler_EyeMask, IN.uv);
				OffestUV = lerp(IN.uv , OffestUV , MaskMap.b);

				//Texture
				float4 BaseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, OffestUV) * _BaseColor * _MainLightColor;
				float3 NormalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
				NormalVS = lerp(NormalVS , NormalMap , _BlendNormal);
				float4 MatCap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, NormalVS.xy * 0.5 + 0.5);
				BaseMap = saturate(BaseMap + MatCap * _MatCapIntensity);

				float GMask = SAMPLE_TEXTURE2D(_EyeMask, sampler_EyeMask, OffestUV).g;
				clip(GMask - _Clip);
 
				return BaseMap;
				//return float4(0,1,0,0);
			}
			ENDHLSL
		}

		Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NormalMap
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
	}
}