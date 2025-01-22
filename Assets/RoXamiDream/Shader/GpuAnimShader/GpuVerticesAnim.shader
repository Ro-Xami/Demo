Shader "RoXami/GpuAnim/GpuVerticesAnim"
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
		[Toggle] _isReceiveToonShadow ("isReceiveToonShadow", Int) = 0
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
		//GpuAnim------------------------------------------------------------
		[Header(Option)]
		_verticesAnimTex ("VerticesAnimTex" , 2D) = "white" {}
		_frameIndex ("FrameIndex" , float) = 0
		[Toggle] _isNormalTangent ("isNormalTangent", Int) = 0
		[HideInInspector]_texWidth ("TexWidth" , float) = 0
		[HideInInspector]_texHeight ("TexHeight" , float) = 0
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
			#pragma shader_feature_local _ISNORMALTANGENT_ON

			TEXTURE2D(_verticesAnimTex);
			SAMPLER(sampler_verticesAnimTex);

			#include "../HLSL/GpuAnim/GpuVerticesAnimInput.hlsl"
			

		ENDHLSL

		Pass {
			Name "ForwardLit"
			Tags {"LightMode" = "UniversalForward"}

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
			Cull [_CullMode]

		HLSLPROGRAM

		CBUFFER_START(UnityPerMaterial)
		#include "../HLSL/ToonLit/ToonLitCbuffer.hlsl"
		float _frameIndex;
		float _texWidth;
		float _texHeight;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _frameIndex)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _frameIndex              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _frameIndex)
        #endif

			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuVertices_MatrixFrameIndex.hlsl"
            #pragma instancing_options procedural:setup
			

			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float3 normalWS : TEXCOORD2;
				float3 tangentWS : TEXCOORD3;
				float3 bitangentWS : TEXCOORD4;
				float3 viewWS : TEXCOORD5;
				float fogCoord : TEXCOORD6;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				IN.positionOS.xyz = TransformVertices(IN.positionOS.xyz , IN.uv1 , _frameIndex , _texHeight);
#ifdef _ISNORMALTANGENT_ON
				IN.normalOS = TransformNormals(IN.uv1 , _frameIndex , _texWidth , _texHeight);
				IN.tangentOS = TransformTangents(IN.uv1 , _frameIndex , _texWidth , _texHeight);
#else
#endif
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;

				VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS , IN.tangentOS);
				OUT.normalWS = normalInputs.normalWS;
				OUT.tangentWS = normalInputs.tangentWS;
				OUT.bitangentWS = normalInputs.bitangentWS;

				OUT.viewWS = SafeNormalize(GetCameraPositionWS() - OUT.positionWS);
				OUT.fogCoord = ComputeFogFactor(OUT.positionCS.z);
				OUT.uv = TRANSFORM_TEX(IN.uv, _baseMap);

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
		half4 _baseMap_ST;
		float _frameIndex;
		float _texWidth;
		float _texHeight;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _frameIndex)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _frameIndex              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _frameIndex)
        #endif

			#pragma target 2.0
			#pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuVertices_MatrixFrameIndex.hlsl"
            #pragma instancing_options procedural:setup

			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;

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

				IN.positionOS.xyz = TransformVertices(IN.positionOS.xyz , IN.uv1 , _frameIndex , _texHeight);
#ifdef _ISNORMALTANGENT_ON
				IN.normalOS = TransformNormals(IN.uv1 , _frameIndex , _texWidth , _texHeight);
				//IN.tangentOS = TransformTangents(IN.uv1 , _frameIndex , _texWidth , _texHeight);
#else
#endif
				float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
				positionWS = ApplyShadowBias(positionWS, normalWS, _LightDirection);
                OUT.positionCS = TransformWorldToHClip(positionWS);
				OUT.uv = TRANSFORM_TEX(IN.uv , _baseMap);

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
		half4 _baseMap_ST;
		float _frameIndex;
		float _texWidth;
		float _texHeight;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _frameIndex)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _frameIndex              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _frameIndex)
        #endif

			#pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuVertices_MatrixFrameIndex.hlsl"
            #pragma instancing_options procedural:setup

			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;

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

				IN.positionOS.xyz = TransformVertices(IN.positionOS.xyz , IN.uv1 , _frameIndex , _texHeight);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv , _baseMap);

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
		half4 _baseMap_ST;
		half _normalStrength;
		float _frameIndex;
		float _texWidth;
		float _texHeight;
		CBUFFER_END

		#ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _frameIndex)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _frameIndex              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _frameIndex)
        #endif

			#pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing
			#include "../HLSL/GpuAnim/GpuVertices_MatrixFrameIndex.hlsl"
            #pragma instancing_options procedural:setup

			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;

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

				IN.positionOS.xyz = TransformVertices(IN.positionOS.xyz , IN.uv1 , _frameIndex , _texHeight);
#ifdef _ISNORMALTANGENT_ON
				IN.normalOS = TransformNormals(IN.uv1 , _frameIndex , _texWidth , _texHeight);
				IN.tangentOS = TransformTangents(IN.uv1 , _frameIndex , _texWidth , _texHeight);
#else
#endif
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz , IN.tangentOS);
				OUT.normalWS = normalInputs.normalWS;
				OUT.tangentWS = normalInputs.tangentWS;
				OUT.bitangentWS = normalInputs.bitangentWS;
				OUT.uv = TRANSFORM_TEX(IN.uv , _baseMap);

				return OUT;
			}

			#include "../HLSL/ToonLit/ToonPassDepthNormalsFragment.hlsl"

            ENDHLSL
        }
    }
	CustomEditor "ToonLitShaderGUI"
}
