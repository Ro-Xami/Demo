float3 TransformVertices(float3 pos , float2 uv , float frameIndex , float texHeight)
{
	float3 vertexOffest = SAMPLE_TEXTURE2D_LOD(_verticesAnimTex, sampler_verticesAnimTex, uv + float2(0 ,frameIndex / texHeight), 0).xyz;
	return pos + vertexOffest;
}

float3 TransformNormals(float2 uv , float frameIndex , float texWidth , float texHeight)
{
	return SAMPLE_TEXTURE2D_LOD(_verticesAnimTex, sampler_verticesAnimTex, uv + float2(1 / texWidth , frameIndex / texHeight), 0).xyz;
}

float4 TransformTangents(float2 uv , float frameIndex , float texWidth , float texHeight)
{
	return SAMPLE_TEXTURE2D_LOD(_verticesAnimTex, sampler_verticesAnimTex, uv + float2(2 / texWidth , frameIndex / texHeight), 0);
}

