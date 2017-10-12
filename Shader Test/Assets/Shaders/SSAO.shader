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

			half4 frag(v2f_ao i) : COLOR
			{
				#define SAMPLE_COUNT 26

				// Kernel with already randomized sample points
				const float3 RAND_SAMPLES[SAMPLE_COUNT] = 
				{
					/*float3(0.002949867, 0.01284683, 0.01102593),
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
					float3(0.01668272, -0.08124822, 0.04017327),*/
					float3(0.05482546, 0.2494672, 0.3232796),
					float3(-0.191044, -0.2591855, 0.2669713),
					float3(-0.2043421, 0.2367355, 0.03422019),
					float3(-0.03208215, 0.06274014, 0.166667),
					float3(-0.2046325, -0.03820277, 0.2232532),
					float3(-0.01958951, 0.02173291, 0.07298192),
					float3(-0.2663276, -0.1980727, 0.2860348),
					float3(0.03430622, -0.01116979, 0.01366123),
					float3(-0.2685122, 0.1094684, 0.209325),
					float3(-0.09254467, -0.2968616, 0.05269672),
					float3(-0.09125322, -0.05893663, 0.3009198),
					float3(0.2453511, -0.2185694, 0.1263528),
					float3(0.2810591, 0.3489996, 0.1820556),
					float3(0.008712705, -0.006111494, 0.009772848),
					float3(0.2061947, 0.2610606, 0.2945131),
					float3(-0.423664, -0.1243943, 0.01867595),
					float3(-0.02346919, -0.1306242, 0.1110497),
					float3(-0.02370451, -0.01125706, 0.04701033),
					float3(-0.3139417, 0.2719517, 0.1070383),
					float3(0.3911843, -0.1367606, 0.1297354),
					float3(-0.2293619, 0.08658551, 0.04718514),
					float3(0.009533866, -0.1970773, 0.4149589),
					float3(-0.154675, 0.05653995, 0.09831425),
					float3(0.02636004, -0.1662591, 0.1752673),
					float3(0.3301921, -0.2140818, 0.01665761),
					float3(-0.06818585, 0.1947672, 0.04535825)
				};
				
				return frag_ao(i, SAMPLE_COUNT, RAND_SAMPLES);
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