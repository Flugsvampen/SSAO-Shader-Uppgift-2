Shader "Custom/SSAO" 
{
    Properties
	{
        _MainTex("Main Texture", 2D) = "" {}
		_RandomTexture("Noise Texture", 2D) = "" {}
		_SSAO("SSAO", 2D) = "" {}
    }

    Subshader
	{
        ZTest Always
		Cull Off
		ZWrite Off
		Fog { Mode Off }

        CGINCLUDE
		#include "UnityCG.cginc"
		//#pragma exclude_renderers gles

        struct v2f_ao 
		{
			float4 pos : POSITION;
			float2 uv : TEXCOORD0;
			float2 uvR : TEXCOORD1;	// UV for random tex
		};

		uniform float2 _NoiseScale;
		float4 _CameraDepthNormalsTexture_ST;
		sampler2D _CameraDepthNormalsTexture;
		sampler2D _RandomTexture;
		float4 _Params;	// x=radius, y=minZ, z=attenuation power, w=SSAO power

		v2f_ao vert_ao(appdata_img v)
		{
			v2f_ao o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord, _CameraDepthNormalsTexture);
			o.uvR = v.texcoord.xy * _NoiseScale;
			return o;
		}

		#define INPUT_SAMPLE_COUNT 26
		#include "frag_ao.cginc"

		ENDCG

			// SSAO pass
			Pass
		{
			CGPROGRAM
			#pragma vertex vert_ao
			#pragma fragment frag
			#pragma target 3.0

			float _SampleSpread = 1.0f;

			half4 frag(v2f_ao i) : COLOR
			{
				#define SAMPLE_COUNT 26

				// Kernel with already randomized sample points
				const float3 RAND_SAMPLES[SAMPLE_COUNT] = 
				{
					float3(0.002949867, 0.01284683, 0.01102593),
					float3(0.06906814, 0.01128638, 0.05320715),
					float3(-0.000770461, -0.04874326, 0.004212367),
					float3(0.05050511, 0.03640967, 0.03790201),
					float3(0.0045923, 0.008116453, 0.008261486),
					float3(0.01358778, -0.03208742, 0.04765264),
					float3(0.01679082, 0.02056153, 0.01905825),
					float3(-0.03587855, -0.01669282, 0.03833504),
					float3(0.05690826, -0.06596839, 0.01076089),
					float3(0.0134652, 0.01212867, 0.0296591),
					float3(0.03060714, -0.01767976, 0.01574764),
					float3(0.02939536, -0.006988192, 0.005904159),
					float3(0.02205941, 0.01018347, 0.02139618),
					float3(0.009726413, 0.001822639, 0.009405001),
					float3(-0.00353252, 0.03099, 0.01865234),
					float3(0.01860307, 0.040569, 0.02876908),
					float3(-0.02375085, 0.02113501, 0.03337773),
					float3(0.02468252, 0.08730727, 0.01505481),
					float3(0.008223602, -0.009393586, 0.02238689),
					float3(0.02133231, 0.05187935, 0.06208164),
					float3(0.05895283, -0.07161243, 0.01260035),
					float3(0.01536977, -0.01221264, 0.002995067),
					float3(0.003435674, -0.09547421, 0.02704615),
					float3(-0.05372969, -0.06047624, 0.05167094),
					float3(0.01017836, -0.005069511, 0.007873893),
					float3(0.01668272, -0.08124822, 0.04017327),
				};
				
				return frag_ao(i, SAMPLE_COUNT, RAND_SAMPLES, _SampleSpread);
			}
			ENDCG
		}

        // Blur pass
        Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"

			struct v2f 
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};

			float4 _MainTex_ST;

			v2f vert(appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _CameraDepthNormalsTexture);
				return o;
			}

			sampler2D _SSAO;
			float2 _SSAO_TexelSize;
			float3 _TexelOffsetScale;

			inline half CheckSame(half4 n, half4 nn)
			{
				// difference in normals
				half2 diff = abs(n.xy - nn.xy);
				half sn = (diff.x + diff.y) < 0.1;
				// difference in depth
				float z = DecodeFloatRG(n.zw);
				float zz = DecodeFloatRG(nn.zw);
				float zdiff = abs(z - zz) * _ProjectionParams.z;
				half sz = zdiff < 0.2;
				return sn * sz;
			}


			half4 frag(v2f i) : COLOR
			{
				#define NUM_BLUR_SAMPLES 4

				float2 o = _TexelOffsetScale.xy;

				half sum = tex2D(_SSAO, i.uv).r * (NUM_BLUR_SAMPLES + 1);
				half denom = NUM_BLUR_SAMPLES + 1;

				half4 geom = tex2D(_CameraDepthNormalsTexture, i.uv);

				for (int s = 0; s < NUM_BLUR_SAMPLES; ++s)
				{
					float2 nuv = i.uv + o * (s + 1);
					half4 ngeom = tex2D(_CameraDepthNormalsTexture, nuv.xy);
					half coef = (NUM_BLUR_SAMPLES - s) * CheckSame(geom, ngeom);
					sum += tex2D(_SSAO, nuv.xy).r * coef;
					denom += coef;

					nuv = i.uv - o * (s + 1);
					ngeom = tex2D(_CameraDepthNormalsTexture, nuv.xy);
					coef = (NUM_BLUR_SAMPLES - s) * CheckSame(geom, ngeom);
					sum += tex2D(_SSAO, nuv.xy).r * coef;
					denom += coef;
				}

				return sum / denom;
			}
			ENDCG
		}

        // Composite pass
        Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f 
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata_img v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			sampler2D _MainTex;
			sampler2D _SSAO;

			half4 frag(v2f i) : COLOR
			{
				// Gets main and AO textures
				half4 output = tex2D(_MainTex, i.uv);
				half ao = tex2D(_SSAO, i.uv).r;

				// Multiplies AO texture with SSAO power
				ao = pow(ao, _Params.w);

				// Adds AO to normal image
				output.rgb *= ao;

				return output;
			}
			ENDCG
		}
    }
}