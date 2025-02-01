Shader "RoXami/Girl/Brow"{
Properties {
		_Color ("Color", Color) = (1, 1, 1, 1)
		[NoScaleOffset]_MainTex ("MainTex", 2D) = "white" {}

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
			float4 _OutlineColor;
			float _OutlineSize;
			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Brow_L"
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
				float4 color : COLOR;
			};
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
				
				OUT.normal = TransformObjectToWorldNormal(IN.normal);
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv = OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {
				half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
 
				return baseMap * _Color * IN.color;
			}
			ENDHLSL
		}
		Pass {
			Name "Brow_L"
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
				float4 color : COLOR;
			};
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
				
				OUT.normal = TransformObjectToWorldNormal(IN.normal);
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv = OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {
				half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
 
				return baseMap * _Color * IN.color;
			}
			ENDHLSL
		}

		//Pass {
		//	Name "Outline"
		//	Cull Front
		//	ZTest Always
 
		//	HLSLPROGRAM

		//	#include "RoXamiOutline.hlsl"
			
 
		//	ENDHLSL
		//}
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