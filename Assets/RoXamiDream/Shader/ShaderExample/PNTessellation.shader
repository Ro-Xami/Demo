Shader "RoXami/Example/PNTessellation" {
	Properties {
		[Header(Tess)]
        [KeywordEnum(integer, fractional_even, fractional_odd)]_Partitioning ("Partitioning Mode", Float) = 0
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        _EdgeFactor ("EdgeFactor", Range(1,8)) = 4 
        _InsideFactor ("InsideFactor", Range(1,8)) = 4 
	}
	SubShader {
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
			CBUFFER_START(UnityPerMaterial)

			float _EdgeFactor; 
            float _InsideFactor; 

			CBUFFER_END
		ENDHLSL

		Pass {
			Tags { "LightMode"="UniversalForward" }
 
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6

			//外壳着色器（常量外壳着色器；控制点外壳着色器）
			#pragma hull FlatTessControlPoint

			//-----------Tessellator 镶嵌着色器（不可编程）

			//域着色器(用于计算顶点信息)
            #pragma domain FlatTessDomain

			#pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD 
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 
			

 
			struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 uv : TEXCOORD0;
			};
 
			struct Varyings {
				float4 positionOS : INTERALTESSPOS;
				float2 uv : TEXCOORD0;
				float3 normalOS : TEXCOORD1;
			};

			//三角面片
			struct PatchTess {
				float edgeFactor[3] : SV_TESSFACTOR;		//边缘细分因子
				float insideFactor : SV_INSIDETESSFACTOR;	//内部细分因子
			};

			// 四角面片
			//struct PatchTess {  
			//	float edgeFactor[4] : SV_TESSFACTOR; // 分别对应四角面片的四个边
			//	float insideFactor[2]  : SV_INSIDETESSFACTOR; // 分别对应内部细分的列数与行数
			//};

			struct HullOut {
				float3 positionOS : INTERNALTESSPOS;
				float2 uv : TEXCOORD0;
				float3 normalOS : TEXCOORD1;
			};

			struct DomainOut {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normalWS : TEXCOORD1;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				OUT.positionOS = IN.positionOS;
				OUT.uv = IN.uv;

				return OUT;
			}

			//-----------------------------------------------------常量外壳着色器------------------------------------------------------
			PatchTess PatchConstant(InputPatch<Varyings,3> IN, uint patchID : SV_PrimitiveID)
			{
				//InputPatch<Varyings,3>顶点着色器的输出结构体，三角形顶点数为3
				//SV_PrimitiveID 传入的面片ID值
				PatchTess OUT;
				OUT.edgeFactor[0] = _EdgeFactor;
				OUT.edgeFactor[1] = _EdgeFactor;
				OUT.edgeFactor[2] = _EdgeFactor;
				OUT.insideFactor = _InsideFactor;

				return OUT;
			}
			
			//--------------------------------------------------------------------------------------------------------------
			//面片类型：三角形，四边形，等值线
			[domain("tri")]

			//曲面细分模式：取整数部分，向上取偶数部分，向上取奇数部分
            #if _PARTITIONING_INTEGER
            [partitioning("integer")]
            #elif _PARTITIONING_FRACTIONAL_EVEN
            [partitioning("fractional_even")] 
            #elif _PARTITIONING_FRACTIONAL_ODD
            [partitioning("fractional_odd")]    
            #endif 

			//细分创建三角形绕序：顺时针，逆时针
            #if _OUTPUTTOPOLOGY_TRIANGLE_CW
            [outputtopology("triangle_cw")] 
            #elif _OUTPUTTOPOLOGY_TRIANGLE_CCW
            [outputtopology("triangle_ccw")] 
            #endif

			//指定常量外壳着色器的函数名
            [patchconstantfunc("PatchConstant")] 
			//外壳着色器的执行次数
            [outputcontrolpoints(3)]
			//最大细分因子（最大64）
            [maxtessfactor(64.0f)]

			//-----------------------------------------------------------控制点外壳着色器---------------------------------------------------
			HullOut FlatTessControlPoint (InputPatch<Varyings , 3> IN , uint id:SV_OUTPUTCONTROLPOINTID)
			{
				//SV_OUTPUTCONTROLPOINTID ： 当前处理的控制点的索引
				HullOut OUT = (HullOut)0;
				OUT.positionOS = IN[id].positionOS.xyz;
				OUT.normalOS = IN[id].normalOS.xyz;
				OUT.uv = IN[id].uv;
				return OUT;
			}

			//-----------------------------------------------------域着色器--------------------------------------------------------------
			[domain("tri")]
			DomainOut FlatTessDomain (PatchTess tessFactors , const OutputPatch<HullOut , 3> IN , float3 bary : SV_DOMAINLOCATION)
			{	
				//PatchTess : 控制点的细分因子，决定了如何控制三角形
				//HullOut ： 三个顶点的HullOut结构，包含顶点，纹理，法线等信息
				//SV_DOMAINLOCATION ： 重心坐标，向量，用于在三个控制点之间插值
				DomainOut OUT = (DomainOut)0;
				float3 positionOS = IN[0].positionOS * bary.x + IN[1].positionOS * bary.y + IN[2].positionOS * bary.z;
				float3 normalOS = IN[0].normalOS * bary.x + IN[1].normalOS * bary.y + IN[2].normalOS * bary.z;
				float2 uv = IN[0].uv * bary.x + IN[1].uv * bary.y + IN[2].uv * bary.z;
				OUT.positionCS = TransformObjectToHClip(positionOS);
				OUT.uv = uv;
				return OUT;
			}

 
			half4 frag(Varyings IN) : SV_Target {
 
				return half4(1,1,1,1);
			}
			ENDHLSL
		}
	}
}
