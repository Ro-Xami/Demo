Shader "Jian/Standard"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _MainTex("BaseMap", 2D) = "white" {}
        [Normal]_NormalTex("_NormalTex", 2D) = "bump" {}
        _NormalScale("_NormalScale",Range(0,1)) = 1
        _MaskTex ("ARMMap", 2D) = "white" {}

        _Ao("AO" , Range(0,1)) = 1
        _Roughness("_Roughness", Range(0,1)) = 1
        _Metallic("_Metallic", Range(0,1)) = 1
        
        _hard ("Hard" , Range(0 , 1)) = 0
        _inDirect ("float" , Range(0 , 1)) = 0.0001
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 100

        HLSLINCLUDE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_verticesAnimTex);
			SAMPLER(sampler_verticesAnimTex);

			//#include "../HLSL/GpuAnim/GpuVerticesAnimInput.hlsl"

		ENDHLSL

        Pass
        {

        Tags{"LightMode" = "UniversalForward"}

        HLSLPROGRAM

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _Diffuse;
        float _NormalScale,_Metallic,_Roughness,_Ao;
        float4 _BaseColor;
        float _hard;
        float _inDirect;
        float _frameIndex;
        CBUFFER_END 

        #ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float, _frameIndex)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        #define _frameIndex              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _frameIndex)
        #endif

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "GPUInstancing_indirect.hlsl"
            #pragma instancing_options procedural:setup

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_instancing

        


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_NormalTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);

            #define ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)

            float Distribution(float roughness2 , float NoH)
            {
                float lerpSquareRoughness = pow(lerp(0.01,1, roughness2),2);
                float Distribution = lerpSquareRoughness / pow( (pow(NoH , 2) * (lerpSquareRoughness - 1) + 1) , 2);
                //float Distribution = pow(NoH , 2) * (roughness2 - 1) + 1.00001;
                //NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
                return Distribution;
            }

            float G_SubFuction(float dotTerm , half roughness)
            {
                float a = pow( (roughness + 1) / 2 , 2);
                float k = a / 2;
                float subG = dotTerm / (dotTerm * (1 - k) + k);
                return subG;
            }

            float Geometry(float roughness , float NoV , float NoL)
            {
                float Gl = G_SubFuction(NoL , roughness);
                float Gv = G_SubFuction(NoV , roughness);
                float G = Gl * Gv;
                return G;
            }

            float3 Fresnel(float3 F0 , float HoV)
            {
                return F0 + (1 - F0) * exp2((-5.55473 * HoV - 6.98316) * HoV);
            }

            float unityVF(float roughness , float LoH)
            {
                float VF = 1 / (pow(LoH , 2) * (roughness + 0.5));
                return VF;
            }

            real3 SH_IndirectionDiff(float3 normal)
            {
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
                float3 Color = SampleSH9(SHCoefficients, normal);
                return max(0, Color);
            }

            float3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }

            real3 IndirectSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);// �������������
                roughness = roughness * (1.7 - 0.7 * roughness);// Unity�ڲ��������� ������������������
                float MidLevel = roughness * 6;// �Ѵֲڶ�remap��0-6 7���׼� Ȼ�����lod����
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//���ݲ�ͬ�ĵȼ����в���
            #if !defined(UNITY_USE_NATIVE_HDR)
                return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//��DecodeHDREnvironment����ɫ��HDR�����½��롣���Կ�����������rgbm��һ��4ͨ����ֵ�����һ��m�����һ������������ʱ��ǰ����ͨ����ʾ����ɫ����xM^y��x��y�����ɻ�����ͼ�����ϵ�����洢��unity_SpecCube0_HDR����ṹ�С�
            #else
                return speColor.xyz*AO;
            #endif
            }

            half3 IndirectSpeFactor(half roughness, half smoothness, half3 BRDFspe, half3 F0, half NdotV)
            {
                #ifdef UNITY_COLORSPACE_GAMMA
                half SurReduction = 1 - 0.28 * roughness * roughness;
                #else
                half SurReduction = 1 / (roughness * roughness + 1);
                #endif
                #if defined(SHADER_API_GLES) // Lighting.hlsl 261 ��
                half Reflectivity = BRDFspe.x;
                #else
                half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                #endif
                half GrazingTSection = saturate(Reflectivity + smoothness);
                half fre = Pow4(1 - NdotV);
                // Lighting.hlsl �� 501 ��
                //half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl �� 501 �У����� 4 �η��������� 5 �η�
                //return fre.xxx;
                return lerp(F0 , GrazingTSection , fre) * SurReduction;
            }

            float GetDistanceFade(float3 positionWS)
			{
			    float4 posVS = mul(GetWorldToViewMatrix(), float4(positionWS, 1));
			    //return posVS.z;
			#if UNITY_REVERSED_Z
			    float vz = -posVS.z;
			#else
			    float vz = posVS.z;
			#endif
			    // jave.lin : 30.0 : start fade out distance, 40.0 : end fade out distance
			    float fade = 1 - smoothstep(30.0, 40.0, vz);
			    return fade;
			}

            struct Attributes
        {
            float4 positionOS : POSITION;
            float4 normalOS : NORMAL;
            float2 texcoord : TEXCOORD0;
            float4 tangentOS : TANGENT;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varings
        {
            float2 uv : TEXCOORD0;
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD1;
            float3 normalWS : NORMAL;
            float3 tangentWS : TANGENT;
            float3 BtangentWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

            //struct GpuVerticesData
            //{
            //    float4x4 trsMatrix;
            //    float frameIndex;
            //};

            //StructuredBuffer<GpuVerticesData> _gpuVerticesData;

            Varings vert (Attributes IN)
            {
                Varings OUT = (Varings) 0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);
                //Vertex
                //RoXami_WorldToObject
                //RoXami_ObjectToWorld
                VertexPositionInputs PositionInputs = GetVertexPositionInputs(IN.positionOS.xyz + _frameIndex/100);
                OUT.positionCS = PositionInputs.positionCS;
                OUT.positionWS = PositionInputs.positionWS;
                //Normal
                VertexNormalInputs NormalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
                OUT.normalWS = NormalInputs.normalWS;
                OUT.normalWS.xyz = NormalInputs.normalWS;
                OUT.tangentWS.xyz = NormalInputs.tangentWS;
                OUT.BtangentWS.xyz = NormalInputs.bitangentWS;

                //Data
                OUT.viewDirWS = SafeNormalize(GetCameraPositionWS() - PositionInputs.positionWS);

                OUT.uv = IN.texcoord;
                return OUT;
            }

            half4 frag(Varings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                // sample the texture
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , IN.uv) * _BaseColor;
                half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,IN.uv);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,IN.uv);

                half metallic = _Metallic * mask.b;
                half roughness = max(0.01 , _Roughness * mask.g);

                half roughness2 = pow(roughness , 2);
                half ao = _Ao * mask.r;

                //Normal
                float3x3 TBN = {IN.tangentWS , IN.BtangentWS , IN.normalWS};
                TBN = transpose(TBN);
                float3 norTS = UnpackNormalScale(normal , _NormalScale);
                norTS.z = sqrt(1 - saturate(dot(norTS.xy , norTS.xy)));

                half3 N = NormalizeNormalPerPixel(mul(TBN , norTS));

                //Data
                Light mainLight = GetMainLight(); 
                float4 lightColor = float4(mainLight.color,1);

                float3 viewDir   = normalize(IN.viewDirWS);
                float3 normalDir = normalize(N);
                float3 lightDir  = normalize(mainLight.direction);
                float3 halfDir   = normalize(viewDir + lightDir);

                float NdotH = max(saturate(dot(normalDir, halfDir)), 0.0001);
                float NdotL = max(saturate(dot(normalDir, lightDir)),0.01);
                //float NdotL = saturate(smoothstep(-_hard , _hard , dot(normalDir, lightDir)) + _inDirect);
                float NdotV = max(saturate(dot(normalDir, viewDir)),0.01);
                float VdotH = max(saturate(dot(viewDir, lightDir)),0.0001);
                float HdotL = max(saturate(dot(halfDir, lightDir)), 0.0001);

                float3 F0 = (1 - metallic) * ColorSpaceDielectricSpec.xyz + metallic * albedo.xyz;//�����SpecColor
                //float3 F0 = lerp(0.04,albedo.rgb,metallic);

                //=============================================BRDF====================================================

                //------------------------------------------DirectSpecColor-----------------------------------------------
                half d = Distribution(roughness2 , NdotH);//���߷ֲ�
                half g = Geometry(roughness , NdotV , NdotL);//�����ڱ�
                half3 f = Fresnel(F0 , HdotL);//������
                //float gf = unityVF(roughness , HdotL);
                //float unityDGF = (d * gf) / 4;
                float3 directSpecColor = (d * g * f) / (4 * NdotV * NdotL);

                //-----------------------------------------DirectDiffuseColor---------------------------------------------
                float3 direct_ks = f;//���淴�����
                float3 direct_kd = (1- direct_ks) * (1 - metallic);//���������
                float3 directDiffuseColor = albedo.xyz * direct_kd;

                //------------------------------------------DirectResult---------------------------------------------
                float3 directColor = (directSpecColor + directDiffuseColor) * NdotL * lightColor.xyz;
                

                //=============================================Indirect===================================================

                //-------------------------------------------IndirectDiffuseColor---------------------------------------------
                half3 shColor = SH_IndirectionDiff(normalDir);//��г�������
                half3 indirect_ks = IndirF_Function(NdotV,F0,roughness);//���淴�����
                half3 indirect_kd = (1 - indirect_ks) * (1 - metallic);//���������
                half3 indirectDiffuseColor = shColor * indirect_kd * albedo.xyz;

                //-------------------------------------------IndirectSpecColor---------------------------------------
                half3 indirectSpeCubeColor = IndirectSpeCube(normalDir, viewDir, roughness, ao);//�߹ⷴ����ɫ
                half3 indirectSpeCubeFactor = IndirectSpeFactor(roughness,1 - roughness, directSpecColor, F0, NdotV);//�߹ⷴ���Ӱ�����أ����lut��ͼ

                half3 indirectSpeColor = indirectSpeCubeColor * indirectSpeCubeFactor;

                //--------------------------------------------IndirectResult-----------------------------------------

                half3 indirectColor = indirectDiffuseColor + indirectSpeColor;

                half3 col = directColor + indirectColor;

                return half4(col  , 1);
            }

            ENDHLSL
    }
}
}