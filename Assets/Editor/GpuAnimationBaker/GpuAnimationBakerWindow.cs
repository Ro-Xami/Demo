using UnityEngine;
using UnityEditor;
using System.IO;

public class GpuAnimationBakerWindow : EditorWindow
{
    public GameObject prefab;

    [SerializeField]//����Ҫ��
    protected UnityEngine.AnimationClip[] clips;
    //���л�����
    protected SerializedObject _serializedObject;
    //���л�����
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
        //ʹ�õ�ǰ���ʼ��
        _serializedObject = new SerializedObject(this);
        //��ȡ��ǰ���п����л�������
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
        //����
        _serializedObject.Update();
        //��ʼ����Ƿ����޸�
        EditorGUI.BeginChangeCheck();
        //��ʾ����
        //�ڶ�����������Ϊtrue�������޷���ʾ�ӽڵ㼴List����
        EditorGUILayout.PropertyField(AnimationClipsProperty, true);
        //��������Ƿ����޸�
        if (EditorGUI.EndChangeCheck())
        {//�ύ�޸�
            _serializedObject.ApplyModifiedProperties();
        }
    }
    public void GuiSetFilePath()
    {
        GUILayout.Label("Set File Path", EditorStyles.boldLabel);
        // �����ļ�·��
        GUILayout.BeginHorizontal();
        GUILayout.Label("File Path:", GUILayout.Width(75));
        savePath = EditorGUILayout.TextField(savePath);
        if (GUILayout.Button("Browse", GUILayout.Width(100)))
        {
            // ѡ���ļ���·��
            string selectedPath = EditorUtility.OpenFolderPanel("Select Folder", "Assets", "");
            if (!string.IsNullOrEmpty(selectedPath))
            {
                // ȥ����Ŀ·����Ĳ��֣�ȷ��·������Ե�
                savePath = "Assets" + selectedPath.Substring(UnityEngine.Application.dataPath.Length);
            }
        }
        GUILayout.EndHorizontal();
    }
    public void GuiSetPrefabPath()
    {
        GUILayout.Label("Set Prefab Path and Name", EditorStyles.boldLabel);
        // �����ļ�·��
        GUILayout.BeginHorizontal();
        GUILayout.Label("Prefab Path:", GUILayout.Width(75));
        savePrefabPath = EditorGUILayout.TextField(savePrefabPath);
        if (GUILayout.Button("Browse", GUILayout.Width(100)))
        {
            // ѡ���ļ���·��
            string selectedPath = EditorUtility.OpenFolderPanel("Select Folder", "Assets", "");
            if (!string.IsNullOrEmpty(selectedPath))
            {
                // ȥ����Ŀ·����Ĳ��֣�ȷ��·������Ե�
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
