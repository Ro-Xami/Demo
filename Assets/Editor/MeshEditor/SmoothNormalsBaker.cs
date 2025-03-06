using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using static GpuAnimationBakerWindow;
using static UnityEditor.UIElements.CurveField;

public class SmoothNormalsBaker : EditorWindow
{
    public GameObject obj;
    public MeshRenderMode renderMode;
    public string savePath;

    [MenuItem("RoXamiTools/MeshEditor/SmoothNormals")]
    public static void ShowWindow()
    {
        GetWindow<SmoothNormalsBaker>("SmoothNormals");
    }

    public void OnGUI()
    {
        obj = (GameObject)EditorGUILayout.ObjectField("Mesh", obj, typeof(GameObject), false);
        renderMode = (MeshRenderMode)EditorGUILayout.EnumPopup("MeshRenderMode", renderMode);
        savePath = EditorTools.GuiSetFilePath(savePath, "File");

        GUILayout.Space(10);
        if (GUILayout.Button("Bake"))
        {
            SmoothNormals();
        }
    }

    public void SmoothNormals()
    {
        switch (renderMode)
        {
            case MeshRenderMode.SkinnedMeshRenderer:
                SkinnedMeshRenderer[] skMesh = obj.GetComponentsInChildren<SkinnedMeshRenderer>();
                if (skMesh.Length == 0)
                {
                    Debug.LogError("There is no SkinnedMeshRenderer Component!");
                    return;
                }
                Mesh[] meshesS = new Mesh[skMesh.Length];
                for (int i = 0; i < skMesh.Length; i++)
                {
                    meshesS[i] = skMesh[i].sharedMesh;
                }
                SmoothNormalsAndCreat(meshesS);
                break;
            case MeshRenderMode.MeshFilter:
                MeshFilter[] mf = obj.GetComponentsInChildren<MeshFilter>();
                if (mf.Length == 0)
                {
                    Debug.LogError("There is no MeshFilter Component!");
                    return;
                }
                Mesh[] meshesF = new Mesh[mf.Length];
                for (int i = 0; i < mf.Length; i++)
                {
                    meshesF[i] = mf[i].sharedMesh;
                }
                SmoothNormalsAndCreat(meshesF);
                break;
        }    
    }

    public void SmoothNormalsAndCreat(Mesh[] meshes)
    {
        for (int i = 0; i < meshes.Length; i++)
        {
            Mesh mesh = GameObject.Instantiate(meshes[i]);

            Vector3[] vertices = new Vector3[mesh.vertices.Length];
            for (int j = 0; j < mesh.vertices.Length; j++)
            {
                vertices[j] = mesh.vertices[j] * 10000f;
            }

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
            AssetDatabase.CreateAsset(mesh, savePath + "/" + meshes[i].name + ".asset");
            AssetDatabase.SaveAssets(); // ±£´æ¸Ä¶¯
        }
    }

    public enum MeshRenderMode
    {
        MeshFilter = 0,
        SkinnedMeshRenderer = 1,
    }
}
