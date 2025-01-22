using UnityEngine;
using UnityEditor;
using System.IO;

public static class BuildGpuVerticesAnimation
{
    static SkinnedMeshRenderer[] skMesh;
    static Mesh mesh;
    static Material mat;
    static Texture2D A2T;
    static int texHeight;
    static int texWidth;
    static int animLength;

    static GameObject newPrefab;
    static string meshPath;
    static string A2TPath;
    static string matPath;
    static string prefabPath;

    static GpuVerticesAnimatorMono mono;
    static GpuVerticesAnimatorCompute compute;
    static GpuVerticesAnimations[] gpuVerticesAnimations;
    public static void BakeAnimToTexture2D(GameObject prefab, AnimationClip[] clips , int frame , bool isNormalTangent , string savePath , string savePrefabPath)
    {
        //-------------------------------------------------------------获取SK组件和Mesh----------------------------------------------------------
        skMesh = prefab.GetComponentsInChildren<SkinnedMeshRenderer>();
        if (skMesh == null || skMesh.Length == 0)
        {
            Debug.LogError("Prefab has no SkinnedMeshRenderer!");
            return;
        }
        if (skMesh.Length > 1)
        {
            Debug.LogError("Prefab has more than 1 SkinnedMeshRenderer! Please combine Mesh to get better performance");
            return;
        }
        mesh = Object.Instantiate(skMesh[0].sharedMesh);

        //------------------------------------------------------------------获取动画-------------------------------------------------------------
        if (clips.Length == 0)
        {
            Debug.LogError("There is no AnimationClips!");
            return;
        }
        for (int i = 0; i < clips.Length; i++)
        {
            if (clips[i] == null)
            {
                Debug.LogError("There is a List has no AnimationClip!");
                return;
            }
        }
        //------------------------------------------------------------------创建纹理-------------------------------------------------------------
        for (int i = 0; i < clips.Length; i++)
        {
            animLength += (int)(frame * clips[i].length);
        }
        texHeight = animLength;
        if (isNormalTangent)
        {
            texWidth = mesh.vertexCount * 3;
        }
        else
        {
            texWidth = mesh.vertexCount;
        }

        A2T = new Texture2D(texWidth, texHeight, TextureFormat.RGBAHalf, false, true);

        //------------------------------------------------------------------保存路径-------------------------------------------------------------
        meshPath = savePath + "/" + prefab.name + "_VerticesAnimationMesh" + ".asset";
        A2TPath = savePath + "/" + prefab.name + "_VerticesAnimationTexture" + ".asset";
        matPath = savePath + "/" + prefab.name + "_VerticesAnimationMaterial" + ".mat";
        prefabPath = savePrefabPath + "/" + prefab.name + "_GpuAnim" + ".prefab";

        CreatNewMesh(isNormalTangent);

        CreatA2T(prefab, clips, frame, isNormalTangent);

        newPrefab = new GameObject();

        CreatMaterial(isNormalTangent);

        CreatNewPrefab(clips , frame);
    }
    public static void CreatAnimator(AnimationClip[] clips , int frame)
    {
        int startFtame = 0;
        gpuVerticesAnimations = new GpuVerticesAnimations[clips.Length];
        for (int h = 0; h < clips.Length; h++)
        {
            gpuVerticesAnimations[h] = new GpuVerticesAnimations();
            gpuVerticesAnimations[h].animtionName = clips[h].name;
            if (h > 0) { startFtame += (int)(frame * clips[h - 1].length); }
            gpuVerticesAnimations[h].startFrame = startFtame;
            gpuVerticesAnimations[h].frameLength = (int)(frame * clips[h].length);
            gpuVerticesAnimations[h].isLoop = clips[h].isLooping;
        }
        mono.animations = gpuVerticesAnimations;
        mono.frame = frame;
        compute.animations = gpuVerticesAnimations;
        compute.frame = frame;
    }
    public static void CreatMaterial(bool isNormalTangent)
    {
        var GpuVertexAnimShader = Shader.Find("RoXami/GpuAnim/GpuVerticesAnim");
        if (GpuVertexAnimShader == null)
        {
            Object.DestroyImmediate(newPrefab);
            Debug.LogError("Can't find GpuVertexAnim Shader to creat Material!");
            return;
        }

        mat = new Material(GpuVertexAnimShader);
        if (isNormalTangent)
        {
            mat.SetFloat("_isNormalTangent", 1);
        }
        mat.SetTexture("_verticesAnimTex", AssetDatabase.LoadAssetAtPath<Texture2D>(A2TPath));
        mat.enableInstancing = true;
        AssetDatabase.CreateAsset(mat, matPath);
        Debug.Log("Baked A2T File successfully at" + matPath);
    }
    public static void CreatNewPrefab(AnimationClip[] clips, int frame)
    {

        AssetDatabase.SaveAssets();
        newPrefab.AddComponent<MeshFilter>().mesh = AssetDatabase.LoadAssetAtPath<Mesh>(meshPath);
        newPrefab.AddComponent<MeshRenderer>().material = AssetDatabase.LoadAssetAtPath<Material>(matPath);
        mono = newPrefab.AddComponent<GpuVerticesAnimatorMono>();
        compute = newPrefab.AddComponent<GpuVerticesAnimatorCompute>();

        CreatAnimator(clips, frame);

        Object.Instantiate<GameObject>(newPrefab);
        PrefabUtility.SaveAsPrefabAsset(newPrefab, prefabPath);
        Object.DestroyImmediate(newPrefab);
        Object.DestroyImmediate(GameObject.Find("New Game Object(Clone)"));
        AssetDatabase.SaveAssets();

        Debug.Log("Baked Prefab successfully at" + prefabPath);
    }
    public static void CreatA2T(GameObject prefab, AnimationClip[] clips, int frame, bool isNormalTangent)
    {
        int previewAnimationLength = 0;
        Vector3[] originalVertices = mesh.vertices;
        for (int l = 0; l < clips.Length; l++)
        {
            if (l > 0)
            {
                previewAnimationLength += (int)(frame * clips[l - 1].length);
            }

            for (int i = 0; i < (int)(frame * clips[l].length); i++)
            {
                float time = (float)i / frame;

                clips[l].SampleAnimation(prefab, time);
                Mesh bakeMesh = Object.Instantiate<Mesh>(mesh);
                skMesh[0].BakeMesh(bakeMesh);
                Vector3[] bakeMeshVertices = bakeMesh.vertices;

                
                    Vector3[] bakeMeshNormals = bakeMesh.normals;
                    Vector4[] bakeMeshTangents = bakeMesh.tangents;

                    for (int j = 0; j < bakeMeshVertices.Length; j++)
                    {
                        Vector3 offestPos = bakeMeshVertices[j] - originalVertices[j];
                        Color verticesData = new Color(offestPos.x, offestPos.y, offestPos.z, 1);
                        A2T.SetPixel(j * 3, i + previewAnimationLength, verticesData);

                        if (isNormalTangent)
                        {
                            Color normalsData = new Color(bakeMeshNormals[j].x, bakeMeshNormals[j].y, bakeMeshNormals[j].z, 1);
                            A2T.SetPixel(j * 3 + 1, i + previewAnimationLength, normalsData);

                            Color tangentsData = bakeMeshTangents[j]; 
                            A2T.SetPixel(j * 3 + 2, i + previewAnimationLength, tangentsData);
                        }
                    }

            }
        }

        A2T.Apply();
        AssetDatabase.CreateAsset(A2T, A2TPath);
        AssetDatabase.SaveAssets();
    }
    public static void CreatNewMesh(bool isNormalTangent)
    {
        Vector2[] animUV = new Vector2[mesh.vertexCount];
        for (int k = 0; k < mesh.vertexCount; k++)
        {
            //animUV[k] = new Vector2((k + 0.5f / 3f)/ mesh.vertexCount, 0.5f / texHeight);//防止输出整数类型
            if (isNormalTangent)
            {
                animUV[k] = new Vector2(k * 3, 0);
            }
            else
            {
                animUV[k] = new Vector2(k, 0);
            }
                
        }
        mesh.SetUVs(1, animUV);
        AssetDatabase.CreateAsset(mesh, meshPath);
        AssetDatabase.SaveAssets();
    }
}
