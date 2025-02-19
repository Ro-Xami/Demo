struct Attributes {
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float3 normalWS : TEXCOORD3;
				float3 tangentWS : TEXCOORD4;
				float3 bitangentWS : TEXCOORD5;
				float3 viewWS : TEXCOORD6;
				float fogCoord : TEXCOORD7;
				float2 normalizedScreenSpaceUV : TEXCOORD8;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;

				VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz , IN.tangentOS);
				OUT.normalWS = normalInputs.normalWS;
				OUT.tangentWS = normalInputs.tangentWS;
				OUT.bitangentWS = normalInputs.bitangentWS;

				OUT.viewWS = SafeNormalize(GetCameraPositionWS() - OUT.positionWS);
				OUT.fogCoord = ComputeFogFactor(OUT.positionCS.z);
				OUT.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(OUT.positionCS);
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				OUT.uv1 = IN.uv1;

				return OUT;
			}