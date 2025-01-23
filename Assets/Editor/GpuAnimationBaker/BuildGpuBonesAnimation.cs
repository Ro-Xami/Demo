using UnityEngine;
using UnityEditor;
using System.IO;
using UnityEngine.UIElements;

public class BuildGpuBonesAnimation
{
    static SkinnedMeshRenderer skMesh;
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
        GameObject bakePrefab = Object.Instantiate(prefab);

        SkinnedMeshRenderer[] skMeshs = bakePrefab.GetComponentsInChildren<SkinnedMeshRenderer>();
        if (skMeshs == null || skMeshs.Length == 0)
        {
            Debug.LogError("Prefab has no SkinnedMeshRenderer!");
            return;
        }
        if (skMeshs.Length > 1)
        {
            Debug.LogError("Prefab has more than 1 SkinnedMeshRenderer! Please combine Mesh to get better performance");
            return;
        }
        skMesh = skMeshs[0];
        mesh = Object.Instantiate(skMesh.sharedMesh);

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
        texWidth = skMesh.bones.Length * 3;
        A2T = new Texture2D(texWidth, texHeight, TextureFormat.RGBAHalf, false, true);

        //------------------------------------------------------------------保存路径-------------------------------------------------------------
        meshPath = savePath + "/" + prefab.name + "_VerticesAnimationMesh" + ".asset";
        A2TPath = savePath + "/" + prefab.name + "_VerticesAnimationTexture" + ".asset";
        matPath = savePath + "/" + prefab.name + "_VerticesAnimationMaterial" + ".mat";
        prefabPath = savePrefabPath + "/" + prefab.name + "_GpuAnim" + ".prefab";

        CreatNewMesh();

        CreatA2T(bakePrefab, clips, frame, isNormalTangent);

        //newPrefab = new GameObject();

        //CreatMaterial(isNormalTangent);

        //CreatNewPrefab(clips , frame);

        Object.DestroyImmediate(bakePrefab);
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
            mat.SetFloat("_animationPixelLength", (float)animLength / texHeight);
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
    public static void CreatA2T(GameObject bakePrefab, AnimationClip[] clips, int frame, bool isNormalTangent)
    {
        Vector3[] bonesPosition = new Vector3[skMesh.bones.Length];
        Quaternion[] bonesRotation = new Quaternion[skMesh.bones.Length];
        Vector3[] bonesScale = new Vector3[skMesh.bones.Length];
        Matrix4x4[] bonesMatrix = new Matrix4x4[skMesh.bones.Length];
        for (int i = 0; i < skMesh.bones.Length; i++)
        {
            bonesPosition[i] = skMesh.bones[i].position;
            bonesRotation[i] = skMesh.bones[i].rotation;
            bonesScale[i] = skMesh.bones[i].lossyScale;
            bonesMatrix[i] = Matrix4x4.TRS(skMesh.bones[i].position, skMesh.bones[i].rotation, Vector3.one);
        }
        int previewAnimationLength = 0;

        for (int l = 0; l < clips.Length; l++)
        {
            if (l > 0)
            {
                previewAnimationLength += (int)(frame * clips[l - 1].length);
            }

            for (int i = 0; i < (int)(frame * clips[l].length); i++)
            {
                float time = (float)i / frame;
                clips[l].SampleAnimation(bakePrefab, time);

                for (int j = 0; j < skMesh.bones.Length; j++)
                {
                    Vector3 offestPosition = skMesh.bones[j].position - bonesPosition[j];
                    //Vector3 offestPosition = Vector3.zero;
                    Quaternion offestRotation = Quaternion.Inverse(bonesRotation[j]) * skMesh.bones[j].rotation;
                    //Quaternion offestRotation = Quaternion.Euler(0,0,0);
                    //Vector3 offestScale = new Vector3(skMesh.bones[j].lossyScale.x / bonesScale[j].x,
                                                    //skMesh.bones[j].lossyScale.y / bonesScale[j].y,
                                                    //skMesh.bones[j].lossyScale.z / bonesScale[j].z);

                    Vector3 offestScale = Vector3.zero;
                    Matrix4x4 trsMatrix = Matrix4x4.TRS(offestPosition, offestRotation, offestScale);

                    Color m0 = new Color(trsMatrix.m00, trsMatrix.m01, trsMatrix.m02, trsMatrix.m03);
                    Color m1 = new Color(trsMatrix.m10, trsMatrix.m11, trsMatrix.m12, trsMatrix.m13);
                    Color m2 = new Color(trsMatrix.m20, trsMatrix.m21, trsMatrix.m22, trsMatrix.m23);

                    A2T.SetPixel(j * 3, animLength * 2 + i + previewAnimationLength, m0);
                    A2T.SetPixel(j * 3 + 1, animLength * 2 + i + previewAnimationLength, m1);
                    A2T.SetPixel(j * 3 + 2, animLength * 2 + i + previewAnimationLength, m2);
                } 
            }
        }

        A2T.Apply();
        AssetDatabase.CreateAsset(A2T, A2TPath);
        AssetDatabase.SaveAssets();
    }
    public static void CreatNewMesh()
    {
        Vector4[] bonesUV = new Vector4[mesh.vertexCount];
        
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            int bw0 = mesh.boneWeights[i].boneIndex0;
            int bw1 = mesh.boneWeights[i].boneIndex1;
            int bw2 = mesh.boneWeights[i].boneIndex2;
            int bw3 = mesh.boneWeights[i].boneIndex3;
            bonesUV[i] = new Vector4(bw0 * 3, bw1 * 3, bw2 * 3, bw3 * 3);
        }
        mesh.SetUVs(1, bonesUV);

        Color[] verticesColor = new Color[mesh.vertexCount];
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            verticesColor[i] = new Color(mesh.boneWeights[i].weight0, mesh.boneWeights[i].weight1, mesh.boneWeights[i].weight2, mesh.boneWeights[i].weight3);
        }
        mesh.colors = verticesColor;
        AssetDatabase.CreateAsset(mesh, meshPath);
        AssetDatabase.SaveAssets();
    }
}
