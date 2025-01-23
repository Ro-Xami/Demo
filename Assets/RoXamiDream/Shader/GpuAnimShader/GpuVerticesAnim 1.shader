Shader "RoXami/GpuAnim/GpuVerticesAnim_"
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

			Texture2D<float4> _verticesAnimTex;

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
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
				float4 uv1 : TEXCOORD1;

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
				float4 uv1 : TEXCOORD7;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				float weights[4] = {IN.color.x , IN.color.y , IN.color.z , IN.color.w};
				float bones[4] = {IN.uv1.x , IN.uv1.y , IN.uv1.z , IN.uv1.w};

				float4 trs = weights[0] * _verticesAnimTex.Load(int3(bones[0] , _frameIndex , 0));
				float3 testPos = float3(0,0,0);
				for(int i = 0 ; i < 4 ; i++)
				{
					if(bones[i] != 0)
					{
						float4 m0 = _verticesAnimTex.Load(int3(bones[i] , _frameIndex , 0));
						float4 m1 = _verticesAnimTex.Load(int3(bones[i] + 1 , _frameIndex , 0));
						float4 m2 = _verticesAnimTex.Load(int3(bones[i] + 2 , _frameIndex , 0));
						float4 m3 = float4(0 , 0 , 0 , 1);

						float4x4 boneMatrix = float4x4(m0 , m1 , m2 , m3);

						testPos += weights[0] * mul(boneMatrix , float4(IN.positionOS.xyz , 1));
					}
				}
				IN.positionOS.xyz += testPos;
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
				OUT.uv1 = IN.uv1;
				OUT.color = IN.color;
				return OUT;
			}
			
			half4 frag(Varyings IN) : SV_Target {
 
				return IN.color.w;
			}
			//#include_with_pragmas "../HLSL/ToonLit/ToonLitFragment.hlsl"			
			
			ENDHLSL
		}

    }
	//CustomEditor "ToonLitShaderGUI"
}
