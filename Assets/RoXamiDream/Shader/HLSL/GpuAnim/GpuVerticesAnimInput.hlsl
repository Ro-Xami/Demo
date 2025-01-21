float3 TransformVertices(float3 pos , float2 uv , float frameIndex)
{
	float3 vertexOffest = SAMPLE_TEXTURE2D_LOD(_verticesAnimTex, sampler_verticesAnimTex, uv + float2(0 ,frameIndex), 0).xyz;
	return pos + vertexOffest;
}

float3 TransformNormals(float2 uv , float frameIndex , float animationPixelLength)
{
	return SAMPLE_TEXTURE2D_LOD(_verticesAnimTex, sampler_verticesAnimTex, uv + float2(0 ,animationPixelLength + frameIndex), 0).xyz;
}

float4 TransformTangents(float2 uv , float frameIndex , float animationPixelLength)
{
	return SAMPLE_TEXTURE2D_LOD(_verticesAnimTex, sampler_verticesAnimTex, uv + float2(0 ,animationPixelLength * 2 + frameIndex), 0);
}

