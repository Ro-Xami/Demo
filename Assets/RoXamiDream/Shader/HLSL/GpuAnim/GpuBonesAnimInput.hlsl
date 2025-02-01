#ifndef GpuBonesAnimInput_INCLUDED
#define GpuBonesAnimInput_INCLUDED

float4 GetBoneAnimationMatrix(Texture2D<float4> tex , float boneIndex , float matrixRowID , float frameIndex)
{
    return tex.Load(int3(boneIndex + matrixRowID , frameIndex, 0));
}

float3 blendData(float3 a, float3 b, float c)
{
    return a + c * (b - a);
}

half4x4 extractRotationMatrix(half4x4 m)
{
    half sx = length(half3(m[0][0], m[0][1], m[0][2]));
    half sy = length(half3(m[1][0], m[1][1], m[1][2]));
    half sz = length(half3(m[2][0], m[2][1], m[2][2]));

    // if determine is negative, we need to invert one scale
    half det = determinant(m);
    if (det < 0)
    {
        sx = -sx;
    }

    half invSX = 1.0 / sx;
    half invSY = 1.0 / sy;
    half invSZ = 1.0 / sz;

    m[0][0] *= invSX;
    m[0][1] *= invSX;
    m[0][2] *= invSX;
    m[0][3] = 0;

    m[1][0] *= invSY;
    m[1][1] *= invSY;
    m[1][2] *= invSY;
    m[1][3] = 0;

    m[2][0] *= invSZ;
    m[2][1] *= invSZ;
    m[2][2] *= invSZ;
    m[2][3] = 0;

    m[3][0] = 0;
    m[3][1] = 0;
    m[3][2] = 0;
    m[3][3] = 1;

    return m;
}

void ComputeGpuBonesAnimation(Texture2D<float4> tex, float3 positionInput, float4 uv, float3 vertColor, float frameIndex, out float3 positionOutput)
{
    float weights[4] = { vertColor.x, vertColor.y, vertColor.z, (1 - vertColor.x - vertColor.y - vertColor.z) };
    float bones[4] = { uv.x, uv.y, uv.z, uv.w };
    positionOutput = float3(0, 0, 0);
    
    for (int i = 0; i < 4; i++)
    {
        if (weights[i] != 0)
        {

            float4 row0 = GetBoneAnimationMatrix(tex, bones[i], 0, frameIndex);
            float4 row1 = GetBoneAnimationMatrix(tex, bones[i], 1, frameIndex);
            float4 row2 = GetBoneAnimationMatrix(tex, bones[i], 2, frameIndex);
            float4 row3 = float4(0, 0, 0, 1);

            float4x4 boneMatrix = float4x4(row0, row1, row2, row3);
            positionOutput += weights[i] * mul(boneMatrix, float4(positionInput, 1)).xyz;
        }
    }
}

void ComputeGpuBonesAnimation(Texture2D<float4> tex, float3 positionInput, float3 normalInput , float4 tangentInput ,
                            float4 uv, float3 vertColor, float frameIndex,
                            out float3 positionOutput , out float3 normalOutput , out float4 tangentOutput)
{
    float weights[4] = { vertColor.x, vertColor.y, vertColor.z, (1 - vertColor.x - vertColor.y - vertColor.z) };
    float bones[4] = { uv.x, uv.y, uv.z, uv.w };
    positionOutput = float3(0, 0, 0);
    normalOutput = float3(0, 0, 0);
    tangentOutput = float4(0, 0, 0, 0);
    
    for (int i = 0; i < 4; i++)
    {
        if (weights[i] != 0)
        {
            float4 row0 = GetBoneAnimationMatrix(tex, bones[i], 0, frameIndex);
            float4 row1 = GetBoneAnimationMatrix(tex, bones[i], 1, frameIndex);
            float4 row2 = GetBoneAnimationMatrix(tex, bones[i], 2, frameIndex);
            float4 row3 = float4(0, 0, 0, 1);

            float4x4 boneMatrix = float4x4(row0, row1, row2, row3);
            float4x4 rotateMatrix = extractRotationMatrix(boneMatrix);
            
            positionOutput += weights[i] * mul(boneMatrix, float4(positionInput, 1)).xyz;
            normalOutput += weights[i] * mul(rotateMatrix, float4(normalInput, 1)).xyz;
            tangentOutput += weights[i] * mul(rotateMatrix, float4(tangentInput));
        }
    }
}

void ComputeGpuBonesAnimationBlend(Texture2D<float4> tex, float3 positionInput,
                            float4 uv, float3 vertColor, float4 animationPlayedData,
                            out float3 positionOutput)
{
    float frameIndex = animationPlayedData.x;
    float frameLastIndex = animationPlayedData.y;
    float blend = animationPlayedData.z;
    
    if (blend > 0 && 1 > blend)
    {
        float3 positionLast = float3(0, 0, 0);
        float3 positionPreview = float3(0, 0, 0);
        
        ComputeGpuBonesAnimation(tex, positionInput
							    , uv, vertColor, frameLastIndex
							    , positionLast);
        ComputeGpuBonesAnimation(tex, positionInput
							    , uv, vertColor, frameIndex
							    , positionPreview);
        positionOutput = blendData(positionLast, positionPreview, blend);
    }
    else
    {
        ComputeGpuBonesAnimation(tex, positionInput
							    , uv, vertColor, frameIndex
							    , positionOutput);
    }
}

void ComputeGpuBonesAnimationBlend(Texture2D<float4> tex, float3 positionInput, float3 normalInput, float4 tangentInput,
                            float4 uv, float3 vertColor, float4 animationPlayedData,
                            out float3 positionOutput, out float3 normalOutput, out float4 tangentOutput)
{
    float frameIndex = animationPlayedData.x;
    float frameLastIndex = animationPlayedData.y;
    float blend = animationPlayedData.z;
    
    if (blend > 0 && 1 > blend)
    {
        float3 positionLast = float3(0, 0, 0);
        float3 positionPreview = float3(0, 0, 0);
        float3 normalLast = float3(0, 0, 0);
        float3 normalPreview = float3(0, 0, 0);
        float4 tangentLast = float4(0, 0, 0, 0);
        float4 tangentPreview = float4(0, 0, 0, 0);
        
        ComputeGpuBonesAnimation(tex, positionInput, normalInput, tangentInput
							    , uv, vertColor, frameLastIndex
							    , positionLast, normalLast, tangentLast);
        ComputeGpuBonesAnimation(tex, positionInput, normalInput, tangentInput
							    , uv, vertColor, frameIndex
							    , positionPreview, normalPreview, tangentPreview);
        positionOutput = blendData(positionLast, positionPreview, blend);
        normalOutput = blendData(normalLast, normalPreview, blend);
        tangentOutput.xyz = blendData(tangentLast.xyz, tangentPreview.xyz, blend);

    }
    else
    {
        ComputeGpuBonesAnimation(tex, positionInput, normalInput, tangentInput
							    , uv, vertColor, frameIndex
							    , positionOutput, normalOutput, tangentOutput);
    }
    tangentOutput.w = tangentInput.w;
}
#endif