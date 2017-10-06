using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateSamepleKernels : MonoBehaviour
{
    [SerializeField] Material material;

    [SerializeField] int kernelSize;
    Texture2D kernelTex;

    [SerializeField] int noiseSize = 4;
    Texture2D noiseTex;


	void Awake ()
    {
        kernelTex = new Texture2D(kernelSize, 1);
        noiseTex = new Texture2D(noiseSize, noiseSize);

        //material.SetTexture("_KernelTex", GenerateKernelSamples());
        material.SetTexture("_NoiseTex", GenerateNoise());
        material.SetInt("_NoiseTexSize", noiseSize);
    }
	

    Texture2D GenerateKernelSamples()
    {
        Vector3[] samplePoints = new Vector3[kernelSize];

        string kernelPrint = "";

        for (int i = 0; i < kernelSize; i++)
        {
            // Creates sample points on the surface of a hemisphere oriented along the z axis
            // This is set as a color so the value can be put in a texture that accessed by the shader
            samplePoints[i] = new Vector3(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), Random.Range(0.0f, 1.0f));
            samplePoints[i].Normalize();

            samplePoints[i] *= Random.Range(0.0f, 1.0f);

            // Scales points to distribute them within the hemisphere with an accelerating interpolation function
            float scale = i / kernelSize;
            scale = Mathf.Lerp(0.1f, 1.0f, scale * scale);
            samplePoints[i] *= scale;

            // Sets the color (kernel) value in a pixel in the texture
            //kernelTex.SetPixel(i, 0, samplePoints[i]);

            kernelPrint += string.Format("float3({0}, {1}, {2})\n", samplePoints[i].x, samplePoints[i].y, samplePoints[i].z);
        }

        print(kernelPrint);

        return kernelTex;
    }


    Texture2D GenerateNoise()
    {
        Color[] noise = new Color[noiseSize];

        // Generates noise texture that will rotate the sample kernel
        // This increases sample count and minimizes banding artifacts
        for (int i = 0; i < noiseSize; i++)
        {
            for (int j = 0; j < noiseSize; j++)
            {
                noiseTex.SetPixel(i, j, new Color(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), 0.0f));
            }
        }

        return noiseTex;
    }


    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, material);
    }
}
