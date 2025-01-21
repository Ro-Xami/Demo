		CBUFFER_START(UnityPerMaterial)
		half _cutOut;
		half4 _baseMap_ST;
		CBUFFER_END

			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN,OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv , _baseMap);

				return OUT;
			}