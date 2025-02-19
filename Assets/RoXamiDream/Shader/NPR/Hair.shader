Shader "RoXami/NPR/Hair" {
	Properties {
		//PBR
		[Main(g1, _, on, off)]_group1 ("PBR Rendering", float) = 1
		[g1,Title(Base Color)]
		[Sub(g1)] _BaseColor ("Color" , Color) = (1 , 1 , 1 , 1)
        [Sub(g1)] _BaseMap ("BaseMap", 2D) = "white" {}
		[Space(10)][g1,Title(Normal)]
		[SubToggle(g1, _ISNORMALMAP_ON)] _isNormalMap("isNormalMap", Int) = 0
		[Tex(g1)][Normal] _NormalMap ("NormalMap", 2D) = "Bump" {}
		[Sub(g1)]_normalStrength ("NormalScale" , float) = 0
		[Space(10)][g1,Title(PBR)]
		[SubToggle(g1, _ISSPECMAP_ON)] _isSpecMap("isSpecMap", Int) = 0
		[Sub(g1)] _SpecMap ("SpecMap", 2D) = "white" {}
		[Sub(g1)]_roughness ("Roughness" , Range(0 , 1)) = 0.9
		//Toon
		[Main(g2, _, on, off)]_group2 ("Toon Rendering", float) = 0
		[g2,Title(Ramp)]
		[SubToggle(g2, _ISRAMPMAP_ON)] _isRampMap("isRampMap", Int) = 0
		[Sub(g2)] _RampMap ("RampMap", 2D) = "white" {}
		[g2,Title(Diffuse)]
		[Sub(g2)]_lightColor ("LightColor" , Color) = (1 , 1 , 1 , 1)
		[Sub(g2)]_shadowColor ("ShadowColor" , Color) = (0.1 , 0.1 , 0.1 , 1)
		[MinMaxSlider(g2,_diffuseMin, _diffuseMax)] _diffuseSlider ("Diffuse Slider", Range(0.0, 1.0)) = 1.0
		[HideInInspector]_diffuseMin ("DiffuseMin" , Range(0 , 1)) = 0.5
		[HideInInspector]_diffuseMax ("DiffuseMax" , Range(0 , 1)) = 0.75
		[Space(10)][g2,Title(Spec)]
		[Sub(g2)]_specColor ("SpecColor" , Color) = (0.5 , 0.5 , 0.5 , 1)
		[MinMaxSlider(g2,_specMin, _specMax)] _specSlider ("Spec Slider", Range(0.0, 1.0)) = 1.0
		[HideInInspector]_specMin ("SpecMin" , Range(0 , 1)) = 0.7
		[HideInInspector]_specMax ("SpecMax" , Range(0 , 1)) = 1
		[Space(10)][g2,Title(InSpec)]
		[Sub(g2)]_inSpecColor ("InSpecColor" , Color) = (1 , 1 , 1 , 1)
		[MinMaxSlider(g2,_inSpecMin, _inSpecMax)] _inSpecSlider ("inSpec Slider", Range(0.0, 1.0)) = 1.0
		[HideInInspector]_inSpecMin ("InSpecMin" , Range(0 , 1)) = 0.5
		[HideInInspector]_inSpecMax ("InSpecMax" , Range(0 , 1)) = 0.75
		//Outline
		[Main(g4, _, on, off)]_group4 ("Outline", float) = 0
		[Preset(g4, LWGUI_EnableOutlinePass)] _outlinePass ("Outline Pass", float) = 0
		[Sub(g4)] _outlineSize ("OutlineSize" , Range(0,1)) = 0.1
		[Sub(g4)] _outlineColor ("OutlineColor" , color) = (0,0,0,1)
		//SurfaceOptions
		[Main(g5, _, on, off)]_group5 ("Surface Options", float) = 0
		[g5,Title(Render Type)]
		[SubEnum(g5, UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
		[SubToggle(g5, _ISRECEIVETOONSHADOW_ON)] _isReceiveToonShadow("isReceiveToonShadow", Int) = 1
		[Sub(g5)] _refValue ("RefValue" , Int) = 1
	}

	SubShader {
		Tags { "RenderType"="Opaque" "Queue" = "Geometry" "RenderPipeline"="UniversalPipeline" "IgnoreProjector" = "True"}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma shader_feature_local _ISRAMPMAP_ON
			#pragma shader_feature_local _ISSPECMAP_ON

		ENDHLSL

		Pass {
		Name "Hair"
		Tags {"LightMode" = "UniversalForward"}

		Cull [_CullMode]
		Stencil
            {
                Ref 1
                Comp Greater
                Pass Keep
                Fail Keep
            }

		HLSLPROGRAM

		CBUFFER_START(UnityPerMaterial)
		#include "../HLSL/ToonLit/ToonLitCbuffer.hlsl"
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

        #define _BaseColor              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor)
        #endif

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			#include "../HLSL/ToonLit/ToonLitVaryings.hlsl"
			#include_with_pragmas "../HLSL/NPR/HairFragment.hlsl"			
			
			ENDHLSL
		}

		Pass 
			{
			Name "Outline"
			Tags{"LightMode" = "SRPDefaultUnlit"}
			Cull Front
			Stencil
            {
                Ref 1
                Comp Greater
                Pass Keep
                Fail Keep
            }
 
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "../HLSL/NPR/NPROutline.hlsl"
			
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

			#include "../HLSL/ToonLit/ToonPassShadowCastVaryings.hlsl"
			#include "../HLSL/ToonLit/ToonPassShadowCastFragment.hlsl"
		
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

			#include "../HLSL/ToonLit/ToonPassDepthOnlyVaryings.hlsl"
			#include "../HLSL/ToonLit/ToonPassDepthOnlyFragment.hlsl"

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

			#include "../HLSL/ToonLit/ToonPassDepthNormalsVaryings.hlsl"
			#include "../HLSL/ToonLit/ToonPassDepthNormalsFragment.hlsl"

            ENDHLSL
        }
	}

	CustomEditor "LWGUI.LWGUI"
}