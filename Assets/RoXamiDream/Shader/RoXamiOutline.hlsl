#pragma vertex vert
#pragma fragment frag

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
 
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
 
			Varyings vert(Attributes IN) {
				Varyings OUT;

				float3 normal = normalize(TransformObjectToWorldNormal(IN.normal));

				IN.positionOS.xyz += normal * _OutlineSize * 0.001 * IN.color;
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv = IN.uv;
				return OUT;
			}
 
			half4 frag(Varyings IN) : SV_Target {
				half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
 
				return baseMap * _OutlineColor;
			}