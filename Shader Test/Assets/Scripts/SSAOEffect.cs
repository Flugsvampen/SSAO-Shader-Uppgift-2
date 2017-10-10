using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Screen Space Ambient Occlusion")]
[ImageEffectAllowedInSceneView]
public class SSAOEffect : MonoBehaviour
{
    public enum SSAOSamples
    {
        Low = 0,
        Medium = 1,
        High = 2,
    }

    [Range(0, 16)]public int noiseSize = 4;
    [Range(0.05f, 1.0f)]public float radius = 0.4f;
    [Range(0.5f, 4f)]public float occlusionIntensity = 1.5f;
    [Range(0f, 4f)]public float blur = 2f;
    //[Range(1, 6)]public int downsampling = 2;
    [Range(0.2f, 2f)]public float occlusionAttenuation = 1.0f;
    [Range(0.00001f, 0.5f)]public float minZ = 0.01f;

    public Material SSAO_mat;

    private Texture2D noiseTex;
    

    void Start()
    {
        noiseTex = GenerateNoiseTex();
        Camera.main.depthTextureMode |= DepthTextureMode.DepthNormals;
    }


    private Texture2D GenerateNoiseTex()
    {
        Color[] noise = new Color[noiseSize * noiseSize];

        for (int i = 0; i < noiseSize * noiseSize; i++)
        {
            noise[i] = new Color(Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), 0.0f);
        }

        noiseTex = new Texture2D(noiseSize, noiseSize);
        noiseTex.SetPixels(noise);

        SSAO_mat.SetTexture("_RandomTexture", noiseTex);

        return noiseTex;
    }


    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Temporary RenderTexture for SSAO
        RenderTexture rtAO = RenderTexture.GetTemporary(source.width, source.height, 0);

        /*float fovY = Camera.main.fieldOfView;

        // Gets distance to the far clip plane
        float z = Camera.main.farClipPlane;

        // Calculates height from the camera to the top of the far clip plane
        float y = Mathf.Tan(fovY * Mathf.Deg2Rad * 0.5f) * z;

        // Calculates width from the camera to the right side of the far clip plane
        float x = y * Camera.main.aspect;

        // Sets the _FarCorner variable as the same as the top right corner of the far clip plane with the previously calculated coordinates
        SSAO_mat.SetVector("_FarCorner", new Vector3(x, y, z));*/

        int noiseWidth, noiseHeight;

        // If the noise texture exist, we get its size
        if (noiseTex)
        {
            noiseWidth = noiseTex.width;
            noiseHeight = noiseTex.height;
        }
        // Sets size to 1. This prevents errors when in edit mode where the noise texture isn't generated
        else
        {
            noiseWidth = 1;
            noiseHeight = 1;
        }

        // Sets the scale of the noise by dividing the render textures size with the noises size
        SSAO_mat.SetVector("_NoiseScale", new Vector3((float)rtAO.width / noiseWidth, (float)rtAO.height / noiseHeight, 0.0f));
        
        SSAO_mat.SetVector("_Params", new Vector4(radius, minZ, 1.0f / occlusionAttenuation, occlusionIntensity));

        bool doBlur = blur > 0;
        Graphics.Blit(doBlur ? null : source, rtAO, SSAO_mat, 0);

        if (doBlur)
        {
            // Blur SSAO horizontally
            RenderTexture rtBlurX = RenderTexture.GetTemporary(source.width, source.height, 0);
            SSAO_mat.SetVector("_TexelOffsetScale",
                new Vector4(blur / source.width, 0, 0, 0));
            SSAO_mat.SetTexture("_SSAO", rtAO);
            Graphics.Blit(null, rtBlurX, SSAO_mat, 1);
            RenderTexture.ReleaseTemporary(rtAO); // original rtAO not needed anymore

            // Blur SSAO vertically
            RenderTexture rtBlurY = RenderTexture.GetTemporary(source.width, source.height, 0);
            SSAO_mat.SetVector("_TexelOffsetScale",
                new Vector4(0, blur / source.height, 0, 0));
            SSAO_mat.SetTexture("_SSAO", rtBlurX);
            Graphics.Blit(source, rtBlurY, SSAO_mat, 1);
            RenderTexture.ReleaseTemporary(rtBlurX); // blurX RT not needed anymore

            rtAO = rtBlurY; // AO is the blurred one now
        }

        // Modulate scene rendering with SSAO
        SSAO_mat.SetTexture("_SSAO", rtAO);
        Graphics.Blit(source, destination, SSAO_mat, 2);

        RenderTexture.ReleaseTemporary(rtAO);
    }

    /*
	private void CreateRandomTable (int count, float minLength)
	{
		Random.seed = 1337;
		Vector3[] samples = new Vector3[count];
		// initial samples
		for (int i = 0; i < count; ++i)
			samples[i] = Random.onUnitSphere;
		// energy minimization: push samples away from others
		int iterations = 100;
		while (iterations-- > 0) {
			for (int i = 0; i < count; ++i) {
				Vector3 vec = samples[i];
				Vector3 res = Vector3.zero;
				// minimize with other samples
				for (int j = 0; j < count; ++j) {
					Vector3 force = vec - samples[j];
					float fac = Vector3.Dot (force, force);
					if (fac > 0.00001f)
						res += force * (1.0f / fac);
				}
				samples[i] = (samples[i] + res * 0.5f).normalized;
			}
		}
		// now scale samples between minLength and 1.0
		for (int i = 0; i < count; ++i) {
			samples[i] = samples[i] * Random.Range (minLength, 1.0f);
		}		
		string table = string.Format ("#define SAMPLE_COUNT {0}\n", count);
		table += "const float3 RAND_SAMPLES[SAMPLE_COUNT] = {\n";
		for (int i = 0; i < count; ++i) {
			Vector3 v = samples[i];
			table += string.Format("\tfloat3({0},{1},{2}),\n", v.x, v.y, v.z);
		}
		table += "};\n";
		Debug.Log (table);
	}
	*/
}