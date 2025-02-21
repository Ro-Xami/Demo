Shader "RoXami/GpuAnim"
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
		//Brush
		[Main(g3, _ISBRUSH_ON, off)]_group3 ("Toon Brush", float) = 0
		[Sub(g3)] _BrushMap ("BrushMap" , 2D) = "white" {}
		[Sub(g3)] _brushTransform ("BrushTransform" , vector) = (10 , 10 , 10 , 0)
		[Sub(g3)] _brushStrength ("BrushStrength" , vector) = (0.1 , 0.1 , 0.1 , 0)
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
		//GpuAnim------------------------------------------------------------
		[Main(GpuAnim, _, on, off)] _gpuAnim ("GPU Animation", float) = 0
		[Preset(GpuAnim, LWGUI_GpuAnimationType)] _gpuAnimType ("GPU Animation Type", float) = 0
		[SubToggle(GpuAnim, _ISNORMALTANGENT_ON)] _isNormalTangent ("isNormalTangent", Int) = 1
		[Tex(GpuAnim)]_gpuAnimationMatrix ("GpuAnimationMatrix" , 2D) = "white"
		[Sub(GpuAnim)] _animationPlayedData ("AnimationPlayedData:frame,lastFrame,blend,0" , vector) = (0,0,0,0)	
    }

        SubShader {

		Tags{ "RenderType"="Opaque" "Queue" = "Geometry" "RenderPipeline"="UniversalPipeline" "IgnoreProjector" = "True"}

		HLSLINCLUDE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "../HLSL/GpuAnim/GpuVerticesAnimInput.hlsl"
			#include "../HLSL/GpuAnim/GpuBonesAnimInput.hlsl"

			#pragma shader_feature_local _ISNORMALMAP_ON
			#pragma shader_feature_local _ISARMMAP_ON
			#pragma shader_feature_local _ISEMISSIONMAP_ON
			#pragma shader_feature_local _ISBRUSH_ON
			#pragma shader_feature_local _ISALPHACLIP_ON
			#pragma shader_feature_local _ISRECEIVETOONSHADOW_ON
			#pragma shader_feature_local _ISBONESORVERTICES_ON
			#pragma shader_feature_local _ISNORMALTANGENT_ON
			
			Texture2D<float4> _gpuAnimationMatrix;
		ENDHLSL

		Pass {
			Name "ForwardLit"
			Tags {"LightMode" = "UniversalForward"}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			ZTest [_ZTest]
			Cull [_CullMode]

		HLSLPROGRAM

		CBUFFER_START(UnityPerMaterial)
		#include "../HLSL/ToonLit/ToonLitCbuffer.hlsl"
		float4 _animationPlayedData;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _animationPlayedData)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _animationPlayedData              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _animationPlayedData)
        #endif

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuAnimaStructuredBufferInput.hlsl"
            #pragma instancing_options procedural:setup
			

			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float3 normalWS : TEXCOORD3;
				float3 tangentWS : TEXCOORD4;
				float3 bitangentWS : TEXCOORD5;
				float3 viewWS : TEXCOORD6;
				float fogCoord : TEXCOORD7;
				float2 screenSpaceUV : TEXCOORD8;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				float3 positionOut = float3(0,0,0);
				float3 normalOut = float3(0,0,0);
				float4 tangentOut = float4(0,0,0,0);

#ifdef _ISBONESORVERTICES_ON
	#ifdef _ISNORMALTANGENT_ON
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.normalOS.xyz , IN.tangentOS
											, IN.uv1 , IN.uv2 , _animationPlayedData
											, positionOut , normalOut , tangentOut);

					VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOut , tangentOut);
					OUT.normalWS = normalInputs.normalWS;
					OUT.tangentWS = normalInputs.tangentWS;
					OUT.bitangentWS = normalInputs.bitangentWS;
	#else
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.uv2 , _animationPlayedData, positionOut);
	#endif
#else
					positionOut = TransformVertices(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1.xy , _animationPlayedData.x);
	#ifdef _ISNORMALTANGENT_ON
					normalOut = TransformNormals(_gpuAnimationMatrix , IN.uv1.xy , _animationPlayedData.x);
					tangentOut = TransformTangents(_gpuAnimationMatrix , IN.uv1.xy , _animationPlayedData.x);

					VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOut , tangentOut);
					OUT.normalWS = normalInputs.normalWS;
					OUT.tangentWS = normalInputs.tangentWS;
					OUT.bitangentWS = normalInputs.bitangentWS;
	#endif
#endif
				VertexPositionInputs positionInputs = GetVertexPositionInputs(positionOut);
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;

				OUT.viewWS = SafeNormalize(GetCameraPositionWS() - OUT.positionWS);
				OUT.fogCoord = ComputeFogFactor(OUT.positionCS.z);
				OUT.screenSpaceUV = GetNormalizedScreenSpaceUV(OUT.positionCS);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.uv1 = OUT.uv;

				return OUT;
			}
			
			#include_with_pragmas "../HLSL/ToonLit/ToonLitFragment.hlsl"			
			
			ENDHLSL
		}

		Pass
        {
			Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM

			CBUFFER_START(UnityPerMaterial)
		half _cutOut;
		half4 _BaseMap_ST;
		float4 _animationPlayedData;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _animationPlayedData)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _animationPlayedData              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _animationPlayedData)
        #endif

			#pragma target 2.0
			#pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuAnimaStructuredBufferInput.hlsl"
            #pragma instancing_options procedural:setup

			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			float3 _LightDirection;
            half4 _ShadowBias; // x: depth bias, y: normal bias
            half4 _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise)

            float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
            {
                float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;
                positionWS = lightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                return positionWS;
            }

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				float3 positionOut = float3(0,0,0);
				float3 normalOut = float3(0,0,0);
				float4 tangentOut = float4(0,0,0,0);

