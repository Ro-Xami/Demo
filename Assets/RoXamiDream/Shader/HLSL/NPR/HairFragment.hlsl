#include_with_pragmas "../ToonLit/ToonLitBRDF.hlsl"

	TEXTURE2D(_BaseMap);
	SAMPLER(sampler_BaseMap);
#if defined(_ISNORMALMAP_ON)
	TEXTURE2D(_NormalMap);
	SAMPLER(sampler_NormalMap);
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
				//pbrInput
				PBR pbr;
				pbr.albedo = albedo.rgb;
				pbr.normal = normal;
				pbr.ao = 1;
				pbr.roughness = _roughness;
				pbr.metallic = 0;
				pbr.emissive = 0;

				half3 col = PBR_Result(IN , pbr);

				col = MixFog(col,IN.fogCoord);

				return half4( col.rgb , 1);
			}