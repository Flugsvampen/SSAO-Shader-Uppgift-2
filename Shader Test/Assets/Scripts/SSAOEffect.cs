using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Screen Space Ambient Occlusion")]
[ImageEffectAllowedInSceneView]
public class SSAOEffect : MonoBehaviour
{
    [Range(0, 16)]public int noiseSize = 4;
    [Range(0.05f, 1.0f)]public float radius = 0.4f;
    [Range(1f, 20f)]public float sampleSpread = 1f;
    [Range(0.1f, 4f)]public float occlusionIntensity = 1.5f;
    [Range(0.2f, 2f)]public float occlusionAttenuation = 1.0f;
    [Range(0f, 5f)]public float blur = 2f;
    [Range(0f, 0.5f)]public float normalDiffFactor = 0.1f;
    [Range(0f, 0.5f)]public float depthDiffFactor = 0.2f;
    [Range(0.001f, 1f)]public float minZ = 0.01f;

    public Material SSAO_mat;

    private Texture2D noiseTex;
    

    void Start()
    {
        //GenerateKernelSamples(26);
        GenerateNoiseTex();
        Camera.main.depthTextureMode |= DepthTextureMode.DepthNormals;
    }


    private void GenerateNoiseTex()
    {
        Color[] noise = new Color[noiseSize * noiseSize];

        for (int i = 0; i < noiseSize * noiseSize; i++)
        {
            noise[i] = new Color(Random.Range(0.0f, 1.0f), Random.Range(0.0f, 1.0f), 0.0f);
        }

        noiseTex = new Texture2D(noiseSize, noiseSize);
        noiseTex.SetPixels(noise);
        SSAO_mat.SetTexture("_RandomTexture", noiseTex);
        SSAO_mat.SetFloat("_NoiseSize", noiseSize);
    }


    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Temporary RenderTexture for SSAO
        RenderTexture rtAO = RenderTexture.GetTemporary(source.width, source.height, 0);

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

        SSAO_mat.SetFloat("_SampleSpread", sampleSpread);
        
        SSAO_mat.SetVector("_Params", new Vector4(radius, minZ, 1.0f / occlusionAttenuation, occlusionIntensity));

        SSAO_mat.SetFloat("_NormalDiffFactor", normalDiffFactor);
        SSAO_mat.SetFloat("_DepthDiffFactor", depthDiffFactor);

        bool doBlur = blur > 0;
        Graphics.Blit(doBlur ? null : source, rtAO, SSAO_mat, 0);

        if (doBlur)
        {
            // Blur SSAO horizontally
            RenderTexture rtBlurX = RenderTexture.GetTemporary(source.width, source.height, 0);
            SSAO_mat.SetVector("_TexelOffsetScale",
                new Vector2(blur / source.width, 0));
            SSAO_mat.SetTexture("_SSAO", rtAO);
            Graphics.Blit(null, rtBlurX, SSAO_mat, 1);
            RenderTexture.ReleaseTemporary(rtAO); // original rtAO not needed anymore

            // Blur SSAO vertically
            RenderTexture rtBlurY = RenderTexture.GetTemporary(source.width, source.height, 0);
            SSAO_mat.SetVector("_TexelOffsetScale",
                new Vector2(0, blur / source.height));
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


    void GenerateKernelSamples(int kernelSize)
    {
        Vector3[] samplePoints = new Vector3[kernelSize];

        string kernelPrint = "";

        for (int i = 0; i < kernelSize; i++)
        {
            // Creates sample points on the surface of a hemisphere oriented along the z axis
            samplePoints[i] = new Vector3(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), Random.Range(0.0f, 1.0f));
            samplePoints[i].Normalize();

            samplePoints[i] *= Random.Range(0.0f, 1.0f);

            // Scales points to distribute them within the hemisphere with an accelerating interpolation function
            float scale = i / kernelSize;
            scale = Mathf.Lerp(0.1f, 1.0f, scale * scale);
            samplePoints[i] *= scale;

            // Adds copy/paste-friendly code with sample points positions to the string
            kernelPrint += string.Format("float3({0}, {1}, {2})\n", samplePoints[i].x, samplePoints[i].y, samplePoints[i].z);
        }

        print(kernelPrint);
    }
}