half frag_ao(v2f_ao i, int sampleCount, float3 samples[INPUT_SAMPLE_COUNT])
{
    // Gets random normal from noise texture
    half3 randNormal = tex2D(_RandomTexture, i.uvR).xyz * 2.0 - 1.0;

    // Gets depth, view normal and depthNormal
    float4 depthNormal = tex2D(_CameraDepthNormalsTexture, i.uv);
    float3 viewNormal;
    float depth;
    DecodeDepthNormal(depthNormal, depth, viewNormal);

	// Multiples depth with the cameras far planes distance
    depth *= _ProjectionParams.z;

	// Calculates scale of samples by dividing its radius with depth
    float scale = _Params.x / depth;

    // Total occlusion factor
    float occ = 0.0;

    for (int s = 0; s < sampleCount; ++s)
    {
        // Reflects sample direction around a random vector
        half3 randomDir = reflect(samples[s], randNormal);

        // Make it point to the upper hemisphere
		half flip = step(dot(viewNormal, randomDir), 0);
		randomDir *= 1 - (2 * flip);
		
        // Adds a bit of normal to reduce self shadowing
		randomDir += viewNormal * 0.3;

        float2 offset = randomDir.xy * scale;

        float sampleD = depth - (randomDir.z * _Params.x);

        // Sample depth with offset position
        float4 sampleDepthNormal = tex2D(_CameraDepthNormalsTexture, i.uv + offset);
        float sampleDepth;
        float3 sampleNormal;
        DecodeDepthNormal(sampleDepthNormal, sampleDepth, sampleNormal);

		// Multiples sample depth with the cameras far planes distance
		sampleDepth *= _ProjectionParams.z;

		// Gets normalized Z depth
        float zDepth = saturate(sampleD - sampleDepth);

		// If the Z depth is greater than the minimum required Z depth
		int addOcc = 1 - step(zDepth, _Params.y);
		// This sample occludes, contribute to occlusion
		occ += pow(1 - zDepth, _Params.z) * addOcc;
    }

    occ /= sampleCount;
    return 1 - occ;
}
