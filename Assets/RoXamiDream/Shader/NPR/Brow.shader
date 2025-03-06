Shader "RoXami/NPR/Brow"{
Properties {
		_BaseColor ("Color", Color) = (1, 1, 1, 1)
		[NoScaleOffset]_MainTex ("MainTex", 2D) = "white" {}
		_refValue ("RefValue" , Int) = 1
		[Header(OutLine)]
		_outlineColor ("OutLineColor" , Color) = (0,0,0,1)
		_outlineSize ("OutLineSize" , Float) = 1
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		ENDHLSL

		Pass {
			Name "Brow"
			Tags { "LightMode"="UniversalForward" }

			Stencil
            {
                Ref 2
                Comp GEqual
                Pass Replace
                Fail Keep
            }
 
			HLSLPROGRAM

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			CBUFFER_END

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
 
				return baseMap * _BaseColor;
			}
			ENDHLSL
		}

		Pass 
			{
			Name "Outline"
			Tags{"LightMode" = "SRPDefaultUnlit"}
			Cull Front

            Stencil
            {
                Ref 2
                Comp GEqual
                Pass Replace
                Fail Keep
            }
 
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "../HLSL/NPR/NPROutline.hlsl"
			
			ENDHLSL
			}

	}
}