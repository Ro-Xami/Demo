float3 TransformVertices(Texture2D<float4> VerticesAnimTex , float3 pos , float2 uv , float frameIndex)
{
	float3 vertexOffest = VerticesAnimTex.Load(int3(uv.x , frameIndex , 0)).xyz;
	return pos + vertexOffest;
}

float3 TransformNormals(Texture2D<float4> VerticesAnimTex , float2 uv , float frameIndex)
{
    return VerticesAnimTex.Load(int3(uv.x + 1, frameIndex, 0)).xyz;
}

float4 TransformTangents(Texture2D<float4> VerticesAnimTex , float2 uv , float frameIndex)
{
	return VerticesAnimTex.Load(int3(uv.x + 2 , frameIndex , 0));
}

