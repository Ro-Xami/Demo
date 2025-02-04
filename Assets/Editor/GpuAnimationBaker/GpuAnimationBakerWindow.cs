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
    public enum GPUAnimMode
    {
        GpuVerticesAnimation = 0,
        GpuBonesAnimation = 1,
    }

}
