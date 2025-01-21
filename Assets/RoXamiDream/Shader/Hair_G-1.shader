Shader "Jian/Girl/Hair_G-1" {
	Properties {
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("MainTex", 2D) = "white" {}
		_ShapeMap ("ShapeMap" , 2D) = "white" {}
		_Lut ("Lut" , 2D) = "white" {}

		[Header(SpecRim)]
		_SpecColor ("SpecColor" , Color) = (1,1,1,1)
		_SpecLength ( "SpecLength" , Range(0,1)) = 0.5
		_SpecHard ( "SpecHard" , Range(0,0.2)) = 0.1
		_RimOffest ("_RimWidth", Range(0, 0.1)) = 0.012
		_Threshold ("_Threshold", Range(0, 0.1)) = 0.09

		_ShadowColor ("ShadowColor" , Color) = (0.5 , 0.5 , 0.5 , 1)

		[Header(OutLine)]
		_OutlineColor ("OutLineColor" , Color) = (0,0,0,1)
		_OutlineSize ("OutLineSize" , Float) = 1
	
	}

	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float _SpecLength;
			float _SpecHard;
			float4 _SpecColor;
			float _RimOffest;
			float _Threshold;
			float4 _ShadowColor;

			float4 _OutlineColor;
			float _OutlineSize;

			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Girl_Hair"
			Tags { "LightMode"="UniversalForward" }

			Cull Off

			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
 
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
				float4 ScrPos : TEXCOORD4;
				float ClipW : TEXCOORD5;
				//float SignDir : TEXCOORD6;
				float4 color : COLOR;
			};
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_Lut);
			SAMPLER(sampler_Lut);
			TEXTURE2D(_ShapeMap);
			SAMPLER(sampler_ShapeMap);
			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
 
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.normal = TransformObjectToWorldNormal(IN.normal);
				OUT.WsPos = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.ViewDir = normalize(GetWorldSpaceViewDir(OUT.WsPos));
				OUT.ScrPos = ComputeScreenPos(OUT.positionCS);
				OUT.uv = IN.uv;
				OUT.ClipW = OUT.positionCS.w;
				//OUT.SignDir = positionInputs.normalVS.x;
				OUT.color = IN.color;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {
				
				//Varins IN
				float3 WorldNormal = normalize(IN.normal);
				float3 LightDir = normalize(_MainLightPosition);
				float3 ViewDir = normalize(IN.ViewDir);
				float3 WorldPosition = IN.WsPos;
				float4 LightColor = _MainLightColor;
				float2 ScreenPosition = IN.ScrPos.xy / IN.ScrPos.w;
				float3 NormalVS = TransformWorldToViewDir(WorldNormal, true);

				//Data
				float NdotL = (dot(WorldNormal , LightDir) + 1) * 0.5;
				float3 HalfDir = normalize(LightDir + ViewDir);
				float3 HalfDirVS = TransformWorldToViewDir(HalfDir , true);
				float2 SignDir = NormalVS.xy;
                float2 OffestSamplePos = ScreenPosition + _RimOffest / IN.ClipW * SignDir;

				//Texture
				float4 ToonColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color * LightColor;
				float4 Shape = SAMPLE_TEXTURE2D(_ShapeMap, sampler_ShapeMap, IN.uv);
				float3 Toon = SAMPLE_TEXTURE2D(_Lut, sampler_Lut, float2(0 , NdotL));
				float OffsetDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture , OffestSamplePos);
                float Depth = SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture , ScreenPosition);

				//Diffuse
				float3 ToonDiffuse = ToonColor * saturate(Toon + _ShadowColor);

				//Spec
				float Spec = smoothstep( _SpecLength , saturate(_SpecLength + _SpecHard) , (dot( HalfDirVS.xz , NormalVS.xz ) + 1) * 0.5 ) * Shape.r;
				float Linear01EyeOffectDepth = Linear01Depth( OffsetDepth , _ZBufferParams);
				float Linear01EyeDepth = Linear01Depth( Depth , _ZBufferParams);
				float DepthDiffer = Linear01EyeOffectDepth - Linear01EyeDepth;
                float Rim = step(_Threshold * 0.001 , DepthDiffer);
				Spec = saturate(Spec + Rim)* NdotL;
				float3 ToonSpec = saturate( lerp(ToonDiffuse , saturate(ToonColor + _SpecColor) , Spec));
				
 
				return float4(ToonSpec , 1);
			}
			ENDHLSL
		}

		Pass 
			{
			Name "Outline"
			Cull Front
 
			HLSLPROGRAM

			#include "RoXamiOutline.hlsl"
			
 
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
            #pragma shader_feature_local _NORMALMAP
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