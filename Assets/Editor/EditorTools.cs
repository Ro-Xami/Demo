using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public static class EditorTools
{
    /// <summary>
    /// �����ļ�����·��
    /// </summary>
    /// <param name="·��"></param>
    /// <param name="����ϵ�����"></param>
    /// <returns></returns>
    public static string FilePath(string savePath , string fileName)
    {
        GUILayout.Label("Set " + fileName + " Path", EditorStyles.boldLabel);
        // �����ļ�·��
        GUILayout.BeginHorizontal();
        GUILayout.Label(fileName + " Path:", GUILayout.Width(75));
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
        return savePath;
    }
    /// <summary>
    /// �����б�
    /// </summary>
    /// <param name="serializedObject"></param>
    /// <param name="serializedProperty"></param>
    public static void ViewList(SerializedObject serializedObject, SerializedProperty serializedProperty)
    {
        //����
        serializedObject.Update();
        //��ʼ����Ƿ����޸�
        EditorGUI.BeginChangeCheck();
        //��ʾ����
        //�ڶ�����������Ϊtrue�������޷���ʾ�ӽڵ㼴List����
        EditorGUILayout.PropertyField(serializedProperty, true);
        //��������Ƿ����޸�
        if (EditorGUI.EndChangeCheck())
        {//�ύ�޸�
            serializedObject.ApplyModifiedProperties();
        }
    }
    /// <summary>
    /// �����б�
    /// </summary>
    /// <param name="serializedObject"></param>
    /// <param name="serializedProperty"></param>
    /// <param name="scrollPosition"></param>
    /// <param name="height"></param>
    public static void ViewListWidthScroll(SerializedObject serializedObject, SerializedProperty serializedProperty,ref Vector2 scrollPosition , int height)
    {
        // �������л�����
        serializedObject.Update();
        // ��ʼ����Ƿ����޸�
        EditorGUI.BeginChangeCheck();
        // ��ʼ������ͼ
        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition, GUILayout.Height(height)); // ���ù�������ĸ߶�
        // ��ʾ����
        // �ڶ�����������Ϊ true�������޷���ʾ�ӽڵ㼴 List ����
        EditorGUILayout.PropertyField(serializedProperty, true);
        // ����������ͼ
        EditorGUILayout.EndScrollView();
        // ��������Ƿ����޸�
        if (EditorGUI.EndChangeCheck())
        {
            // �ύ�޸�
            serializedObject.ApplyModifiedProperties();
        }
    }
    /// <summary>
    /// ��ȡѡ����ʲ�
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="selectedAssets"></param>
    public static void GetSelectedAssets<T>(ref T[] selectedAssets , string name) where T : UnityEngine.Object
    {
        if (GUILayout.Button("Collect Selection " + name))
        {
            // ��ȡѡ�е����ж���
            UnityEngine.Object[] selectedObjects = Selection.objects;
            List<T> assets = new List<T>();

            // ����ѡ�еĶ��󲢽������ͼ��
            foreach (UnityEngine.Object obj in selectedObjects)
            {
                if (obj is T asset)
                {
                    assets.Add(asset);
                }
            }

            // ת��Ϊ���鲢��ֵ
            selectedAssets = assets.ToArray();
        }
    }
    /// <summary>
    /// ����������ȡ��ѵķ�����
    /// </summary>
    /// <param name="number"></param>
    /// <param name="width"></param>
    /// <param name="height"></param>
    public static void GetBestMatrix(int n, ref int x, ref int y)
    {
        if (n <= 0)
        {
            Debug.LogError("n must be greater than 0.");
            return;
        }

        // �����ʼ X ֵ����n ���������֣�
        x = Mathf.FloorToInt(Mathf.Sqrt(n));
        y = Mathf.CeilToInt((float)n / x);

        // ���� X �� Y��ʹ X �� Y �����ӽ�
        while (x * y > n && x > 1)
        {
            x--;
            y = Mathf.CeilToInt((float)n / x);
        }
    }
    /// <summary>
    /// ͼƬԤ��
    /// </summary>
    /// <param name="tex"></param>
    public static void TextureViewer(Texture2D tex)
    {
        // ����һ���Զ���ı�����ʽ
        GUIStyle titleStyle = new GUIStyle(EditorStyles.boldLabel);
        titleStyle.fontSize = 25;
        // ��������λ����ʹ�����
        Rect tRect = EditorGUILayout.GetControlRect(GUILayout.Height(50), GUILayout.Width(Screen.width)); // ʹ���������ڿ��������
        float titleWidth = titleStyle.CalcSize(new GUIContent("Texture Viewer")).x; // �������Ŀ��
        Rect centeredRect = new Rect((tRect.x + (tRect.width - titleWidth) / 2), tRect.y, titleWidth, tRect.height);
        GUI.Label(centeredRect, "Texture Viewer", titleStyle);

        if (tex != null)
        {
            // ����ͼƬ�Ĵ�С����Ӧ����
            float aspectRatio = (float)tex.width / tex.height;
            float maxHeight = Screen.height * 0.5f; // ���߶�ռ��Ļ�߶ȵ�һ��
            float maxWidth = maxHeight * aspectRatio;
            if (maxWidth > Screen.width * 0.8f) // �����ȳ������ڿ�ȵ�80%����ʹ�ô��ڿ�ȵ�80%��Ϊ�����
            {
                maxWidth = Screen.width * 0.8f;
                maxHeight = maxWidth / aspectRatio;
            }
            // ���ƺ�ɫ����
            Rect imageRect = new Rect((Screen.width - maxWidth) / 2, centeredRect.y + centeredRect.height + 10, maxWidth, maxHeight);
            GUI.DrawTexture(new Rect(imageRect.x - 5, imageRect.y - 5, imageRect.width + 10, imageRect.height + 10), Texture2D.whiteTexture);
            GUI.color = new Color(0.1f, 0.1f, 0.1f, 1f);
            GUI.DrawTexture(new Rect(imageRect.x - 5, imageRect.y - 5, imageRect.width + 10, imageRect.height + 10), Texture2D.whiteTexture);
            GUI.color = Color.white;
            // ����ͼƬ
            GUI.DrawTexture(imageRect, tex);

            GUILayout.Space(imageRect.height + 40);
        }
    }

    public static void NewGradient(ref Gradient gradient)
    {
        gradient = new Gradient();
        gradient.colorKeys = new GradientColorKey[]
        {
            new GradientColorKey(Color.red , 0f),
            new GradientColorKey(Color.green , 1f),
        };
        gradient.alphaKeys = new GradientAlphaKey[]
        {
            new GradientAlphaKey(1f,0f),
            new GradientAlphaKey(1f,1f),
        };
    }
}
