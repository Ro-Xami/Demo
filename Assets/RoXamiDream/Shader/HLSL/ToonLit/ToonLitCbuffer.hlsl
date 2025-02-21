half4 _BaseColor;
half4 _BaseMap_ST;
half _normalStrength;
half _ao;
half _roughness;
half _metallic;
half3 _emissionColor;
half3 _lightColor;
half3 _shadowColor;
half _diffuseMin;
half _diffuseMax;
half _specMin;
half _specMax;
half3 _specColor;
half _inSpecMin;
half _inSpecMax;
half3 _inSpecColor;

#ifdef _ISBRUSH_ON
half4 _brushStrength;
half4 _brushTransform;
#endif 

#ifdef _ISALPHACLIP_ON
half _cutOut;
#endif

#ifdef _ISDEPTHRIM_ON
half4 _rimColor;
half _rimOffest;
half _threshold;
#endif

#ifdef _ISLIGHTMAP_ON
half2 _forntDir;
half2 _righDir;
#endif