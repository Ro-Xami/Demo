using UnityEngine;
using UnityEditor;
using System.IO;

public class GpuAnimationBakerWindow : EditorWindow
{
    public GameObject prefab;

    [SerializeField]//必须要加
    protected UnityEngine.AnimationClip[] clips;
    //序列化对象
    protected SerializedObject _serializedObject;
    //序列化属性
    protected SerializedProperty AnimationClipsProperty;

    public bool isNormalTangent = true;
    public GPUAnimMode animMode = GPUAnimMode.GpuBonesAnimation;

    public int frame = 60;
    public string savePath = "Asset";
    public string savePrefabPath = "Asset";

    [MenuItem("RoXamiTools/GpuAnimBaker3D")]
    public static void ShowWindow()
    {
        GetWindow<GpuAnimationBakerWindow>("GpuAnimBaker3D");
    }

    protected void OnEnable()
    {
        //使用当前类初始化
        _serializedObject = new SerializedObject(this);
        //获取当前类中可序列话的属性
        AnimationClipsProperty = _serializedObject.FindProperty("clips");
    }

    public void OnGUI()
    {
        prefab = (GameObject)EditorGUILayout.ObjectField("SkeletonMesh", prefab, typeof(GameObject), false);
        GuiSetAnimationClips();
        frame = EditorGUILayout.IntField("AnimationFrame", frame);
        isNormalTangent = EditorGUILayout.Toggle("isNormalTangent", isNormalTangent);
        animMode = (GPUAnimMode)EditorGUILayout.EnumPopup("GPUAnimMode", animMode);

        GUILayout.Space(10);

        savePath = EditorTools.GuiSetFilePath(savePath, "File");

        GUILayout.Space(10);

        savePrefabPath = EditorTools.GuiSetFilePath(savePrefabPath, "Prefab");

        GUILayout.Space(10);

        if (GUILayout.Button("Bake"))
        {
            BuildGpuAnimation.BakeAnimToTexture2D(prefab, clips, frame, isNormalTangent, savePath, savePrefabPath, animMode);
        }
    }
    //=====================================================GUI====================================================
    public void GuiSetAnimationClips()
    {
        //更新
        _serializedObject.Update();
        //开始检查是否有修改
        EditorGUI.BeginChangeCheck();
        //显示属性
        //第二个参数必须为true，否则无法显示子节点即List内容
        EditorGUILayout.PropertyField(AnimationClipsProperty, true);
        //结束检查是否有修改
        if (EditorGUI.EndChangeCheck())
        {//提交修改
            _serializedObject.ApplyModifiedProperties();
        }
    }
    public enum GPUAnimMode
    {
        GpuVerticesAnimation = 0,
        GpuBonesAnimation = 1,
    }

}
