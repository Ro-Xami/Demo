using UnityEngine;
using UnityEditor;
using System.IO;
using UnityEngine.UIElements;
using System.Collections.Generic;

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

    public List<GameObject> test;

    [MenuItem("RoXami Tools/GPU Animation/GpuAnim Baker 3D")]
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
        EditorTools.ViewList(_serializedObject, AnimationClipsProperty);
        frame = EditorGUILayout.IntField("AnimationFrame", frame);
        isNormalTangent = EditorGUILayout.Toggle("isNormalTangent", isNormalTangent);
        animMode = (GPUAnimMode)EditorGUILayout.EnumPopup("GPUAnimMode", animMode);

        GUILayout.Space(10);

        savePath = EditorTools.FilePath(savePath, "File");

        GUILayout.Space(10);

        savePrefabPath = EditorTools.FilePath(savePrefabPath, "Prefab");

        GUILayout.Space(10);

        if (GUILayout.Button("Bake"))
        {
            BuildGpuAnimation.BakeAnimToTexture2D(prefab, clips, frame, isNormalTangent, savePath, savePrefabPath, animMode);
        }

        ListView view = new ListView(test, 5)
        {
            selectionType = SelectionType.Multiple,
            showAddRemoveFooter = true,
            reorderable = true,
            reorderMode = ListViewReorderMode.Animated,
            showBorder = true,
            showBoundCollectionSize = true,
            showFoldoutHeader = true,
        };
    }
    //=====================================================GUI====================================================

    public enum GPUAnimMode
    {
        GpuVerticesAnimation = 0,
        GpuBonesAnimation = 1,
    }

}
