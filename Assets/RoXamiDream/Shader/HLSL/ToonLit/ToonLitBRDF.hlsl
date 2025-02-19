#ifndef ToonLitBRDF_INCLUDED
#define ToonLitBRDF_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _SHADOWS_SOFT
#pragma multi_compile_fog

#pragma shader_feature_local _ISRAMPMAP_ON
#pragma shader_feature_local _ISLIGHTMAP_ON


#if defined(_ISBRUSH_ON)
	TEXTURE2D(_BrushMap);
    SAMPLER(sampler_BrushMap);
#endif

#if defined(_ISRAMPMAP_ON)
    Texture2D<float4> _RampMap;
#endif

#if defined(_ISSPECMAP_ON)
    TEXTURE2D(_SpecMap);
    SAMPLER(sampler_SpecMap);
#endif

#if defined(_ISLIGHTMAP_ON)
	TEXTURE2D(_LightMap);
	SAMPLER(sampler_LightMap);
#endif

#define linear_F0 0.08

struct PBR
{
    half3 albedo;
    half3 normal;
    half ao;
    half roughness;
    half metallic;
    half3 emissive;
};
//=================================================Math Function=============================================================
half LinearStep(half minValue, half maxValue, half In)
{
    return saturate((In-minValue) / (maxValue - minValue));
}

half LinearStep_Max(half minValue, half maxValue, half In)
{
    return max(0 , (In-minValue) / (maxValue - minValue));
}

//====================================================BRDF Function=============================================================
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

half3 GGX_Spec (half HoL , half NoH , half3 F0 ,  half roughness)
{
    half roughness2 = pow(roughness , 2);
    half HoL2 = pow(HoL , 2);
    half d = NoH * NoH * (roughness2 - 1) + 1.00001f;
    half nor = roughness * 4 + 2;
    half Spec = roughness2 / ((d * d) * max(0.1 , HoL2) * nor);

    half3 SpecCol = half3(0,0,0);
#if defined(_ISRAMPMAP_ON)
    Spec = LinearStep(_specMin , _specMax, Spec);
    SpecCol = _RampMap.Load(int3(Spec * 255 , 4 , 0)).xyz; 
#else
    Spec = LinearStep_Max(_specMin , _specMax, Spec);
    SpecCol = _specColor * Spec;
#endif
    return F0 * SpecCol;
}

half3 Fresnel_Light (half HoL, half3 F0)
{
    half fresnel = exp2((-5.55473 * HoL - 6.98316) * HoL);
    return lerp(fresnel, 1.0, F0);
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

half3 Fresnel_InLight (half NoV, half roughness, half3 F0)
{
    //half fresnel = exp2((-5.55473 * NdotV - 6.98316) * NdotV);   
    half fresnel = LinearStep(_inSpecMin, _inSpecMax, 1 - NoV);//Toon
    half3 fresnelCol = half3(0,0,0);
#if defined(_ISRAMPMAP_ON)
    fresnelCol = _RampMap.Load(int3(fresnel * 255 , 8 , 0)).xyz;
    fresnelCol = F0 + fresnelCol * saturate(1 - roughness - F0);
#else
    fresnel = pow(fresnel * 2 , 2);
    fresnelCol = F0 + fresnel * saturate(1 - roughness - F0);
#endif
    return fresnelCol;
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

//===================================================NPR Function===========================================================
half3 DirectSpec_Hair(half NoH , half2 uv1 , half3 viewDir)
{
    half3 specHair = LinearStep(_specMin , _specMax, NoH);
#if defined(_ISSPECMAP_ON)
    specHair *= SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, uv1 + half2(0, -viewDir.y * 0.1 + 1)).rgb;
#endif
    return specHair;
}

half SDF_LightShadow(half isFront , half lightShadow)
{
    half sdf = saturate((lightShadow - 0.5) * 2 + isFront);
    return sdf;
}

#ifdef _ISDEPTHRIM_ON
half DepthRimLight(half2 screenSpaceUV , half3 normal , half positionCS_W)
{
    half3 normalVS = TransformWorldToViewDir(normal, true);
    half2 signDir = normalVS.xy;
    half2 OffestSamplePos = screenSpaceUV + _rimOffest / positionCS_W * signDir;
    half OffsetDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture , OffestSamplePos).r;
    half Depth = SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture , screenSpaceUV).r;
    //Rim
    half Linear01EyeOffectDepth = Linear01Depth(OffsetDepth , _ZBufferParams);
    half Linear01EyeDepth = Linear01Depth(Depth , _ZBufferParams);
    half DepthDiffer = Linear01EyeOffectDepth - Linear01EyeDepth;
    half Rim = step(_threshold * 0.001, DepthDiffer);
    return Rim;
}
#endif

