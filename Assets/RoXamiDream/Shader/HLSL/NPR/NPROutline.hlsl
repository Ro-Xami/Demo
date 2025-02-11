#pragma vertex vert
#pragma fragment frag

CBUFFER_START(UnityPerMaterial)
		float _outlineSize;
		float4 _outlineColor;
CBUFFER_END

struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
 
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;
				float3 outlineDir = normalize(IN.color.xyz * 2 - 1);
				IN.positionOS.xyz += outlineDir * _outlineSize * IN.color.z * 0.1;
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv = IN.uv;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
 
				return baseMap * _outlineColor;
			}