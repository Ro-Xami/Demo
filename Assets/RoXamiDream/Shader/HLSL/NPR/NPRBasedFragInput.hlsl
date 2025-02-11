#ifndef NPRBasedFragInput_INCLUDED
#define NPRBasedFragInput_INCLUDED

#if defined(_ISBRUSH_ON)
	TEXTURE2D(_brush);
    SAMPLER(sampler_brush);
#endif

#define linear_f0 0.08

struct PBR
{
    half3 albedo;
    half3 normal;
    half ao;
    half roughness;
    half metallic;
    half3 emissive;
};
//MathFunction
half LinearStep(half minValue, half maxValue, half In)
{
    return saturate((In-minValue) / (maxValue - minValue));
}

half LinearStep_Max(half minValue, half maxValue, half In)
{
    return max(0 , (In-minValue) / (maxValue - minValue));
}

half Distribution (half NoH , half roughness)
{
    half roughness2 = pow(roughness, 2);
    return roughness2 / (3.141592654 * pow(pow(NoH, 2) * (roughness2 - 1) + 1, 2));
    //return NoH * NoH * roughness2 + 1;
}

half Sub_Geometry (half DotTerm , half k)
{
    return DotTerm / lerp(DotTerm, 1, k);
}

half Combine_Geometry (half NoL , half NoV , half roughness)
{
    half k = pow((1.0 + roughness), 2) / 0.5;
    return Sub_Geometry(NoL, k) * Sub_Geometry(NoV, k);
}

half3 Fresnel_Light (half HoL, half3 F0)
{
    half fresnel = exp2((-5.55473 * HoL - 6.98316) * HoL);
    return lerp(fresnel, 1.0, F0);
}

half3 GGX_Spec (half HoL , half NoH , half3 F0 ,  half roughness , half brush)
{
    half roughness2 = pow(roughness , 2);
    half HoL2 = pow(HoL , 2);
    half d = NoH * NoH * (roughness2 - 1) + 1.00001f;
    half nor = roughness * 4 + 2;
    half Spec = roughness2 / ((d * d) * max(0.1 , HoL2) * nor);

#ifdef _ISBRUSH_ON
	Spec = Spec * lerp(0.5 , brush , _brushStrength.y) + 0.5;//ToonBrush
#else
#endif 
    
    Spec = LinearStep_Max(_specMin , _specMax, Spec);//Toon
    return Spec * F0 * _specColor;
}

half3 unity_SampleSH(half3 normalWS)
{
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;
    return max(half3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
}

half3 Fresnel_InLight (half NoV, half roughness, half3 F0 , half brush)
{
    //half fresnel = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
#ifdef _ISBRUSH_ON
	NoV = NoV * lerp(0.5 , brush , _brushStrength.z) + 0.5;//ToonBrush
#else
#endif 
    
    half fresnel = LinearStep(_inSpecMin, _inSpecMax, 1 - NoV);//Toon
    fresnel = pow(fresnel * 2 , 2);
    return F0 + fresnel * saturate(1 - roughness - F0);
}

real3 SpecCube_InLignt(half3 normalWS, half3 viewWS, half roughness)
{
    half mip = PerceptualRoughnessToMipmapLevel(roughness);
    half3 reflectDir = reflect(-viewWS, normalWS);
    half4 indirectionCube = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
    return DecodeHDREnvironment(indirectionCube, unity_SpecCube0_HDR);
}

half2 LUT_Approx (half roughness, half NoV)
{
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = roughness * c0 + c1;
    half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    return saturate(AB);
}

half3 DirectionalLight (half HoL , half NoL , half NoV , half NoH , half3 albedo , half roughness , half metallic , half3 F0 , half3 lightColor , half shadow , half brush)
{ 
    half3 Ks = Fresnel_Light(HoL, F0);
    half3 Kd = saturate((1 - Ks)) * (1 - metallic);
    //half3 BRDFSpec = (Distribution(NoH, roughness) * Combine_Geometry(NoL, NoV, roughness) * Fresnel_Light(HoL, F0)) / (4 * NoL * NoV);
    half3 BRDFSpec = GGX_Spec(HoL , NoH , F0 , roughness , brush);
    NoL *= shadow;
    half3 diffuseCol = lerp(_shadowColor , _lightColor , NoL);
    return (Kd * albedo * diffuseCol + BRDFSpec * NoL) * lightColor;
    //return diffuseColor;
}

half3 InDirectionalLight(half NoV , half3 normalWS, half3 viewWS , half3 albedo , half metallic , half roughness, half occlusion, half3 F0 , half brush)
{
    half3 SHColor = unity_SampleSH(normalWS);
    half3 Ks = Fresnel_InLight(NoV, roughness, F0 , brush);
    half3 Kd = saturate((1 - Ks)) * (1 - metallic);
    half3 InDiffuse = SHColor * Kd * albedo;
    
    half3 F_IndirectionLight = Ks;
    half3 SpecCubecolor = SpecCube_InLignt(normalWS, viewWS, roughness);
    half2 LUT = LUT_Approx(roughness, NoV);
    half3 InSpec = SpecCubecolor * (F_IndirectionLight * LUT.r + LUT.g);
    InSpec *= _inSpecColor;
    return (InDiffuse + InSpec) * occlusion;
    //return InSpec;
}

half3 PBR_Result(half3 positionWS , half3 viewDir, half2 uv , PBR pbr)
{
    half3 albedo = pbr.albedo;
    half3 normalDir = pbr.normal;
    half occlusion = pbr.ao;
    half roughness = LinearStep( 0.003 , 1 , pbr.roughness);
    half metallic = pbr.metallic;
    half3 emission = pbr.emissive;


    half4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light light = GetMainLight(shadowCoord);
    half shadow = 1;
#ifdef _ISRECEIVETOONSHADOW_ON
    shadow = light.shadowAttenuation;
#else
#endif
    half3 lightColor = light.color;
    half3 lightDir = normalize(light.direction);
    half3 brush = half3(0,0,0);   
    
    half3 halfDir = SafeNormalize(viewDir + lightDir);
    half NoH = max(saturate(dot(normalDir, halfDir)), 0.0001);
    half NoL = (dot(normalDir, lightDir) + 1) * 0.5;//Toon
    //half NoL = max(dot(normalDir, lightDir) , 0.01); 
    half NoV = max(saturate(dot(normalDir, viewDir)), 0.01);
    half HoV = max(saturate(dot(viewDir, lightDir)), 0.0001);
    half HoL = max(saturate(dot(halfDir, lightDir)), 0.0001);

#ifdef _ISBRUSH_ON
	brush = SAMPLE_TEXTURE2D(_brush, sampler_brush, uv * _brushTransform.xy + _brushTransform.zw).rgb;
    NoL = NoL * lerp(0.5 , brush.r , _brushStrength.x) + 0.5;//ToonBrush
#else
#endif   

    NoL = LinearStep(_diffuseMin , _diffuseMax, NoL);//Toon
    NoL = max(0.01 , NoL);
    half3 F0 = lerp(linear_f0, albedo, metallic);
    
    return
    DirectionalLight(HoL, NoL, NoV, NoH, albedo, roughness, metallic, F0 , lightColor, shadow , brush.g) +
        InDirectionalLight(NoV, normalDir, viewDir, albedo, metallic, roughness, occlusion , F0 , brush.g) +
            emission;
    //return
    //    InDirectionalLight(NoV, normalDir, viewDir, albedo, metallic, roughness, occlusion , F0 , brush.g);
}

#define PBR_Result(IN , pbr) PBR_Result(IN.positionWS , IN.viewWS , IN.uv , pbr);
#endif