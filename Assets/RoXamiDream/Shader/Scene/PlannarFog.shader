Shader "RoXami/Scene/PlannarFog"{
	Properties{
			[KeywordEnum(Linear, EXP, EXP2)] _FOGMODE ("Fog Mode" , Float) = 0
			_fogColor ("Fog Color" , Color) = (1,1,1,1)

			[Space(20)][Header(Linear Mode)]
			
			_linearStart ("Linear Depth Start" , Float) = 65
			_linearEnd ("Linear Depth End" , Float) = 95
			_heightStart ("Linear Height Start" , Float) = 0
			_heightEnd ("Linear Height End" , Float) = 50

			[Space(20)][Header(Exponential Mode)]
			_expDepthStart ("EXP Depth Start" , Float) = 0
			_depthDensity ("EXP Depth Density" , Range(0 , 1)) = 0.01
			_expHeightStart ("EXP Height Start" , Float) = 0
			_heightDensity ("EXP Height Density" , Range(0 , 1)) = 0.01

			[Header(Noise)]
			[Toggle(_FOG_NOISE_ON)]_noiseON ("Enabel NoiseMap" , Float) = 0
			[NoScaleOffset]_NoiseMap ("Noise Map" , 2D) = "white" {}
			_noiseVec0 ("XY: Tiling; ZW: MoveSpeed" , Vector) = (1,1,0,0)
			_noiseVec1 ("XY: Tiling; ZW: MoveSpeed" , Vector) = (1,1,0,0)
			_noiseAlpha ("Noise Alpha" , Range(-1 , 1)) = 1

			[Space(20)][Header(Scattering)]
			[Toggle(_FOG_SCATTERING_ON)]_scaterringON ("Enabel Scattering" , Float) = 0
			_scatteringPow ("Scattering Power" , Range(0 , 20)) = 5
		}

	SubShader{

		Tags {"RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}
		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		ENDHLSL

		Pass{
			Tags {"LightMode"="UniversalForward"}
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature _FOG_NOISE_ON
			#pragma shader_feature _FOG_SCATTERING_ON
			#pragma shader_feature _FOGMODE_LINEAR _FOGMODE_EXP _FOGMODE_EXP2

			TEXTURE2D(_NoiseMap);
			SAMPLER(sampler_NoiseMap);

			CBUFFER_START(UnityPerMaterial)
				half _linearStart;
				half _linearEnd;
				half4 _fogColor;
				half _heightStart;
				half _heightEnd;
				half4 _noiseVec0;
				half4 _noiseVec1;
				half _noiseAlpha;
				half _FOGMODE;
				half _depthDensity;
				half _heightDensity;
				half _scatteringPow;
				half _expDepthStart;
				half _expHeightStart;
			CBUFFER_END

			half ComputeFogLinear(float z , half start , half end)
			{	//factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
				return saturate((start - z) / (start - end));
			}

			half ComputeFogEXP(float z , float density)
			{	//factor = exp(-density*z)
				return 1 - exp(-density * z);
			}

			half ComputeFogEXP2(float z , float density)
			{	//factor = exp(-(density*z)^2)
				half fogFactor = dot(density * z , density * z);
				return 1 - exp(- fogFactor);
			}

			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 srcPos : TEXCOORD1;
			};

			Varyings vert(Attributes IN){
				Varyings OUT = (Varyings) 0;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.srcPos = ComputeScreenPos(OUT.positionCS);
				OUT.uv = IN.uv;

				return OUT;
			}

			half4 frag (Varyings IN) : SV_Target{

				//Depth
				float2 screenSpaceUV = IN.srcPos.xy / IN.srcPos.w;
				half depth = SampleSceneDepth(screenSpaceUV);

				//PositionWS
				float4 ndc = float4(screenSpaceUV.xy * 2 - 1, depth, 1);
				#if UNITY_UV_STARTS_AT_TOP
				   ndc.y *= -1;
				#endif
				float4 positionWS = mul(UNITY_MATRIX_I_VP, ndc);
				positionWS /= positionWS.w;

				//FOG
				half4 fogCol = _fogColor;
				half fogDepth = LinearEyeDepth(depth, _ZBufferParams);
				half fogHeight = _WorldSpaceCameraPos.y - positionWS.y;

				#ifdef _FOGMODE_LINEAR
					fogDepth = ComputeFogLinear(fogDepth , _linearStart , _linearEnd);
					fogHeight = ComputeFogLinear(fogHeight , _heightStart , _heightEnd);
				#elif _FOGMODE_EXP
					fogDepth = max(0 , fogDepth - _expDepthStart);
					fogDepth = ComputeFogEXP(fogDepth, _depthDensity);
					fogHeight = max(0 , fogHeight - _expHeightStart);
					fogHeight = ComputeFogEXP(fogHeight, _heightDensity);
				#elif _FOGMODE_EXP2
					fogDepth = max(0 , fogDepth - _expDepthStart);
					fogDepth = ComputeFogEXP2(fogDepth, _depthDensity);
					fogHeight = max(0 , fogHeight - _expHeightStart);
					fogHeight = ComputeFogEXP2(fogHeight, _heightDensity);
				#endif
				fogCol.a *= saturate(fogDepth + fogHeight);

				//Noise
				#ifdef _FOG_NOISE_ON
					half2 noiseUV = positionWS.xz / 1000;
					float noiseSpeed = _Time.y / 100;
					half2 noiseUV0 = noiseUV * _noiseVec0.xy + noiseSpeed * _noiseVec0.zw;
					half2 noiseUV1 = noiseUV * _noiseVec1.xy + noiseSpeed * _noiseVec1.zw;
					half noise = SAMPLE_TEXTURE2D(_NoiseMap , sampler_NoiseMap , noiseUV0).r;
					noise += SAMPLE_TEXTURE2D(_NoiseMap , sampler_NoiseMap , noiseUV1).r;
					noise = saturate(_noiseAlpha + noise);
					fogCol.a *= noise;
				#endif

				//without Skybox
				fogCol.a *= step(FLT_MIN , depth);

				//Scattering
				#ifdef _FOG_SCATTERING_ON
					Light light = GetMainLight();
					half3 lightDir = normalize(light.direction);
					half3 viewDir = normalize(positionWS.xyz - _WorldSpaceCameraPos.xyz);
					half VoL = pow(max(0 , _scatteringPow) , dot(lightDir , viewDir));
					VoL = saturate(VoL);
					fogCol.rgb = lerp(fogCol.rgb , light.color , VoL);
				#endif

				//return half4(VoL.xxx , 1);
				return fogCol;
				}
			ENDHLSL
			}
		}
}
