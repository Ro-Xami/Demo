Shader "Jian/ToonLit"
{
    Properties
    {
		_Color ("Color" , Color) = (1 , 1 , 1 , 1)
        [NoScaleOffset] _baseMap ("BaseMap", 2D) = "white" {}
		[Toggle] _isNormalMap("isNormalMap", Int) = 0
		[NoScaleOffset] _normalMap ("NormalMap", 2D) = "Bump" {}
		_normalStrength ("NormalScale" , float) = 0
		[Toggle] _isArmMap("isArmMap", Int) = 0
		[NoScaleOffset]_maskMap ("ArmMap", 2D) = "white" {}
		_ao ("AO" , Range(0 , 1)) = 1
		_roughness ("Roughness" , Range(0 , 1)) = 0.5
		_metallic ("Metallic" , Range(0 , 1)) = 0
		[Toggle] _isEmissionMap("isEmissionMap", Int) = 0
		[NoScaleOffset] _emissionMap ("EmissionMap", 2D) = "white" {}
		[HDR] _emissionColor ("EmissiveColor" , Color) = (0 , 0 , 0 , 0)
		[Toggle] _isAlphaClip("isAlphaClip", Int) = 0
		_cutOut("CutOut" , Range(0,1)) = 0.5
		_diffuseMin ("DiffuseMin" , Range(0 , 1)) = 0.5
		_diffuseMax ("DiffuseMax" , Range(0.01 , 1)) = 0.75
		_lightColor ("LightColor" , Color) = (1 , 1 , 1 , 1)
		_shadowColor ("ShadowColor" , Color) = (0.1 , 0.1 , 0.1 , 1)
		_specMin ("SpecMin" , Range(0.01 , 0.9999)) = 0.7
		_specMax ("SpecMax" , Range(0.01 , 0.5)) = 1
		_specColor ("SpecColor" , Color) = (0.5 , 0.5 , 0.5 , 0.5)
		_inSpecMin ("InSpecMin" , Range(0.01 , 1)) = 0.5
		_inSpecMax ("InSpecMax" , Range(0.01 , 0.5)) = 0.75
		_inSpecColor ("InSpecColor" , Color) = (1 , 1 , 1 , 1)
		[Toggle] _isBrush("isBrush", Int) = 0
		_brush ("BrushMap" , 2D) = "white" {}
		_brushTransform ("BrushTransform" , vector) = (10 , 10 , 10 , 0)
		_brushStrength ("BrushStrength" , vector) = (0.1 , 0.1 , 0.1 , 0)

		//SurfaceOptions
		[Toggle] _isOpaque ("isOpaque", Int) = 0
		[Toggle] _isReceiveToonShadow ("isReceiveToonShadow", Int) = 1
		//Pass----------------------------------------------------------------
		[Toggle] _isShadowCasterPass ("isShadowCasterPass", Int) = 1
		[Toggle] _isDepthOnlyPass ("isDepthOnlyPass", Int) = 1
		[Toggle] _isDepthNormalsPass ("isDepthNormalsPass", Int) = 1
		//Option------------------------------------------------------------
		[Header(Option)]
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("SrcBlend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("DstBlend", Float) = 0
		[Enum(Off, 0, On, 1)]_ZWriteMode ("ZWriteMode", float) = 1
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode ("ZTestMode", Float) = 4
    }

        SubShader {

		Tags{ "RenderType"="Opaque" "Queue" = "Geometry" "RenderPipeline"="UniversalPipeline" "IgnoreProjector" = "True"}

		HLSLINCLUDE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma shader_feature_local _ISNORMALMAP_ON
			#pragma shader_feature_local _ISARMMAP_ON
			#pragma shader_feature_local _ISEMISSIONMAP_ON
			#pragma shader_feature_local _ISBRUSH_ON
			#pragma shader_feature_local _ISALPHACLIP_ON
			#pragma shader_feature_local _ISRECEIVETOONSHADOW_ON

			

		ENDHLSL

		Pass {
			Tags {"LightMode" = "UniversalForward"}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]

		HLSLPROGRAM

		CBUFFER_START(UnityPerMaterial)
		#include "HLSL/ToonLit/ToonLitCbuffer.hlsl"
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

        #define _Color              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Color)
        #endif

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			#include "HLSL/ToonLit/ToonLitVaryings.hlsl"

			#include_with_pragmas "HLSL/ToonLit/ToonLitFragment.hlsl"			
			
			ENDHLSL
		}

		Pass
        {
			Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On
            ZTest LEqual
            ColorMask 0
			Cull [_CullMode]

            HLSLPROGRAM
			#pragma target 2.0
			#pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

			#include "HLSL/ToonLit/ToonPassShadowCastVaryings.hlsl"
			#include "HLSL/ToonLit/ToonPassShadowCastFragment.hlsl"
		
            ENDHLSL
        }

		Pass
        {	
			Name "DepthOnly"
            Tags{ "LightMode" = "DepthOnly" }

			ZWrite On
            ColorMask R
			Cull [_CullMode]

            HLSLPROGRAM

			#pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

			#include "HLSL/ToonLit/ToonPassDepthOnlyVaryings.hlsl"
			#include "HLSL/ToonLit/ToonPassDepthOnlyFragment.hlsl"

            ENDHLSL
        }

		Pass
        {
			Name "DepthNormals"
            Tags{ "LightMode" = "DepthNormals" }

			ZWrite On
            Cull[_Cull]
			Cull [_CullMode]

            HLSLPROGRAM

			#pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

			#include "HLSL/ToonLit/ToonPassDepthNormalsVaryings.hlsl"
			#include "HLSL/ToonLit/ToonPassDepthNormalsFragment.hlsl"

            ENDHLSL
        }
    }

	CustomEditor "ToonLitShaderGUI"
}
