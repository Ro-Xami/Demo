#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
#if defined(SHADER_API_GLCORE) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_PSSL) || defined(SHADER_API_XBOXONE)
// 表示外部将会给shader设置一个实例数据缓冲区，内部是要渲染的一系列实例数据
//StructuredBuffer<float4x4> IndirectShaderDataBuffer;
struct gpuAnimationBufferData
{
	float4x4 trsMatrix_World;
	float4 animationPlayedData;
};
StructuredBuffer<gpuAnimationBufferData> gpuBufferData;
#endif	
#endif
// inverse函数的作用是返回输入矩阵的逆矩阵
float4x4 inverse(float4x4 input)
{
#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))

	float4x4 cofactors = float4x4(
		minor(_22_23_24, _32_33_34, _42_43_44),
		-minor(_21_23_24, _31_33_34, _41_43_44),
		minor(_21_22_24, _31_32_34, _41_42_44),
		-minor(_21_22_23, _31_32_33, _41_42_43),

		-minor(_12_13_14, _32_33_34, _42_43_44),
		minor(_11_13_14, _31_33_34, _41_43_44),
		-minor(_11_12_14, _31_32_34, _41_42_44),
		minor(_11_12_13, _31_32_33, _41_42_43),

		minor(_12_13_14, _22_23_24, _42_43_44),
		-minor(_11_13_14, _21_23_24, _41_43_44),
		minor(_11_12_14, _21_22_24, _41_42_44),
		-minor(_11_12_13, _21_22_23, _41_42_43),

		-minor(_12_13_14, _22_23_24, _32_33_34),
		minor(_11_13_14, _21_23_24, _31_33_34),
		-minor(_11_12_14, _21_22_24, _31_32_34),
		minor(_11_12_13, _21_22_23, _31_32_33)
		);
#undef minor
	return transpose(cofactors) / determinant(input);
}

// setup函数作用是给每个实例数据在渲染前得到实际矩阵和逆矩阵，相当于每个实例数据的初始化操作。
void setup()
{
#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
	unity_ObjectToWorld = gpuBufferData[unity_InstanceID].trsMatrix_World;
	unity_WorldToObject = inverse(unity_ObjectToWorld);
	_animationPlayedData = gpuBufferData[unity_InstanceID].animationPlayedData;
#endif
}
