Shader "Jian/Example/Standard"
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

        Pass
        {

        Tags{"LightMode" = "UniversalForward"}

        HLSLPROGRAM
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            //#include "RoXamiShadow.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            //#pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

            

                        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _Diffuse;
        float _NormalScale,_Metallic,_Roughness,_Ao;
        //float4 _BaseColor;
        float _hard;
        float _inDirect;
        CBUFFER_END 

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_NormalTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);

            //����ʷ�����(���Կռ�)Gamma�ռ�0.220916301
            #define ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)

            //���߷ֲ�����
            float Distribution(float roughness2 , float NoH)
            {
                float lerpSquareRoughness = pow(lerp(0.01,1, roughness2),2);
                float Distribution = lerpSquareRoughness / pow( (pow(NoH , 2) * (lerpSquareRoughness - 1) + 1) , 2);
                //float Distribution = pow(NoH , 2) * (roughness2 - 1) + 1.00001;
                //NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
                return Distribution;
            }

            //�����ڱ��Ӻ���
            float G_SubFuction(float dotTerm , half roughness)
            {
                float a = pow( (roughness + 1) / 2 , 2);
                float k = a / 2;
                float subG = dotTerm / (dotTerm * (1 - k) + k);
                return subG;
            }

            //�����ڱκ���
            float Geometry(float roughness , float NoV , float NoL)
            {
                float Gl = G_SubFuction(NoL , roughness);
                float Gv = G_SubFuction(NoV , roughness);
                float G = Gl * Gv;
                return G;
            }

            //ֱ�ӹ������
            float3 Fresnel(float3 F0 , float HoV)
            {
                return F0 + (1 - F0) * exp2((-5.55473 * HoV - 6.98316) * HoV);
            }

            //unity�򻯺�ļ����ڱκͷ�����
            float unityVF(float roughness , float LoH)
            {
                float VF = 1 / (pow(LoH , 2) * (roughness + 0.5));
                return VF;
            }

            //��г��������������ɫ
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

            //��ӹ����������
            float3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }

            //��ӹ�߹� ����̽��
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

            //�߹ⷴ��Ӱ�����ص�lut��ͼ���������
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
            float4 positionOS : POSITION;                     //���붥��
            float4 normalOS : NORMAL;                         //���뷨��
            float2 texcoord : TEXCOORD0;                      //����uv��Ϣ
            float4 tangentOS : TANGENT;                       //��������
        };

        struct Varings
        {
            float2 uv : TEXCOORD0;                            //���uv
            float4 positionCS : SV_POSITION;                  //���λ��
            float3 positionWS : TEXCOORD1;                    //����ռ��¶���λ����Ϣ
            float3 normalWS : NORMAL;                         //����ռ��·�����Ϣ
            float3 tangentWS : TANGENT;
            float3 BtangentWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;                     //����ռ��¹۲��ӽ�
            float4 ShadowCoord : TEXCOORD4;
        };

            Varings vert (Attributes IN)
            {
                Varings OUT = (Varings) 0;
                //Vertex
                VertexPositionInputs PositionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
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
                OUT.ShadowCoord = TransformWorldToShadowCoord(OUT.positionWS.xyz);

                OUT.uv = IN.texcoord;
                return OUT;
            }

            half4 frag(Varings IN) : SV_Target
            {
                // sample the texture
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , IN.uv);
                half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,IN.uv);
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,IN.uv);

                half metallic = _Metallic * mask.b;
                half roughness = max(0.01 , _Roughness * mask.g);
                //half roughness =  _Roughness * mask.g;

                half roughness2 = pow(roughness , 2);
                half ao = _Ao * mask.r;

                //Normal
                float3x3 TBN = {IN.tangentWS , IN.BtangentWS , IN.normalWS};
                TBN = transpose(TBN);//ת�þ���
                float3 norTS = UnpackNormalScale(normal , _NormalScale);
                norTS.z = sqrt(1 - saturate(dot(norTS.xy , norTS.xy)));

                half3 N = NormalizeNormalPerPixel(mul(TBN , norTS));

                //Data
                IN.ShadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                Light mainLight = GetMainLight(IN.ShadowCoord); 
                float shadow = MainLightRealtimeShadow(IN.ShadowCoord);
                //half shadowFadeOut = GetDistanceFade(IN.positionWS); // jave.lin : ���� shadow fade out
                //shadow = lerp(1, shadow, shadowFadeOut);
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
                float3 directColor = (directSpecColor + directDiffuseColor) * NdotL * lightColor.xyz * shadow;
                

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

                Pass // jave.lin : �� ApplyShadowBias
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct a2v {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            // �������� uniform �� URP shadows.hlsl ��ش����п��Կ���û�зŵ� CBuffer ���У���������ֻҪ�� ����Ϊ��ͬ�� uniform ����
            float3 _LightDirection;
            float4 _ShadowBias; // x: depth bias, y: normal bias
            half4 _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise)
            // jave.lin ֱ�ӽ���Shadows.hlsl �е� ApplyShadowBias copy ����
            float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
            {
                float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;
                // normal bias is negative since we want to apply an inset normal offset
                positionWS = lightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                return positionWS;
            }
            v2f vert(a2v v)
            {
                v2f o = (v2f)0;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                half3 normalWS = TransformObjectToWorldNormal(v.normal);
                worldPos = ApplyShadowBias(worldPos, normalWS, _LightDirection);
                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = v.uv;
                return o;
            }
            real4 frag(v2f i) : SV_Target
            {
#if _ALPHATEST_ON
                half4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.001);
#endif
                return 0;
            }
            ENDHLSL
        }
    }
}
