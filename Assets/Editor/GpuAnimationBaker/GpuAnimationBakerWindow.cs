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
    public GPUAnimMode animMode;

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

        GuiSetFilePath();

        GUILayout.Space(10);

        GuiSetPrefabPath();

        GUILayout.Space(10);

        if (GUILayout.Button("Bake"))
        {
            switch (animMode)
            {
                case GPUAnimMode.GpuVerticesAnimation:
                    BuildGpuVerticesAnimation.BakeAnimToTexture2D(prefab, clips, frame, isNormalTangent, savePath, savePrefabPath);
                    break;
                case GPUAnimMode.GpuBonesAnimation:
                    BuildGpuBonesAnimation.BakeAnimToTexture2D(prefab, clips, frame, isNormalTangent, savePath, savePrefabPath);
                    break;
            }
            
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
    public void GuiSetFilePath()
    {
        GUILayout.Label("Set File Path", EditorStyles.boldLabel);
        // 设置文件路径
        GUILayout.BeginHorizontal();
        GUILayout.Label("File Path:", GUILayout.Width(75));
        savePath = EditorGUILayout.TextField(savePath);
        if (GUILayout.Button("Browse", GUILayout.Width(100)))
        {
            // 选择文件夹路径
            string selectedPath = EditorUtility.OpenFolderPanel("Select Folder", "Assets", "");
            if (!string.IsNullOrEmpty(selectedPath))
            {
                // 去除项目路径外的部分，确保路径是相对的
                savePath = "Assets" + selectedPath.Substring(UnityEngine.Application.dataPath.Length);
            }
        }
        GUILayout.EndHorizontal();
    }
    public void GuiSetPrefabPath()
    {
        GUILayout.Label("Set Prefab Path and Name", EditorStyles.boldLabel);
        // 设置文件路径
        GUILayout.BeginHorizontal();
        GUILayout.Label("Prefab Path:", GUILayout.Width(75));
        savePrefabPath = EditorGUILayout.TextField(savePrefabPath);
        if (GUILayout.Button("Browse", GUILayout.Width(100)))
        {
            // 选择文件夹路径
            string selectedPath = EditorUtility.OpenFolderPanel("Select Folder", "Assets", "");
            if (!string.IsNullOrEmpty(selectedPath))
            {
                // 去除项目路径外的部分，确保路径是相对的
                savePrefabPath = "Assets" + selectedPath.Substring(UnityEngine.Application.dataPath.Length);
            }
        }
        GUILayout.EndHorizontal();
    }
    public enum GPUAnimMode
    {
        GpuVerticesAnimation = 0,
        GpuBonesAnimation = 1,
    }

}
