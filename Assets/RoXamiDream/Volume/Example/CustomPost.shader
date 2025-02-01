Shader "RoXami/CustomRenderFeature/CustomPost" {
	Properties {
	}
	SubShader {

		Pass {
			Name "Example"
			Tags { "LightMode"="SRPDefaultUnlit" }
 
			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

			float _MinFloat;
			float _RangeFloat;
			float4 _Color;
 
			half4 frag(Varyings IN) : SV_Target {
				half4 col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, IN.texcoord);
 
				return col * _Color + _MinFloat.xxxx + _RangeFloat.xxxx;
			}
			ENDHLSL
		}
	}
}