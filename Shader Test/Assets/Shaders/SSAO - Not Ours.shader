// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/SSAO - Not Ours"
{
	Properties{
		_MainTex("", 2D) = "" {}
	_RandomTexture("", 2D) = "" {}
	_SSAO("", 2D) = "" {}
	}
		Subshader{
		ZTest Always Cull Off ZWrite Off Fog{ Mode Off }

		CGINCLUDE
		// Common code used by several SSAO passes below
#include "UnityCG.cginc"
#pragma exclude_renderers gles
	struct v2f_ao {
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
		float2 uvR : TEXCOORD1;
	};

	uniform float2 _NoiseScale;
	float4 _CameraDepthNormalsTexture_ST;

	v2f_ao vert_ao(appdata_img v)
	{
		v2f_ao o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord, _CameraDepthNormalsTexture);
		o.uvR = v.texcoord.xy * _NoiseScale;
		return o;
	}

	sampler2D _CameraDepthNormalsTexture;
	sampler2D _RandomTexture;
	float4 _Params; // x=radius, y=minz, z=attenuation power, w=SSAO power

#if defined(SHADER_API_XBOX360)|| defined(SHADER_API_D3D11)

#	define INPUT_SAMPLE_COUNT 8
#	include "frag_ao.cginc"

#	define INPUT_SAMPLE_COUNT 14
#	include "frag_ao.cginc"

#	define INPUT_SAMPLE_COUNT 26
#	include "frag_ao.cginc"

#	define INPUT_SAMPLE_COUNT 34
#	include "frag_ao.cginc"

#else

#	define INPUT_SAMPLE_COUNT
#	include "frag_ao.cginc"

#endif

	ENDCG

		// ---- SSAO pass, 8 samples
		Pass{

		CGPROGRAM
#pragma vertex vert_ao
#pragma fragment frag
#pragma target 3.0
#pragma fragmentoption ARB_precision_hint_fastest


		half4 frag(v2f_ao i) : COLOR
	{
#define SAMPLE_COUNT 8
		const float3 RAND_SAMPLES[SAMPLE_COUNT] = {
		float3(0.01305719,0.5872321,-0.119337),
		float3(0.3230782,0.02207272,-0.4188725),
		float3(-0.310725,-0.191367,0.05613686),
		float3(-0.4796457,0.09398766,-0.5802653),
		float3(0.1399992,-0.3357702,0.5596789),
		float3(-0.2484578,0.2555322,0.3489439),
		float3(0.1871898,-0.702764,-0.2317479),
		float3(0.8849149,0.2842076,0.368524),
	};
	return frag_ao(i, SAMPLE_COUNT, RAND_SAMPLES);
	}
		ENDCG

	}

		// ---- SSAO pass, 14 samples
		Pass{

		CGPROGRAM
#pragma vertex vert_ao
#pragma fragment frag
#pragma target 3.0
#pragma fragmentoption ARB_precision_hint_fastest


		half4 frag(v2f_ao i) : COLOR
	{
#define SAMPLE_COUNT 14
		const float3 RAND_SAMPLES[SAMPLE_COUNT] = {
		float3(0.4010039,0.8899381,-0.01751772),
		float3(0.1617837,0.1338552,-0.3530486),
		float3(-0.2305296,-0.1900085,0.5025396),
		float3(-0.6256684,0.1241661,0.1163932),
		float3(0.3820786,-0.3241398,0.4112825),
		float3(-0.08829653,0.1649759,0.1395879),
		float3(0.1891677,-0.1283755,-0.09873557),
		float3(0.1986142,0.1767239,0.4380491),
		float3(-0.3294966,0.02684341,-0.4021836),
		float3(-0.01956503,-0.3108062,-0.410663),
		float3(-0.3215499,0.6832048,-0.3433446),
		float3(0.7026125,0.1648249,0.02250625),
		float3(0.03704464,-0.939131,0.1358765),
		float3(-0.6984446,-0.6003422,-0.04016943),
	};
	return frag_ao(i, SAMPLE_COUNT, RAND_SAMPLES);
	}
		ENDCG

	}

		// ---- SSAO pass, 26 samples
		Pass{

		CGPROGRAM
#pragma vertex vert_ao
#pragma fragment frag
#pragma target 3.0
#pragma fragmentoption ARB_precision_hint_fastest


		half4 frag(v2f_ao i) : COLOR
	{
#define SAMPLE_COUNT 26
		const float3 RAND_SAMPLES[SAMPLE_COUNT] = {
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
	return frag_ao(i, SAMPLE_COUNT, RAND_SAMPLES);
	}
		ENDCG

	}

		// ---- Blur pass
		Pass{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"

	struct v2f {
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
		}
		for (int s = 0; s < NUM_BLUR_SAMPLES; ++s)
		{
			float2 nuv = i.uv - o * (s + 1);
			half4 ngeom = tex2D(_CameraDepthNormalsTexture, nuv.xy);
			half coef = (NUM_BLUR_SAMPLES - s) * CheckSame(geom, ngeom);
			sum += tex2D(_SSAO, nuv.xy).r * coef;
			denom += coef;
		}
		return sum / denom;
	}
		ENDCG
	}

		// ---- Composite pass
		Pass{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"

	struct v2f {
		float4 pos : POSITION;
		float2 uv[2] : TEXCOORD0;
	};

	v2f vert(appdata_img v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv[0] = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
		o.uv[1] = MultiplyUV(UNITY_MATRIX_TEXTURE1, v.texcoord);
		return o;
	}

	sampler2D _MainTex;
	sampler2D _SSAO;

	half4 frag(v2f i) : COLOR
	{
		half4 c = tex2D(_MainTex, i.uv[0]);
		half ao = tex2D(_SSAO, i.uv[1]).r;
		ao = pow(ao, _Params.w);
		c.rgb *= ao;
		return c;
	}
		ENDCG
	}

	}

		Fallback off
}