//==================================================Direct InDirect Function================================================
half3 DirectionalLight (half HoL , half NoL , half NoV , half NoH , half3 albedo , half roughness , half metallic , half3 F0 , half3 lightColor , half2 uv1 , half3 viewDir)
{ 
    half3 Ks = Fresnel_Light(HoL, F0);
    half3 Kd = saturate((1 - Ks)) * (1 - metallic);

    half3 diffuseCol = half3(0, 0, 0);
#if defined(_ISRAMPMAP_ON)
    diffuseCol = _RampMap.Load(int3(NoL * 255 , 0 , 0)).xyz; 
#else
    diffuseCol = lerp(_shadowColor , _lightColor , NoL);
#endif
    
    //BRDF
    half3 BRDFSpec = half3(0,0,0);
#if defined(_ISSPECMAP_ON)
    BRDFSpec = DirectSpec_Hair(NoH , uv1 , viewDir);
#else 
    BRDFSpec = GGX_Spec(HoL , NoH , F0 , roughness);
    //BRDFSpec = d * g * f / (4 * NoL * NoV);
#endif

    return (Kd * albedo * diffuseCol + BRDFSpec * NoL) * lightColor;
    //return BRDFSpec;
}

half3 InDirectionalLight(half NoV , half3 normalWS, half3 viewWS , half3 albedo , half metallic , half roughness, half occlusion, half3 F0)
{
    half3 SHColor = unity_SampleSH(normalWS);
    half3 Ks = Fresnel_InLight(NoV, roughness, F0);
    half3 Kd = saturate((1 - Ks)) * (1 - metallic);
    half3 InDiffuse = SHColor * Kd * albedo;
    
    half3 F_IndirectionLight = Ks;
    half3 SpecCubecolor = SpecCube_InLignt(normalWS, viewWS, roughness);
    half2 LUT = LUT_Approx(roughness, NoV);
    half3 InSpec = SpecCubecolor * (F_IndirectionLight * LUT.r + LUT.g);
#if defined(_ISRAMPMAP_ON)
#else
    InSpec *= _inSpecColor;
#endif
    return (InDiffuse + InSpec) * occlusion;
    //return InSpec;
}

//=====================================================Combine Function======================================================
half3 PBR_Result(half3 positionWS , half3 viewDir, half2 screenSpaceUV , half4 positionCS , half2 uv , half2 uv1 , PBR pbr)
{
    half3 albedo = pbr.albedo;
    half3 normalDir = pbr.normal;
    half occlusion = pbr.ao;
    half roughness = LinearStep( 0.003 , 1 , pbr.roughness);
    half metallic = pbr.metallic;
    half3 emission = pbr.emissive;

    half4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light light = GetMainLight(shadowCoord);

    half3 lightColor = light.color;
    half3 lightDir = normalize(light.direction);
    half3 brush = half3(0,0,0);
    
    half3 halfDir = SafeNormalize(viewDir + lightDir);
    half NoH = max(saturate(dot(normalDir, halfDir)), 0.0001);
    half NoL = (dot(normalDir, lightDir) + 1) * 0.5;//Toon
    half NoV = max(saturate(dot(normalDir, viewDir)), 0.01);
    half HoV = max(saturate(dot(viewDir, lightDir)), 0.0001);
    half HoL = max(saturate(dot(halfDir, lightDir)), 0.0001);

#ifdef _ISRECEIVETOONSHADOW_ON
    NoL *= light.shadowAttenuation;
#endif

#ifdef _ISLIGHTMAP_ON
    half4 rightLightShadow = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, uv1);
    half4 leftLightShadow = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, half2(1 - uv1.x , uv1.y));
    half2 rightDir_XZ = normalize(half2(1,0));
    half2 lightDir_XZ = normalize(lightDir.xz);
    half2 frontDir_XZ = normalize(half2(0,1));
    half isFront = dot(lightDir_XZ , frontDir_XZ);
    half isRight = dot(lightDir.xz , rightDir_XZ);
    half4 sdf_LightShadow = isRight > 0 ? rightLightShadow : leftLightShadow;
    NoL = SDF_LightShadow(isFront , sdf_LightShadow.r) * sdf_LightShadow.a;
    NoH = SDF_LightShadow(isFront , sdf_LightShadow.g) + SDF_LightShadow(isFront , sdf_LightShadow.b);
    //NoH *= 0.5;
#endif

#ifdef _ISBRUSH_ON
	brush = SAMPLE_TEXTURE2D(_BrushMap, sampler_BrushMap, uv *  _brushTransform.xy +  _brushTransform.zw).rgb;
    NoL = NoL * lerp(0.5 , brush.r ,  _brushStrength.x) + 0.5;
    NoH = HoL * lerp(0.5 , brush ,  _brushStrength.y) + 0.5;
    NoV = NoV * lerp(0.5 , brush ,  _brushStrength.z) + 0.5;  
#endif 

    NoL = LinearStep(_diffuseMin , _diffuseMax, NoL);//Toon
    NoL = max(0.01 , NoL);
    half3 F0 = lerp(linear_F0, albedo, metallic);

    half3 depthRim = half3(0,0,0);
#ifdef _ISDEPTHRIM_ON
    depthRim = DepthRimLight(screenSpaceUV , normal , positionCS.w);
#endif
    
    return
    DirectionalLight(HoL, NoL, NoV, NoH, albedo, roughness, metallic, F0 , lightColor, uv1 , viewDir)
    + InDirectionalLight(NoV, normalDir, viewDir, albedo, metallic, roughness, occlusion , F0)
    + depthRim
    + emission;
    //return depthRim;
}

#define PBR_Result(IN , pbr) PBR_Result(IN.positionWS , IN.viewWS , IN.normalizedScreenSpaceUV , IN.positionCS , IN.uv , IN.uv1 , pbr);
#endif