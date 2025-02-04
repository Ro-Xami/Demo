using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class SmoothNormalsBaker : EditorWindow
{
    public GameObject obj;
    public string savePath;

    [MenuItem("RoXamiTools/MeshEditor/SmoothNormals")]
    public static void ShowWindow()
    {
        GetWindow<SmoothNormalsBaker>("SmoothNormals");
    }

    public void OnGUI()
    {
        obj = (GameObject)EditorGUILayout.ObjectField("Mesh", obj, typeof(GameObject), false);
        savePath = EditorTools.GuiSetFilePath(savePath, "File");

        GUILayout.Space(10);
        if (GUILayout.Button("Bake"))
        {
            SmoothNormals();
        }
    }

    public void SmoothNormals()
    {
        MeshFilter[] mf = obj.GetComponentsInChildren<MeshFilter>();
        
        for (int i = 0; i < mf.Length; i++)
        {
            Mesh mesh = GameObject.Instantiate(mf[i].sharedMesh);

            Vector3[] vertices = mesh.vertices;
            int[] triangles = mesh.triangles;
            Color[] colors = new Color[mesh.vertices.Length];
            Dictionary<Vector3, List<Vector3>> vertexToNormals = new Dictionary<Vector3, List<Vector3>>();

            for (int j = 0; j < triangles.Length; j += 3)
            {
                Vector3 v0 = vertices[triangles[j]];
                Vector3 v1 = vertices[triangles[j + 1]];
                Vector3 v2 = vertices[triangles[j + 2]];

                Vector3 normal = Vector3.Cross(v1 - v0, v2 - v0).normalized;

                if (!vertexToNormals.ContainsKey(v0)) vertexToNormals[v0] = new List<Vector3>();
                if (!vertexToNormals.ContainsKey(v1)) vertexToNormals[v1] = new List<Vector3>();
                if (!vertexToNormals.ContainsKey(v2)) vertexToNormals[v2] = new List<Vector3>();

                vertexToNormals[v0].Add(normal);
                vertexToNormals[v1].Add(normal);
                vertexToNormals[v2].Add(normal);
            }

            for (int j = 0; j < vertices.Length; j++)
            {
                if (vertexToNormals.ContainsKey(vertices[j]))
                {
                    Vector3 smoothNormal = Vector3.zero;
                    foreach (Vector3 normal in vertexToNormals[vertices[j]])
                    {
                        smoothNormal += normal;
                    }
                    smoothNormal = smoothNormal.normalized;
                    colors[j] = new Color((smoothNormal.x + 1f) * 0.5f, (smoothNormal.y + 1f) * 0.5f, (smoothNormal.z + 1f) * 0.5f, 1);
                }
            }
            mesh.SetColors(colors);
            AssetDatabase.CreateAsset(mesh, savePath + "/" + mf[i].sharedMesh.name + ".asset");
            AssetDatabase.SaveAssets(); // ±£´æ¸Ä¶¯
        }
    }
}
