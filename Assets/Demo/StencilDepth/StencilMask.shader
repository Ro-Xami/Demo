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
				Ref [_refValue]//当前片元的参考值
				Comp Always //比较大小函数
				Pass [_passMode] //深度和缓冲区都通过，对Stencil值的操作
				Fail keep //深度和缓冲区都不通过，对Stencil值的操作
				ZFail keep //深度不通过，缓冲区通过，对Stencil值的操作
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