#ifdef _ISBONESORVERTICES_ON
	#ifdef _ISNORMALTANGENT_ON
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.normalOS.xyz , IN.tangentOS
											, IN.uv1 , IN.uv2 , _animationPlayedData
											, positionOut , normalOut , tangentOut);
	#else
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.uv2 , _animationPlayedData, positionOut);
	#endif
#else
					positionOut = TransformVertices(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1.xy , _animationPlayedData.x);
	#ifdef _ISNORMALTANGENT_ON
					normalOut = TransformNormals(_gpuAnimationMatrix , IN.uv1.xy , _animationPlayedData.x);
	#endif
#endif
		
				float3 positionWS = TransformObjectToWorld(positionOut);
				float3 normalWS = TransformObjectToWorldNormal(normalOut);
				positionWS = ApplyShadowBias(positionWS, normalWS, _LightDirection);
                OUT.positionCS = TransformWorldToHClip(positionWS);
				OUT.uv = TRANSFORM_TEX(IN.uv , _BaseMap);

				return OUT;
			}

			#include "../HLSL/ToonLit/ToonPassShadowCastFragment.hlsl"
		
            ENDHLSL
        }

		Pass
        {	
			Name "DepthOnly"
            Tags{ "LightMode" = "DepthOnly" }

			ZWrite On
            ColorMask R

            HLSLPROGRAM

			CBUFFER_START(UnityPerMaterial)
		half _cutOut;
		half4 _BaseMap_ST;
		float4 _animationPlayedData;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _animationPlayedData)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _animationPlayedData              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _animationPlayedData)
        #endif

			#pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuAnimaStructuredBufferInput.hlsl"
            #pragma instancing_options procedural:setup

			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				float3 positionOut = float3(0,0,0);
				float3 normalOut = float3(0,0,0);
				float4 tangentOut = float4(0,0,0,0);

#ifdef _ISBONESORVERTICES_ON
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.uv2 , _animationPlayedData, positionOut);
#else
					positionOut = TransformVertices(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1.xy , _animationPlayedData.x);
#endif

				OUT.positionCS = TransformObjectToHClip(positionOut);
				OUT.uv = TRANSFORM_TEX(IN.uv , _BaseMap);

				return OUT;
			}

			#include "../HLSL/ToonLit/ToonPassDepthOnlyFragment.hlsl"

            ENDHLSL
        }

		Pass
        {
			Name "DepthNormals"
            Tags{ "LightMode" = "DepthNormals" }

			ZWrite On
            Cull[_Cull]

            HLSLPROGRAM

			CBUFFER_START(UnityPerMaterial)
		half _cutOut;
		half4 _BaseMap_ST;
		half _normalStrength;
		float4 _animationPlayedData;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _animationPlayedData)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _animationPlayedData              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _animationPlayedData)
        #endif

			#pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuAnimaStructuredBufferInput.hlsl"
            #pragma instancing_options procedural:setup

			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uv2 : TEXCOORD2;
				float4 color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD;
				float3 normalWS : TEXCOORD1;
				float3 tangentWS : TEXCOORD2;
				float3 bitangentWS : TEXCOORD3;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);
				float3 positionOut = float3(0,0,0);
				float3 normalOut = float3(0,0,0);
				float4 tangentOut = float4(0,0,0,0);

#ifdef _ISBONESORVERTICES_ON
	#ifdef _ISNORMALTANGENT_ON
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.normalOS.xyz , IN.tangentOS
											, IN.uv1 , IN.uv2 , _animationPlayedData
											, positionOut , normalOut , tangentOut);

					VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOut , tangentOut);
					OUT.normalWS = normalInputs.normalWS;
					OUT.tangentWS = normalInputs.tangentWS;
					OUT.bitangentWS = normalInputs.bitangentWS;
	#else
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.uv2 , _animationPlayedData, positionOut);
	#endif
#else
					positionOut = TransformVertices(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1.xy , _animationPlayedData.x);
	#ifdef _ISNORMALTANGENT_ON
					normalOut = TransformNormals(_gpuAnimationMatrix , IN.uv1.xy , _animationPlayedData.x);
					tangentOut = TransformTangents(_gpuAnimationMatrix , IN.uv1.xy , _animationPlayedData.x);

					VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOut , tangentOut);
					OUT.normalWS = normalInputs.normalWS;
					OUT.tangentWS = normalInputs.tangentWS;
					OUT.bitangentWS = normalInputs.bitangentWS;
	#endif
#endif
				OUT.positionCS = TransformObjectToHClip(positionOut);
				OUT.uv = TRANSFORM_TEX(IN.uv , _BaseMap);

				return OUT;
			}

			#include "../HLSL/ToonLit/ToonPassDepthNormalsFragment.hlsl"

            ENDHLSL
        }
    }
	CustomEditor "LWGUI.LWGUI"
}
