Shader "URP/PBR"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _DiffuseTex("Texture", 2D) = "white" {}
        [Normal]_NormalTex("_NormalTex", 2D) = "bump" {}
        _NormalScale("_NormalScale",Range(0,1)) = 1
        _MaskTex ("M = R R = G AO = B E = Alpha", 2D) = "white" {}

        _Metallic("_Metallic", Range(0,1)) = 1
        _Roughness("_Roughness", Range(0,1)) = 1
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //���ӹ��պ�����
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        //C������
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffuseTex_ST;
        float4 _Diffuse;
        float _NormalScale,_Metallic,_Roughness;
        float4 _BaseColor;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;                     //���붥��
            float4 normalOS : NORMAL;                         //���뷨��
            float2 texcoord : TEXCOORD0;                      //����uv��Ϣ
            float4 tangentOS : TANGENT;                       //��������
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;                            //���uv
            float4 positionCS : SV_POSITION;                  //���λ��
            float3 positionWS : TEXCOORD1;                    //����ռ��¶���λ����Ϣ
            float3 normalWS : NORMAL;                         //����ռ��·�����Ϣ
            float3 tangentWS : TANGENT;
            float3 BtangentWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;                     //����ռ��¹۲��ӽ�

        };

        TEXTURE2D(_DiffuseTex);                          SAMPLER(sampler_DiffuseTex);
        TEXTURE2D(_NormalTex);                          SAMPLER(sampler_NormalTex);
        TEXTURE2D(_MaskTex);                          SAMPLER(sampler_MaskTex);


        ENDHLSL




        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            // D �ķ���
            float Distribution(float roughness, float nh)
            {
                float lerpSquareRoughness = pow(lerp(0.01,1, roughness),2);                      // ����������С�߹��
                float D = lerpSquareRoughness / (pow((pow(nh,2) * (lerpSquareRoughness - 1) + 1), 2) * PI);
                return D;
			}

            // G_1
            // ֱ�ӹ��� G������
            inline real G_subSection(half dot, half k)
            {
                return dot / lerp(dot, 1, k);
            }

            // G �ķ���
            float Geometry(float roughness, float nl, float nv)
            {
                //half k = pow(roughness + 1,2)/8.0;          // ֱ�ӹ��Kֵ

                //half k = pow(roughness,2)/2;                      // ��ӹ��Kֵ

                half k = pow(1 + roughness, 2) / 0.5;

                float GLeft = G_subSection(nl,k);                   // ��һ���ֵ� G
                float GRight = G_subSection(nv,k);                  // �ڶ����ֵ� G
                float G = GLeft * GRight;
                return G;
			}

            // ��ӹ� F �ķ���
            float3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }



            // ֱ�ӹ� F�ķ���
            float3 FresnelEquation(float3 F0,float lh)
            {
                float3 F = F0 + (1 - F0) * exp2((-5.55473 * lh - 6.98316) * lh);
                return F;
			}



            //��ӹ�߹� ����̽��
            real3 IndirectSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);                                                  // �������������
                roughness = roughness * (1.7 - 0.7 * roughness);                                                   // Unity�ڲ��������� ������������������
                float MidLevel = roughness * 6;                                                                    // �Ѵֲڶ�remap��0-6 7���׼� Ȼ�����lod����
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
                // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl �� 501 �У����� 4 �η��������� 5 �η�
                return lerp(F0, GrazingTSection, fre) * SurReduction;
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


            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _DiffuseTex);
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = PositionInputs.positionCS;                          //��ȡ��οռ�λ��
                o.positionWS = PositionInputs.positionWS;                          //��ȡ����ռ�λ����Ϣ

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS.xyz = NormalInputs.normalWS;                                //  ��ȡ����ռ��·�����Ϣ
                o.tangentWS.xyz = NormalInputs.tangentWS;                              //  ��ȡ����ռ���������Ϣ
                o.BtangentWS.xyz = NormalInputs.bitangentWS;                            //  ��ȡ����ռ��¸�������Ϣ

                o.viewDirWS = SafeNormalize(GetCameraPositionWS() - PositionInputs.positionWS);   //  �������λ�� - ����ռ䶥��λ��
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // ============================================= ��ͼ���� =============================================
                half4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex,sampler_DiffuseTex,i.uv) * _BaseColor;
                half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv);

                half metallic = _Metallic;
                half smoothness = _Roughness;
                half roughness = pow((1 - smoothness),2);

                half ao = 0;
                // ============================================== ���߼��� ========================================
                float3x3 TBN = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz};            // ����
                TBN = transpose(TBN);
                float3 norTS = UnpackNormalScale(normal, _NormalScale);                        // ʹ�ñ������Ʒ��ߵ�ǿ��
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));                        // �淶������

                half3 N = NormalizeNormalPerPixel(mul(TBN, norTS));                           // ���㷨�ߺͷ�����ͼ�ں� = �������ռ䷨����Ϣ

                // ================================================ ��Ҫ������  ==========================================
                Light mainLight = GetMainLight();                                             // ��ȡ����
                float4 lightColor = float4(mainLight.color,1);                                 // ��ȡ������ɫ


                float3 viewDir   = normalize(i.viewDirWS);
                float3 normalDir = normalize(N);
                float3 lightDir  = normalize(mainLight.direction);
                float3 halfDir   = normalize(viewDir + lightDir);

                float nh = max(saturate(dot(normalDir, halfDir)), 0.0001);
                float nl = max(saturate(dot(normalDir, lightDir)),0.01);
                float nv = max(saturate(dot(normalDir, viewDir)),0.01);
                float vh = max(saturate(dot(viewDir, lightDir)),0.0001);
                float hl = max(saturate(dot(halfDir, lightDir)), 0.0001);

                float3 F0 = lerp(0.04,albedo.rgb,metallic);


                // ================================================ ֱ�ӹ�߹ⷴ��  ==========================================

                half D = Distribution(roughness,nh);


                half G = Geometry(roughness,nl,nv);


                half3 F = FresnelEquation(F0,hl);


                float3 SpecularResult = (D * G * F) / (nv * nl * 4);
                float3 SpecColor = saturate(SpecularResult * lightColor * nl);                    // �������AO
                //return half4(SpecColor, 1);
                // ================================================ ֱ�ӹ�������  ==========================================

                float3 ks = F;
                float3 kd = (1- ks) * (1 - metallic);                   // ����kd

                float3 diffColor = kd * albedo * lightColor * nl;                                  // ���������Է���

                // ================================================ ֱ�ӹ�  ==========================================
                float3 directLightResult = diffColor + SpecColor;
                //return half4(directLightResult, 1);
                // ================================================ ��ӹ�������  ==========================================
                half3 shcolor = SH_IndirectionDiff(N);                                         // �������AO
                half3 indirect_ks = IndirF_Function(nv,F0,roughness);                          // ���� ks
                half3 indirect_kd = (1 - indirect_ks) * (1 - metallic);                        // ����kd
                half3 indirectDiffColor = shcolor * indirect_kd * albedo;
                //return half4(indirectDiffColor, 1);
                // ================================================ ��ӹ�߹ⷴ��  ==========================================

                half3 IndirectSpeCubeColor = IndirectSpeCube(N, viewDir, roughness, 1.0);
                half3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, SpecularResult, F0, nv);

                half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;

                 //return half4(IndirectSpeColor.rgb,1);
                // ================================================ ��ӹ�  ==========================================
                half3 IndirectColor = IndirectSpeColor + indirectDiffColor;

                // ================================================ �ϲ���  ==========================================
                half3 finalCol = IndirectColor + directLightResult;

                return float4(finalCol , 1);
            }
            ENDHLSL
        }
    }
}