using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InstatntiateInGrid : MonoBehaviour
{
    [SerializeField] GameObject prefab;
    [SerializeField] int amountX = 6;
    [SerializeField] int amountZ = 6;
    [SerializeField] float offset = 1.1f;
    [SerializeField] Vector3 startPos = new Vector3(0f, 0f, 0f);
    [SerializeField] Vector3 rotation = new Vector3(0f, 0f, 0f);


	// Use this for initialization
	void Start ()
    {
		for (int i = 0; i <= amountX; i++)
        {
            for (int j = 0; j < amountZ; j++)
            {
                Vector3 pos = new Vector3(startPos.x + offset * i, startPos.y, startPos.z + offset * j);
                Instantiate(prefab, pos, Quaternion.Euler(rotation));
            }
        }
	}
}
