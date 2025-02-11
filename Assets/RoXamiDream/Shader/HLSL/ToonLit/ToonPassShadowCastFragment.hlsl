#if defined(_ISALPHACLIP_ON)
	TEXTURE2D(_BaseMap);
	SAMPLER(sampler_BaseMap);
#endif

            real4 frag(Varyings IN) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(IN);

#ifdef _ISALPHACLIP_ON
				half albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).a;
				clip(albedo - _cutOut);
#else
#endif
                return 0;
            }