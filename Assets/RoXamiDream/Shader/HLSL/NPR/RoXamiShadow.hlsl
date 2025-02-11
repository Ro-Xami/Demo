float3 GetStyleShadow(float4 ShadowCoord , float shadowOffset)
{
	float shadowR = MainLightRealtimeShadow(ShadowCoord + float4(shadowOffset , 0 , 0 , 0));
	float shadowG = MainLightRealtimeShadow(ShadowCoord + float4(0 , shadowOffset , 0 , 0));
	float shadowB = MainLightRealtimeShadow(ShadowCoord + float4(0 , 0 , shadowOffset , 0));

	return float3(shadowR , shadowG , shadowB); 
}