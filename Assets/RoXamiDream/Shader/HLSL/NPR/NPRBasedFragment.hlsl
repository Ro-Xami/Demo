#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include_with_pragmas "NPRBasedFragInput.hlsl"

#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _SHADOWS_SOFT
#pragma multi_compile_fog


	TEXTURE2D(_BaseMap);
	SAMPLER(sampler_BaseMap);
#if defined(_ISNORMALMAP_ON)
	TEXTURE2D(_NormalMap);
	SAMPLER(sampler_NormalMap);
#endif

#if defined(_ISARMMAP_ON)
	TEXTURE2D(_MaskMap);
	SAMPLER(sampler_MaskMap);
#endif

#if defined(_ISEMISSIONMAP_ON)
	TEXTURE2D(_EmissionMap);
	SAMPLER(sampler_EmissionMap);
#endif

half4 frag(Varyings IN) : SV_Target {
				UNITY_SETUP_INSTANCE_ID(IN);

				//Map
				half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

				half3 normal = normalize(IN.normalWS);
#ifdef _ISNORMALMAP_ON
				half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv);
				half3x3 TBN = {IN.tangentWS.xyz, IN.bitangentWS.xyz, IN.normalWS.xyz};
                TBN = transpose(TBN);
                half3 norTS = UnpackNormalScale(normalMap, _normalStrength);
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));
                normal = NormalizeNormalPerPixel(mul(TBN, norTS));
#else
#endif
				half3 mask = half3(1,1,1);
#ifdef _ISARMMAP_ON
				mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, IN.uv).rgb;
#else
#endif
				half3 emissive = half3(1,1,1);
#ifdef _ISEMISSIONMAP_ON
				emissive = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, IN.uv).rgb;
#else
#endif
				//pbrData
				half ao = mask.b * _ao;
				half roughness = mask.r * _roughness;
				half metallic = mask.b * _metallic;
				emissive *= _emissionColor; 
				
				//pbrInput
				PBR pbr;
				pbr.albedo = albedo.rgb;
				pbr.normal = normal;
				pbr.ao = ao;
				pbr.roughness = roughness;
				pbr.metallic = metallic;
				pbr.emissive = emissive;

				half3 col = PBR_Result(IN , pbr);

				col = MixFog(col,IN.fogCoord);

#ifdef _ISALPHACLIP_ON
				clip(albedo.a - _cutOut);
#else
#endif
				return half4( col , albedo.a);
			}