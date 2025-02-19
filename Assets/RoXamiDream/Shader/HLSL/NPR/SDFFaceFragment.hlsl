#include_with_pragmas "../ToonLit/ToonLitBRDF.hlsl"

	TEXTURE2D(_BaseMap);
	SAMPLER(sampler_BaseMap);

half4 frag(Varyings IN) : SV_Target {
				UNITY_SETUP_INSTANCE_ID(IN);

				//Map
				half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
				half3 normal = normalize(IN.normalWS);

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

				return half4( col , 1);
			}