using UnityEngine;
using UnityEditor;
using static GpuAnimationBakerWindow;

public static class BuildGpuAnimation
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

    static GpuAnimator gpuAnimator;
    static GpuAnimations[] GpuAnimations;
    public static void BakeAnimToTexture2D(GameObject prefab, AnimationClip[] clips , int frame , bool isNormalTangent , string savePath , string savePrefabPath, GPUAnimMode mode)
    {
        GameObject bakePrefab = Object.Instantiate(prefab);

        GetSavePath(prefab, savePath, savePrefabPath);
        GetAnimationsData(clips, bakePrefab);

        switch (mode)
        {
            case GPUAnimMode.GpuVerticesAnimation:
                CreatNewMeshVertices(isNormalTangent);
                NewTextureVertices(clips, frame, isNormalTangent);
                CreatA2TVertices(bakePrefab, clips, frame, isNormalTangent);
                break;
            case GPUAnimMode.GpuBonesAnimation:
                CreatNewMeshBones();
                NewTextureBones(clips, frame);
                CreatA2TBones(bakePrefab, clips, frame, isNormalTangent);
                break;
        }

        CreatMaterial(isNormalTangent, mode);
        CreatNewPrefab(clips, frame, mode);
        Object.DestroyImmediate(bakePrefab);
        Object.DestroyImmediate(newPrefab);
    }


    //VerticesTextureMesh
    #region
    /// <summary>
    /// New一个纹理
    /// </summary>
    public static void NewTextureVertices(AnimationClip[] clips, int frame, bool isNormalTangent)
    {
        animLength = 0;
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
    }
    /// <summary>
    /// 创建纹理，烘焙顶点的位置，法线切线
    /// </summary>
    public static void CreatA2TVertices(GameObject prefab, AnimationClip[] clips, int frame, bool isNormalTangent)
    {
        //前一个动画的长度
        int lastAnimationLength = 0;
        //原始顶点的位置
        Vector3[] originalVertices = mesh.vertices;

        for (int l = 0; l < clips.Length; l++)
        {
            if (l > 0)
            {
                lastAnimationLength += (int)(frame * clips[l - 1].length);
            }

            for (int i = 0; i < (int)(frame * clips[l].length); i++)
            {
                float time = (float)i / frame;

                clips[l].SampleAnimation(prefab, time);
                Mesh bakeMesh = Object.Instantiate<Mesh>(mesh);
                skMesh.BakeMesh(bakeMesh);

                for (int j = 0; j < bakeMesh.vertexCount; j++)
                {
                    Vector3 offestPos = bakeMesh.vertices[j] - originalVertices[j];
                    Color verticesData = new Color(offestPos.x, offestPos.y, offestPos.z, 1);
                    A2T.SetPixel(j * 3, i + lastAnimationLength, verticesData);

                    if (isNormalTangent)
                    {
                        Color normalsData = new Color(bakeMesh.normals[j].x, bakeMesh.normals[j].y, bakeMesh.normals[j].z, 1);
                        A2T.SetPixel(j * 3 + 1, i + lastAnimationLength, normalsData);

                        Color tangentsData = bakeMesh.tangents[j];
                        A2T.SetPixel(j * 3 + 2, i + lastAnimationLength, tangentsData);
                    }
                }
            }
        }

        A2T.Apply();
        AssetDatabase.CreateAsset(A2T, A2TPath);
        AssetDatabase.SaveAssets();
    }
    /// <summary>
    /// 创建Mesh，存储顶点索引到uv1
    /// </summary>
    public static void CreatNewMeshVertices(bool isNormalTangent)
    {
        Vector2[] animUV = new Vector2[mesh.vertexCount];
        for (int k = 0; k < mesh.vertexCount; k++)
        {
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
    #endregion

    //BonesTextureMesh
    #region
    /// <summary>
    /// New一个纹理
    /// </summary>
    public static void NewTextureBones(AnimationClip[] clips, int frame)
    {
        animLength = 0;
        for (int i = 0; i < clips.Length; i++)
        {
            animLength += (int)(frame * clips[i].length);
        }

        texHeight = animLength;
        texWidth = skMesh.bones.Length * 3;
        A2T = new Texture2D(texWidth, texHeight, TextureFormat.RGBAHalf, false, true);
    }
    /// <summary>
    /// 创建纹理，烘焙动画的骨骼变换矩阵
    /// </summary>
    public static void CreatA2TBones(GameObject bakePrefab, AnimationClip[] clips, int frame, bool isNormalTangent)
    {
        //前一个动画的长度
        int lastAnimationLength = 0;

        for (int l = 0; l < clips.Length; l++)
        {
            if (l > 0)
            {
                lastAnimationLength += (int)(frame * clips[l - 1].length);
            }

            for (int i = 0; i < (int)(frame * clips[l].length); i++)
            {
                //按照帧数采样动画
                float time = (float)i / frame;
                clips[l].SampleAnimation(bakePrefab, time);

                for (int j = 0; j < skMesh.bones.Length; j++)
                {
                    //获取采样动画的骨骼
                    Transform bone = skMesh.bones[j];
                    //获取TPose的骨骼
                    Matrix4x4 bindPose = skMesh.sharedMesh.bindposes[j];
                    // 计算骨骼当前帧的变换矩阵
                    Matrix4x4 boneMatrix = bone.localToWorldMatrix * bindPose;
                    // 将矩阵的每一行编码为颜色，存储到纹理中
                    Color row0 = new Color(boneMatrix.m00, boneMatrix.m01, boneMatrix.m02, boneMatrix.m03);
                    Color row1 = new Color(boneMatrix.m10, boneMatrix.m11, boneMatrix.m12, boneMatrix.m13);
                    Color row2 = new Color(boneMatrix.m20, boneMatrix.m21, boneMatrix.m22, boneMatrix.m23);
                    //纵向为动画的帧数，横向为当前帧的变换矩阵
                    A2T.SetPixel(j * 3, animLength * 2 + i + lastAnimationLength, row0);
                    A2T.SetPixel(j * 3 + 1, animLength * 2 + i + lastAnimationLength, row1);
                    A2T.SetPixel(j * 3 + 2, animLength * 2 + i + lastAnimationLength, row2);
                } 
            }
        }
        A2T.Apply();
        AssetDatabase.CreateAsset(A2T, A2TPath);
        AssetDatabase.SaveAssets();
    }
    /// <summary>
    /// 创建Mesh，储存骨骼索引和骨骼蒙皮权重到uv和顶点色（这两个是静态数据）
    /// </summary>
    public static void CreatNewMeshBones()
    {
        //存储骨骼索引到UV1的四个分量
        Vector4[] bonesUV1 = new Vector4[mesh.vertexCount];
        Vector4[] bonesWeightsUV2 = new Vector4[mesh.vertexCount];
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            bonesUV1[i] = new Vector4(mesh.boneWeights[i].boneIndex0 * 3,
                                    mesh.boneWeights[i].boneIndex1 * 3,
                                    mesh.boneWeights[i].boneIndex2 * 3,
                                    mesh.boneWeights[i].boneIndex3 * 3);
        }
        mesh.SetUVs(1, bonesUV1);

        //存储骨骼蒙皮权重到顶点颜色
        //Color[] verticesColor = new Color[mesh.vertexCount];
        for (int i = 0; i < mesh.vertexCount; i++)
        {
            bonesWeightsUV2[i] = new Vector4(mesh.boneWeights[i].weight0,
                                        mesh.boneWeights[i].weight1,
                                        mesh.boneWeights[i].weight2,
                                        mesh.boneWeights[i].weight3);
        }
        mesh.SetUVs(2, bonesWeightsUV2);
        //mesh.colors = verticesColor;
        AssetDatabase.CreateAsset(mesh, meshPath);
        AssetDatabase.SaveAssets();
    }
    #endregion

    //Options
    #region
    /// <summary>
    /// 保存路径
    /// </summary>
    private static void GetSavePath(GameObject prefab, string savePath, string savePrefabPath)
    {
        meshPath = savePath + "/" + prefab.name + "_VerticesAnimationMesh" + ".asset";
        A2TPath = savePath + "/" + prefab.name + "_VerticesAnimationTexture" + ".asset";
        matPath = savePath + "/" + prefab.name + "_VerticesAnimationMaterial" + ".mat";
        prefabPath = savePrefabPath + "/" + prefab.name + "_GpuAnim" + ".prefab";
    }
    /// <summary>
    ///获取SK，Mesh，clip文件
    /// </summary>
    public static void GetAnimationsData(AnimationClip[] clips, GameObject bakePrefab)
    {
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
    }
    /// <summary>
    /// 创建驱动动画的Animator
    /// </summary>
    public static void CreatAnimator(AnimationClip[] clips, int frame, GPUAnimMode mode)
    {
        int startFtame = 0;
        GpuAnimations = new GpuAnimations[clips.Length];
        for (int h = 0; h < clips.Length; h++)
        {
            GpuAnimations[h] = new GpuAnimations();
            GpuAnimations[h].animtionName = clips[h].name;
            if (h > 0) { startFtame += (int)(frame * clips[h - 1].length); }
            GpuAnimations[h].startFrame = startFtame;
            GpuAnimations[h].frameLength = (int)(frame * clips[h].length);
            GpuAnimations[h].isLoop = clips[h].isLooping;
        }
        gpuAnimator.animations = GpuAnimations;
        gpuAnimator.frame = frame;
        switch (mode)
        {
            case GPUAnimMode.GpuVerticesAnimation:
                break;
            case GPUAnimMode.GpuBonesAnimation:
                break;
        }
    }
    /// <summary>
    /// 创建材质
    /// </summary>
    public static void CreatMaterial(bool isNormalTangent, GPUAnimMode mode)
    {
        var GpuVertexAnimShader = Shader.Find("RoXami/GpuAnim");
        if (GpuVertexAnimShader == null)
        {
            Debug.LogError("Can't find GpuVertexAnim Shader to creat Material!");
            return;
        }
        mat = new Material(GpuVertexAnimShader);
        if (isNormalTangent)
        {
            mat.SetFloat("_isNormalTangent", 1);
        }
        mat.SetTexture("_gpuAnimationMatrix", AssetDatabase.LoadAssetAtPath<Texture2D>(A2TPath));
        switch (mode)
        {
            case GPUAnimMode.GpuVerticesAnimation:
                mat.SetFloat("_IsBonesOrVertices", 0);
                break;
            case GPUAnimMode.GpuBonesAnimation:
                mat.SetFloat("_IsBonesOrVertices", 1);
                break;
        }
        mat.enableInstancing = true;
        AssetDatabase.CreateAsset(mat, matPath);
        Debug.Log("Baked A2T File successfully at" + matPath);
    }
    /// <summary>
    /// 创建一个新的预制体
    /// </summary>
    public static void CreatNewPrefab(AnimationClip[] clips, int frame, GPUAnimMode mode)
    {

        AssetDatabase.SaveAssets();
        newPrefab = new GameObject();
        newPrefab.AddComponent<MeshFilter>().mesh = AssetDatabase.LoadAssetAtPath<Mesh>(meshPath);
        newPrefab.AddComponent<MeshRenderer>().material = AssetDatabase.LoadAssetAtPath<Material>(matPath);
        gpuAnimator = newPrefab.AddComponent<GpuAnimator>();

        CreatAnimator(clips, frame, mode);

        PrefabUtility.SaveAsPrefabAsset(newPrefab, prefabPath);
        AssetDatabase.SaveAssets();

        Debug.Log("Baked Prefab successfully at" + prefabPath);
    }
    #endregion
}
