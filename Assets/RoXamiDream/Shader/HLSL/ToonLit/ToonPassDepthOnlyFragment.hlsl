#if defined(_ISALPHACLIP_ON)
	TEXTURE2D(_baseMap);
	SAMPLER(sampler_baseMap);
#endif
            half4 frag(Varyings IN) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(IN);

#ifdef _ISALPHACLIP_ON
				half albedo = SAMPLE_TEXTURE2D(_baseMap, sampler_baseMap, IN.uv).a;
				clip(albedo - _cutOut);
#else
#endif

                return IN.positionCS.z;
            }