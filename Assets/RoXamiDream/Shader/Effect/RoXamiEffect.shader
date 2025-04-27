Shader "RoXami/Effect/RoXamiEffect"
{
	Properties
	{
		//Toggles
        _MainFunction ("MainFunction" , float) = 1
		[Toggle(_DISTROTION_ON)] _distortion("Distortion_ON" , float) = 0
		[Toggle(_MASK_ON)] _mask("Mask_ON" , float) = 0
		[Toggle(_DISSOLVE_ON)] _dissolve("Dissolve_ON" , float) = 0
		[Toggle(_FRESNEL_ON)] _fresnel("Fresnel_ON" , float) = 0
		[Toggle(_VERTEXOFFSET_ON)] _vertexOffset("VertexOffset_ON" , float) = 0
		[Toggle(_LIGHTFLOW_ON)] _lightFlow("LightFlow_ON" , float) = 0

        [Toggle(_VERTEXOFFSET_MASK_ON)] _vertetxOffest_Mask("VertexOffset_Mask_ON" , float) = 0
        [Toggle(_DISSOLVE_MASK_ON)] _dissolve_Mask("Dissolve_Mask_ON" , float) = 0
        [Toggle(_DISSOLVE_RIM_ON)] _dissolve_Rim("Dissolve_Rim_ON" , float) = 0
        [Toggle(_DISSOLVE_CUSTOMDATA_ON)] _dissolve_CustomData("Dissolve_CustomData_ON" , float) = 0
        [Toggle(_LIGHTFLOW_MASK_ON)] _lightFlow_Mask("LightFlowMask_ON" , float) = 0

		//BaseSettings
		[Enum(UnityEngine.Rendering.CullMode)] _Cullmode("Cullmode", Float) = 2
        [Enum(Alpha, 0, Add, 1)] _BlendMode("Mode", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 1
        [Enum(Off, 0, On, 1)]_Zwrite("Zwrite", Float) = 0

		//MainTex
		[HDR]_Color ("Color", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        [Toggle(_ROTATE_ON)] _Rotate ("RotateTog", Float) = 0
        _rotator ("Rotator", Float ) = 0
        [Toggle(_CHANNAL_ON)] _channal ("Color Channal", Float) = 0
        [Toggle(_CUSTOMDATAMOVE_ON)] _customDataMove ("CustomDataMove", Float) = 0
        _USpeed ("U Speed", Float ) = 0
        _VSpeed ("V Speed", Float ) = 0

        //Distrotion
        _distortionMap ("DistortionMap" , 2D) = "white" {}
        _distortionStrength ("DistortionStrength" , float) = 1
        _distortionSpeedU ("DistortionSpeedU" , float) = 0
        _distortionSpeedV ("DistortionSpeedU" , float) = 0

        //Mask
        _maskMap ("MaskMap" , 2D) = "white" {}
        _maskSpeedU ("MaskSpeedU" , float) = 0
        _maskSpeedV ("MaskSpeedV" , float) = 0
        _maskClip ("MaskClip" , Range(-1 , 1)) = 0

        //Dissolve
        _dissolveMap ("DissolveMap" , 2D) = "white" {}
        _dissolveSpeedU ("DissolveSpeedU" , float) = 0
        _dissolveSpeedV ("DissolveSpeedV" , float) = 0
        _dissolveSmooth ("DissolveSmooth" , Range(0 , 1)) = 0.3
        _dissolveClip ("DissolveClip" , Range(-1 , 1)) = 0
        _dissolveMask ("DissolveMask" , 2D) = "white" {}
        _dissolveMaskClip ("DissolveMaskClip" , Range(-1 , 1)) = 0
        [HDR]_dissolveColor ("DissolveColor" , color) = (1,1,1,1)

        //Fresnel
        [HDR] _fresnelColor ("FrenelColor" , color) = (1,1,1,1)
        _fresnelScale ("FresnelScale" , Range(0 , 1)) = 0
        _fresnelPower ("FresnelPower" , Range(0.1 , 10)) = 1

        //VertexOffset
        _vertexOffsetMap ("VertexOffsetMap" , 2D) = "white" {}
        _vertexOffsetStrength ("VertexOffsetStrength" , float) = 1
        _vertexOffsetSpeedU ("VertexOffsetSpeedU" , float) = 0
        _vertexOffsetSpeedV ("VertexOffsetSpeedV" , float) = 0
        _vertexOffsetMask ("VertexOffsetMask" , 2D) = "white" {}
        _vertexoffsetMaskClip ("VertexOffsetMaskClip" , Range(-1 , 1)) = 0

        //LightFlow
        _lightFlowMap ("LightFlowMap" , 2D) = "white" {}
        [HDR] _lightFlowColor ("LightFlowColor" , color) = (1,1,1,1)
        _lightFlowSpeedU ("LightFlowSpeedU" , float) = 0
        _lightFlowSpeedV ("LightFlowSpeedV" , float) = 0
        _lightFlowMask ("LightFlowMask" , 2D) = "white" {}
        _lightFlowMaskClip ("LightFlowMaskClip" , Range(-1 , 1)) = 0
	}

	SubShader
	{
		Tags {"IgnoreProjector"="True" "Queue"="Transparent" "RenderType"="Transparent"}

        LOD 100

		pass
		{
			Name "RoXamiEffect"
               Tags { "LightMode"="UniversalForward"}

			ZWrite [_Zwrite]           
            Blend [_SrcBlend] [_DstBlend]
            Cull [_Cullmode]        
            ZTest LEqual 

			HLSLPROGRAM
            #pragma vertex EffectVaryings
            #pragma fragment EffectFragment
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma shader_feature_local _DISTROTION_ON
			#pragma shader_feature_local _MASK_ON
			#pragma shader_feature_local _DISSOLVE_ON
			#pragma shader_feature_local _FRESNEL_ON
			#pragma shader_feature_local _VERTEXOFFSET_ON
			#pragma shader_feature_local _LIGHTFLOW_ON
			#pragma shader_feature_local _ROTATE_ON

            #pragma shader_feature_local _VERTEXOFFSET_MASK_ON
            #pragma shader_feature_local _DISSOLVE_MASK_ON
            #pragma shader_feature_local _DISSOLVE_RIM_ON
            #pragma shader_feature_local _DISSOLVE_CUSTOMDATA_ON
			#pragma shader_feature_local _LIGHTFLOW_MASK_ON
            
            //Textures
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            #if defined(_DISTROTION_ON)
            TEXTURE2D(_distortionMap);SAMPLER(sampler_distortionMap);
            #endif

            #if defined(_MASK_ON)
            TEXTURE2D(_maskMap);SAMPLER(sampler_maskMap);
            #endif

            #if defined(_VERTEXOFFSET_ON)
            TEXTURE2D(_vertexOffsetMap);SAMPLER(sampler_vertexOffsetMap);
            #if defined(_VERTEXOFFSET_MASK_ON)
            TEXTURE2D(_vertexOffsetMask);SAMPLER(sampler_vertexOffsetMask);
            #endif
            #endif

            #if defined(_LIGHTFLOW_ON)
            TEXTURE2D(_lightFlowMap);SAMPLER(sampler_lightFlowMap);
            #if defined(_LIGHTFLOW_MASK_ON)
            TEXTURE2D(_lightFlowMask);SAMPLER(sampler_lightFlowMask);
            #endif
            #endif

            #if defined(_DISSOLVE_ON)
            TEXTURE2D(_dissolveMap);SAMPLER(sampler_dissolveMap);
            #if defined(_DISSOLVE_MASK_ON)
            TEXTURE2D(_dissolveMask);SAMPLER(sampler_dissolveMask);
            #endif
            #endif

			CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST , _distortionMap_ST , _lightFlowMap_ST , _lightFlowMask_ST , _maskMap_ST
                        , _vertexOffsetMap_ST , _vertexOffsetMask_ST , _dissolveMap_ST , _dissolveMask_ST;
                float _BlendMode;
                float _USpeed , _VSpeed , _rotator , _channal;
                float _distortionSpeedU , _distortionSpeedV , _distortionStrength;
                float _maskSpeedU , _maskSpeedV , _maskClip;
                float4 _fresnelColor;
                float _fresnelPower , _fresnelScale;
                float4 _lightFlowColor;
                float _lightFlowSpeedU , _lightFlowSpeedV , _lightFlowMaskClip;
                float _vertexOffsetStrength , _vertexOffsetSpeedU , _vertexOffsetSpeedV , _vertexoffsetMaskClip;
                float4 _dissolveColor;
                float _dissolveSpeedU , _dissolveSpeedV , _dissolveClip, _dissolveMaskClip , _dissolvePower , _dissolveSmooth;
			CBUFFER_END

			struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv0  : TEXCOORD0;
                half4 uv1 : TEXCOORD1;
                half4 color : COLOR;            
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                half4 uv1 : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
                half3 viewWS : TEXCOORD3;
                half4 color : COLOR;                                                 
            };

            Varyings EffectVaryings (Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                OUT.uv0 = IN.uv0;
                OUT.uv1 = IN.uv1;
                OUT.color = IN.color;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                //VertexOffset
                #if defined(_VERTEXOFFSET_ON)
                    half2 vertexOffsetUV = TRANSFORM_TEX(IN.uv0, _vertexOffsetMap);
                    vertexOffsetUV += _Time.y * half2(_vertexOffsetSpeedU , _vertexOffsetSpeedV);
                    half vertexOffest = SAMPLE_TEXTURE2D_LOD(_vertexOffsetMap, sampler_vertexOffsetMap, vertexOffsetUV , 0).r;
                    #if defined(_VERTEXOFFSET_MASK_ON)
                        half2 vertexOffsetMaskUV = TRANSFORM_TEX(IN.uv0, _vertexOffsetMask);
                        half vertexOffestMask = SAMPLE_TEXTURE2D_LOD(_vertexOffsetMask, sampler_vertexOffsetMask, vertexOffsetMaskUV , 0).r;
                        vertexOffestMask = saturate(vertexOffestMask + _vertexoffsetMaskClip);
                        vertexOffest *= vertexOffestMask;
                    #endif
                    IN.positionOS.xyz += vertexOffest * _vertexOffsetStrength * normalize(IN.normalOS);
                #endif
                
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz );
                OUT.viewWS = SafeNormalize(GetCameraPositionWS() - positionWS);

                return OUT;
            }

            half4 EffectFragment(Varyings IN) : SV_Target
            {
                half4 finalRGBA = _Color * IN.color;
                half2 mainUV = TRANSFORM_TEX(IN.uv0, _MainTex);

                //CustomData
                #if defined(_CUSTOMDATAMOVE_ON)
                    mainUV += half2(IN.uv1.x , IN.uv1.y);
                #else
                    mainUV += _Time.y * half2(_USpeed , _VSpeed);
                #endif

                //Distortion
                #if defined(_DISTROTION_ON)
                    half2 distortionUV = TRANSFORM_TEX(IN.uv0, _distortionMap);
                    distortionUV += _Time.y * half2(_distortionSpeedU , _distortionSpeedV);
                    half distortion = SAMPLE_TEXTURE2D(_distortionMap, sampler_distortionMap, distortionUV).r;
                    mainUV += (distortion - 0.5) * 2 * _distortionStrength;
                #endif

                //Rotation
                #if defined(_ROTATE_ON)
                    half rotate_angle = ((_rotator * 3.14159) / 180.0);
                    half rotate_cos = 1.0;
                    half rotate_sin = 1.0;
                    sincos(rotate_angle, rotate_sin, rotate_cos);             
                    half2 center = half2(0.5,0.5);
                    mainUV = (mul(mainUV - center, float2x2(rotate_cos, -rotate_sin, rotate_sin, rotate_cos)) + center);
                #endif
                
                //MainTex
                half4 MianTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);
                finalRGBA.rgb *= MianTex.rgb;
                finalRGBA.a *= _channal ? MianTex.a : MianTex.r;

                //Dissolve
                #if defined(_DISSOLVE_ON)
                    half dissolve;
                    half2 dissolveUV = TRANSFORM_TEX(IN.uv0, _dissolveMap);
                    dissolveUV += _Time.y * half2(_dissolveSpeedU , _dissolveSpeedV);
                    half dissolveMap = SAMPLE_TEXTURE2D(_dissolveMap, sampler_dissolveMap, dissolveUV).r;
                    dissolve = dissolveMap;
                    #if defined (_DISSOLVE_MASK_ON)
                        half2 dissolveMaskUV = TRANSFORM_TEX(IN.uv0, _dissolveMask);
                        half dissolveMask = SAMPLE_TEXTURE2D(_dissolveMask, sampler_dissolveMask, dissolveMaskUV).r;
                        dissolveMask = saturate(dissolveMask + _dissolveMaskClip);
                        dissolve *= dissolveMask;
                    #endif
                    #if defined(_DISSOLVE_CUSTOMDATA_ON)
                        dissolve = smoothstep(saturate(IN.uv1.w - _dissolveSmooth) , saturate(IN.uv1.w + _dissolveSmooth) ,dissolve);
                    #else
                        dissolve = smoothstep(saturate(_dissolveClip - _dissolveSmooth) , saturate(_dissolveClip + _dissolveSmooth) ,dissolve);
                    #endif
                    finalRGBA.a = saturate(finalRGBA.a - dissolve);
                    #if defined(_DISSOLVE_RIM_ON)
                        half rimDistance = (_dissolveClip + 1) * 0.5;
                        half dissolveRim = 1 - distance(rimDistance , dissolveMap);
                        finalRGBA.rgb += smoothstep(0.65 , 0.8 , dissolveRim) * _dissolveColor.rgb;
                    #endif
                #endif

                //Mask
                #if defined(_MASK_ON)
                    half2 maskUV = TRANSFORM_TEX(IN.uv0, _maskMap);
                    maskUV += _Time.y * half2(_maskSpeedU , _maskSpeedV);
                    half mask = SAMPLE_TEXTURE2D(_maskMap, sampler_maskMap, maskUV).r;
                    mask = saturate(mask + _maskClip);
                    finalRGBA.a *= mask;
                #endif

                //Fresnel
                #if defined(_FRESNEL_ON)
                    half fresnel = 1 - saturate(dot(IN.viewWS , IN.normalWS));
                    fresnel = pow(fresnel , _fresnelPower);
                    fresnel += _fresnelScale;
                    finalRGBA.rgb += _fresnelColor.rgb * fresnel;
                #endif

                //LightFlow
                #if defined(_LIGHTFLOW_ON)
                    half2 lightFlowUV = TRANSFORM_TEX(IN.uv0, _lightFlowMap);
                    lightFlowUV += _Time.y * half2(_lightFlowSpeedU , _lightFlowSpeedV);
                    half3 lightFlow = SAMPLE_TEXTURE2D(_lightFlowMap, sampler_lightFlowMap, lightFlowUV).rgb;
                    lightFlow *= _lightFlowColor.rgb;
                    #if defined(_LIGHTFLOW_MASK_ON)
                        half2 lightFlowMaskUV = TRANSFORM_TEX(IN.uv0, _lightFlowMask);
                        half lightFlowMask = SAMPLE_TEXTURE2D(_lightFlowMask, sampler_lightFlowMask, lightFlowMaskUV).r;
                        lightFlow *= lightFlowMask;
                    #endif
                    finalRGBA.rgb += lightFlow;
                #endif

                finalRGBA = lerp(finalRGBA, half4(finalRGBA.rgb * finalRGBA.a, 1), _BlendMode);
                
                return finalRGBA;
            }
            ENDHLSL
		}
	}
    CustomEditor "RoXamiEffectGUI"
}