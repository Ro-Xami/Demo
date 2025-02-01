Shader "RoXami/GpuAnim"
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
		[Header(GpuAnim)]
		[Toggle] _IsBonesOrVertices ("IsBonesOrVertices", Int) = 0
		[Toggle] _isNormalTangent ("isNormalTangent", Int) = 0
		_gpuAnimationMatrix ("GpuAnimationMatrix" , 2D) = "white"
		_animationPlayedData ("AnimationPlayedData:frame,lastFrame,blend,0" , vector) = (0,0,0,0)	
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
			ZWrite [_ZWriteMode]
			ZTest [_ZTestMode]
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
				float4 color : COLOR;

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

				float3 positionOut = float3(0,0,0);
				float3 normalOut = float3(0,0,0);
				float4 tangentOut = float4(0,0,0,0);

#ifdef _ISBONESORVERTICES_ON
	#ifdef _ISNORMALTANGENT_ON
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.normalOS.xyz , IN.tangentOS
											, IN.uv1 , IN.color.xyz , _animationPlayedData
											, positionOut , normalOut , tangentOut);

					VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOut , tangentOut);
					OUT.normalWS = normalInputs.normalWS;
					OUT.tangentWS = normalInputs.tangentWS;
					OUT.bitangentWS = normalInputs.bitangentWS;
	#else
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.color.xyz , _animationPlayedData, positionOut);
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
											, IN.uv1 , IN.color.xyz , _animationPlayedData
											, positionOut , normalOut , tangentOut);
	#else
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.color.xyz , _animationPlayedData, positionOut);
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
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.color.xyz , _animationPlayedData, positionOut);
#else
					positionOut = TransformVertices(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1.xy , _animationPlayedData.x);
#endif

				OUT.positionCS = TransformObjectToHClip(positionOut);
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
											, IN.uv1 , IN.color.xyz , _animationPlayedData
											, positionOut , normalOut , tangentOut);

					VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOut , tangentOut);
					OUT.normalWS = normalInputs.normalWS;
					OUT.tangentWS = normalInputs.tangentWS;
					OUT.bitangentWS = normalInputs.bitangentWS;
	#else
					ComputeGpuBonesAnimationBlend(_gpuAnimationMatrix , IN.positionOS.xyz , IN.uv1 , IN.color.xyz , _animationPlayedData, positionOut);
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
				OUT.uv = TRANSFORM_TEX(IN.uv , _baseMap);

				return OUT;
			}

			#include "../HLSL/ToonLit/ToonPassDepthNormalsFragment.hlsl"

            ENDHLSL
        }
    }
	//CustomEditor "ToonLitShaderGUI"
}
