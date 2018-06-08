using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class InfoToReflMaterial : MonoBehaviour
{
    // The proxy volume used for local reflection calculations.
    public GameObject boundingBox;

    void Start()
    {
        Vector3 bboxLenght = boundingBox.transform.localScale;
        Vector3 centerBBox = boundingBox.transform.position;
        // Min and max BBox points in world coordinates.
        Vector3 BMin = centerBBox - bboxLenght / 2;
        Vector3 BMax = centerBBox + bboxLenght / 2;
        // Pass the values to the material.

        gameObject.GetComponent<MeshRenderer>().sharedMaterial.SetVector("_BBoxMin", BMin);
        gameObject.GetComponent<MeshRenderer>().sharedMaterial.SetVector("_BBoxMax", BMax);
        gameObject.GetComponent<MeshRenderer>().sharedMaterial.SetVector("_EnviCubeMapPos", centerBBox);
    }


   
}


