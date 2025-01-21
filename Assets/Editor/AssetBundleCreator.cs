using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace XM.Editor
  {
      public class AssetBundleCreator : EditorWindow
      {
          [MenuItem("Tools/Build Asset Bundle")]
         public static void BuildAssetBundle()
         {
             var win = GetWindow<AssetBundleCreator>("Build Asset Bundle");
             win.Show();
         }
 
         [SerializeField]//����Ҫ��
         protected List<UnityEngine.Object> _assetLst = new List<UnityEngine.Object>();
 
         //���л�����
         protected SerializedObject _serializedObject;
 
         //���л�����
        protected SerializedProperty _assetLstProperty;


        protected void OnEnable()
         {
             //ʹ�õ�ǰ���ʼ��
             _serializedObject = new SerializedObject(this);
             //��ȡ��ǰ���п����л�������
             _assetLstProperty = _serializedObject.FindProperty("_assetLst");
       }

       protected void OnGUI()
       {
            //����
             _serializedObject.Update();

            //��ʼ����Ƿ����޸�
             EditorGUI.BeginChangeCheck();

             //��ʾ����
             //�ڶ�����������Ϊtrue�������޷���ʾ�ӽڵ㼴List����
            EditorGUILayout.PropertyField(_assetLstProperty, true);

             //��������Ƿ����޸�
             if (EditorGUI.EndChangeCheck())
             {//�ύ�޸�
                 _serializedObject.ApplyModifiedProperties();
             }
         }
     }
}