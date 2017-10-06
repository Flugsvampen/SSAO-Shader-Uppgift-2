Shader "Custom/SSAO"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		//_KernelTex ("Kernel Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_Radius ("Radius", Range(0.0, 10.0)) = 1.0
	}
		SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			//uniform sampler2D _KernelTex;
			uniform sampler2D _NoiseTex;
			uniform sampler2D _CameraDepthNormalsTexture;

			uniform int _NoiseTexSize;
			uniform int _KernelSize = 10;

			uniform float _Radius;

			

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 _KernelSamples[10] =
				{
					float3(0.03555618, -0.01857867, 0.001219778),
					float3(0.02714074, 0.04072468, 0.04000646),
					float3(0.01408669, 0.01539655, 0.004707138),
					float3(0.002407561, -0.00134942, 0.001230853),
					float3(-0.02036642, 0.002516509, 0.0177905),
					float3(0.04765717, -0.04838736, 0.07180879),
					float3(-0.02982457, 0.03627676, 0.04157405),
					float3(0.05050805, -0.03679693, 0.07141794),
					float3(0.007068174, 0.0005599133, 0.004737417),
					float3(0.02201164, -0.05331776, 0.02248155)
				};

				float4 mainTex = tex2D(_MainTex, i.uv);
				//float4 kernelTex = tex2D(_KernelTex, i.uv);
				float4 noiseTex = tex2D(_NoiseTex, i.uv);

				float depth;
				float3 normal;
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, normal);

				float3 origin = UnityObjectToClipPos(normal) * depth; // TOTALLY SHIT

				float2 noiseScale = float2(_NoiseTexSize / _ScreenParams.x, _NoiseTexSize / _ScreenParams.y);
				
				float3 rVec = tex2D(_NoiseTex, i.uv * _NoiseTexSize).xyz * 2.0f - 1.0f;
				float3 tangent = normalize(rVec - normal * dot(rVec, normal));
				float3 bitangent = cross(normal, tangent);
				float3x3 tbn = float3x3(tangent, bitangent, normal);

				float occlusion = 0.0;

				for (int j = 0; j < _KernelSize; j++)
				{
					// Get sample position
					float3 _sample = mul(tbn, _KernelSamples[j]);
					_sample = _sample * _Radius + origin;

					// Project sample position
					float4 offset = float4(_sample, 1.0f);
					offset = mul(UNITY_MATRIX_P, offset);
					offset.xy /= offset.w;
					offset.xy = offset.xy * 0.5f + 0.5f;

					// Get sample depth
					float sampleDepth = tex2D(, offset.xy).r; // UNFINISHED

					// Range check and accumulate
					float rangeCheck = abs(origin.z - sampleDepth) < _Radius ? 1.0f : 0.0f; // POTENTIAL SHIT
					occlusion += (sampleDepth <= _sample.z ? 1.0f : 0.0f) * rangeCheck; // POTENTIAL SHIT
				}

				occlusion = 1.0 - (occlusion / _KernelSize);

				return mainTex; //+ occlusion;
			}
			ENDCG
		}
	}
}
