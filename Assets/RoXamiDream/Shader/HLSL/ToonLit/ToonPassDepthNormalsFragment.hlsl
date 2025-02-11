#if defined(_ISALPHACLIP_ON)
	TEXTURE2D(_BaseMap);
	SAMPLER(sampler_BaseMap);
#endif

#if defined(_ISNORMALMAP_ON)
	TEXTURE2D(_NormalMap);
	SAMPLER(sampler_NormalMap);
#endif

            half4 frag(Varyings IN) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(IN);

				half3 normal = IN.normalWS;
#ifdef _ISNORMALMAP_ON
				half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv);
				half3x3 TBN = {IN.tangentWS.xyz, IN.bitangentWS.xyz, IN.normalWS.xyz};
                TBN = transpose(TBN);
                half3 norTS = UnpackNormalScale(normalMap, _normalStrength);
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));
                normal = NormalizeNormalPerPixel(mul(TBN, norTS));
#else
#endif

#ifdef _ISALPHACLIP_ON
				half albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).a;
				clip(albedo - _cutOut);
#else
#endif

                return half4(NormalizeNormalPerPixel(normal), 0.0);
            }