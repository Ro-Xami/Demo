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
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        //增加光照函数库
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        //C缓存区
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffuseTex_ST;
        float4 _Diffuse;
        float _NormalScale,_Metallic,_Roughness;
        float4 _BaseColor;
        CBUFFER_END

        struct appdata
        {
            float4 positionOS : POSITION;                     //输入顶点
            float4 normalOS : NORMAL;                         //输入法线
            float2 texcoord : TEXCOORD0;                      //输入uv信息
            float4 tangentOS : TANGENT;                       //输入切线
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;                            //输出uv
            float4 positionCS : SV_POSITION;                  //齐次位置
            float3 positionWS : TEXCOORD1;                    //世界空间下顶点位置信息
            float3 normalWS : NORMAL;                         //世界空间下法线信息
            float3 tangentWS : TANGENT;
            float3 BtangentWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;                     //世界空间下观察视角

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


            // D 的方法
            float Distribution(float roughness, float nh)
            {
                float lerpSquareRoughness = pow(lerp(0.01,1, roughness),2);                      // 这里限制最小高光点
                float D = lerpSquareRoughness / (pow((pow(nh,2) * (lerpSquareRoughness - 1) + 1), 2) * PI);
                return D;
			}

            // G_1
            // 直接光照 G项子项
            inline real G_subSection(half dot, half k)
            {
                return dot / lerp(dot, 1, k);
            }

            // G 的方法
            float Geometry(float roughness, float nl, float nv)
            {
                //half k = pow(roughness + 1,2)/8.0;          // 直接光的K值

                //half k = pow(roughness,2)/2;                      // 间接光的K值

                half k = pow(1 + roughness, 2) / 0.5;

                float GLeft = G_subSection(nl,k);                   // 第一部分的 G
                float GRight = G_subSection(nv,k);                  // 第二部分的 G
                float G = GLeft * GRight;
                return G;
			}

            // 间接光 F 的方法
            float3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }



            // 直接光 F的方法
            float3 FresnelEquation(float3 F0,float lh)
            {
                float3 F = F0 + (1 - F0) * exp2((-5.55473 * lh - 6.98316) * lh);
                return F;
			}



            //间接光高光 反射探针
            real3 IndirectSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);                                                  // 计算出反射向量
                roughness = roughness * (1.7 - 0.7 * roughness);                                                   // Unity内部不是线性 调整下拟合曲线求近似
                float MidLevel = roughness * 6;                                                                    // 把粗糙度remap到0-6 7个阶级 然后进行lod采样
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//根据不同的等级进行采样
            #if !defined(UNITY_USE_NATIVE_HDR)
                return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
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
                #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
                half Reflectivity = BRDFspe.x;
                #else
                half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                #endif
                half GrazingTSection = saturate(Reflectivity + smoothness);
                half fre = Pow4(1 - NdotV);
                // Lighting.hlsl 第 501 行
                // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，他是 4 次方，我们是 5 次方
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
                o.positionCS = PositionInputs.positionCS;                          //获取齐次空间位置
                o.positionWS = PositionInputs.positionWS;                          //获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
                o.normalWS.xyz = NormalInputs.normalWS;                                //  获取世界空间下法线信息
                o.tangentWS.xyz = NormalInputs.tangentWS;                              //  获取世界空间下切线信息
                o.BtangentWS.xyz = NormalInputs.bitangentWS;                            //  获取世界空间下副切线信息

                o.viewDirWS = SafeNormalize(GetCameraPositionWS() - PositionInputs.positionWS);   //  相机世界位置 - 世界空间顶点位置
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // ============================================= 贴图纹理 =============================================
                half4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex,sampler_DiffuseTex,i.uv) * _BaseColor;
                half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv);

                half metallic = _Metallic;
                half smoothness = _Roughness;
                half roughness = pow((1 - smoothness),2);

                half ao = 0;
                // ============================================== 法线计算 ========================================
                float3x3 TBN = {i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz};            // 矩阵
                TBN = transpose(TBN);
                float3 norTS = UnpackNormalScale(normal, _NormalScale);                        // 使用变量控制法线的强度
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy)));                        // 规范化法线

                half3 N = NormalizeNormalPerPixel(mul(TBN, norTS));                           // 顶点法线和法线贴图融合 = 输出世界空间法线信息

                // ================================================ 需要的数据  ==========================================
                Light mainLight = GetMainLight();                                             // 获取光照
                float4 lightColor = float4(mainLight.color,1);                                 // 获取光照颜色


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


                // ================================================ 直接光高光反射  ==========================================

                half D = Distribution(roughness,nh);


                half G = Geometry(roughness,nl,nv);


                half3 F = FresnelEquation(F0,hl);


                float3 SpecularResult = (D * G * F) / (nv * nl * 4);
                float3 SpecColor = saturate(SpecularResult * lightColor * nl);                    // 这里可以AO
                //return half4(SpecColor, 1);
                // ================================================ 直接光漫反射  ==========================================

                float3 ks = F;
                float3 kd = (1- ks) * (1 - metallic);                   // 计算kd

                float3 diffColor = kd * albedo * lightColor * nl;                                  // 这里增加自发光

                // ================================================ 直接光  ==========================================
                float3 directLightResult = diffColor + SpecColor;
                //return half4(directLightResult, 1);
                // ================================================ 间接光漫反射  ==========================================
                half3 shcolor = SH_IndirectionDiff(N);                                         // 这里可以AO
                half3 indirect_ks = IndirF_Function(nv,F0,roughness);                          // 计算 ks
                half3 indirect_kd = (1 - indirect_ks) * (1 - metallic);                        // 计算kd
                half3 indirectDiffColor = shcolor * indirect_kd * albedo;
                //return half4(indirectDiffColor, 1);
                // ================================================ 间接光高光反射  ==========================================

                half3 IndirectSpeCubeColor = IndirectSpeCube(N, viewDir, roughness, 1.0);
                half3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, SpecularResult, F0, nv);

                half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;

                 //return half4(IndirectSpeColor.rgb,1);
                // ================================================ 间接光  ==========================================
                half3 IndirectColor = IndirectSpeColor + indirectDiffColor;

                // ================================================ 合并光  ==========================================
                half3 finalCol = IndirectColor + directLightResult;

                return float4(finalCol , 1);
            }
            ENDHLSL
        }
    }
}