Shader "RoXami/Example/FrustumCulling"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _MainTex("BaseMap", 2D) = "white" {}
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
        float4 _BaseColor;
        CBUFFER_END 

        #ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                //UNITY_DEFINE_INSTANCED_PROP(float, _frameIndex)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
        //#define _frameIndex              UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _frameIndex)
        #endif

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "GPUInstancing_indirect.cginc"
            #pragma instancing_options procedural:setup
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

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
            float3 normalWS : TEXCOORD2;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

            Varings vert (Attributes IN)
            {
                Varings OUT = (Varings) 0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

                VertexPositionInputs PositionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = PositionInputs.positionCS;
                OUT.positionWS = PositionInputs.positionWS;
                VertexNormalInputs NormalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
                OUT.normalWS = NormalInputs.normalWS;
                OUT.uv = IN.texcoord;
                return OUT;
            }

            half4 frag(Varings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                half4 col = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , IN.uv) * _BaseColor;
                Light light = GetMainLight();
                half diffuseTerm = dot(normalize(light.direction) , normalize(IN.normalWS));
                diffuseTerm = max(1 - diffuseTerm , 0.01);
                col *= diffuseTerm;

                return half4(col.rgb , 1);
            }

            ENDHLSL
    }
}
}