Shader "Example/UnlitShaderExample" {
	Properties {
		_BaseMap ("Example Texture", 2D) = "white" {}
		_BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			CBUFFER_END
		ENDHLSL

		Pass {
			Name "Example"
			Tags { "LightMode"="UniversalForward" }
 
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile_fog

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
 
			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 color : COLOR;
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD2;
				float2 uv : TEXCOORD0;
				float3 viewWS : TEXCOORD6;
				float3 normalWS : TEXCOORD3;
				float3 tangentWS : TEXCOORD4;
				float3 bitangentWS : TEXCOORD5;
				float4 color : COLOR;
			};
 
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
 
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;

				VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz , IN.tangentOS);
				OUT.normalWS = normalInputs.normalWS;
				OUT.tangentWS = normalInputs.tangentWS;
				OUT.bitangentWS = normalInputs.bitangentWS;
				OUT.viewWS = SafeNormalize(GetCameraPositionWS() - OUT.positionWS);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.color = IN.color;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

				 Light light = GetMainLight();
				half3 lightDir = normalize(light.direction);
				half3 normalDir = normalize(IN.normalWS);
				half3 camDir = normalize(_WorldSpaceCameraPos.xyz);
				half3 viewDir = normalize(camDir - normalize(IN.positionWS.xyz));
				half rim = 1 - dot(normalDir , IN.viewWS);
				rim = step(0.8 , rim);

				half lit = dot(lightDir , normalDir);
 
				return float4(rim.xxx , 1);
			}
			ENDHLSL
		}
	}
}