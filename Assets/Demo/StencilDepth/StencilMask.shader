Shader "RoXamiTest/StencilMask" {
	Properties {

		_refValue ("RefValue" , Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _compMode ("CompMode" , float) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _passMode ("PassMode" , float) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

		HLSLINCLUDE

		ENDHLSL

		Pass {
			Tags { "LightMode"="UniversalForward" }

			ColorMask 0
			ZWrite Off
			//ZTest 
			Stencil
			{
				Ref [_refValue]//��ǰƬԪ�Ĳο�ֵ
				Comp Always //�Ƚϴ�С����
				Pass [_passMode] //��Ⱥͻ�������ͨ������Stencilֵ�Ĳ���
				Fail keep //��Ⱥͻ���������ͨ������Stencilֵ�Ĳ���
				ZFail keep //��Ȳ�ͨ����������ͨ������Stencilֵ�Ĳ���
				WriteMask 255
				ReadMask 255
			}

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
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
			};
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
 
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;

				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {

				return 1;
			}
			ENDHLSL
		}
	}
}