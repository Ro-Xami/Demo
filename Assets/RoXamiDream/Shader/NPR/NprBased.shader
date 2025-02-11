Shader "RoXami/NPR/Based"
{
    Properties
    {
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
		[SubToggle(g1, _ISARMMAP_ON)] _isArmMap("isArmMap", Int) = 0
		[Tex(g1)]_MaskMap ("ArmMap", 2D) = "white" {}
		[Sub(g1)]_ao ("AO" , Range(0 , 1)) = 1
		[Sub(g1)]_roughness ("Roughness" , Range(0 , 1)) = 0.5
		[Sub(g1)]_metallic ("Metallic" , Range(0 , 1)) = 0
		[Space(10)][g1,Title(Emission)]
		[SubToggle(g1, _ISEMISSIONMAP_ON)] _isEmissionMap("isEmissionMap", Int) = 0
		[Tex(g1)][NoScaleOffset] _EmissionMap ("EmissionMap", 2D) = "white" {}
		[Sub(g1)][HDR] _emissionColor ("EmissiveColor" , Color) = (0 , 0 , 0 , 0)
		//Toon
		[Main(g2, _, on, off)]_group2 ("Toon Rendering", float) = 0
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
		[Main(g3, _, on, off)]_group3 ("Outline", float) = 0
		[Sub(g3)] _outlineSize ("OutlineSize" , Range(0,1)) = 0.1
		[Sub(g3)] _outlineColor ("OutlineColor" , color) = (0,0,0,1)
		//SurfaceOptions
		[Main(g4, _, on, off)]_group4 ("Surface Options", float) = 0
		[g4,Title(Render Type)]
		[Preset(g4, LWGUI_Preset_BlendMode)] _surfaceOptions ("Surface Options", float) = 0
		[SubToggle(g4, _ISALPHACLIP_ON)] _isAlphaClip("isAlphaClip", Int) = 0
		[Sub(g4)]_cutOut("CutOut" , Range(0,1)) = 0.5
		[Space(10)][g4,Title(Surface)]
		[SubEnum(g4, UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", Float) = 2
		[SubToggle(g4, _ISRECEIVETOONSHADOW_ON)] _isReceiveToonShadow("isReceiveToonShadow", Int) = 1
		[Space(10)][g4,Title(Transparent Options)]
		[SubToggle(g4)] _ZWrite ("ZWriteMode ", Float) = 1
		[SubEnum(g4, UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTestMode", Float) = 4
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("SrcBlend", Float) = 1
		[HideInInspector][Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("DstBlend", Float) = 0
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
			ZWrite [_ZWrite]
			ZTest [_ZTest]
			Cull [_CullMode]

		HLSLPROGRAM

		CBUFFER_START(UnityPerMaterial)
		#include "../HLSL/NPR/NPRBasedCbuffer.hlsl"
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

			#include_with_pragmas "../HLSL/NPR/NPRBasedFragment.hlsl"			
			
			ENDHLSL
		}

		Pass 
			{
			Name "Outline"
			Cull Front
 
			HLSLPROGRAM

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
