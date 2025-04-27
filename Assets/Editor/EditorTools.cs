using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public static class EditorTools
{
    /// <summary>
    /// 设置文件保存路径
    /// </summary>
    /// <param name="路径"></param>
    /// <param name="面板上的名字"></param>
    /// <returns></returns>
    public static string FilePath(string savePath , string fileName)
    {
        GUILayout.Label("Set " + fileName + " Path", EditorStyles.boldLabel);
        // 设置文件路径
        GUILayout.BeginHorizontal();
        GUILayout.Label(fileName + " Path:", GUILayout.Width(75));
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
        return savePath;
    }
    /// <summary>
    /// 可视列表
    /// </summary>
    /// <param name="serializedObject"></param>
    /// <param name="serializedProperty"></param>
    public static void ViewList(SerializedObject serializedObject, SerializedProperty serializedProperty)
    {
        //更新
        serializedObject.Update();
        //开始检查是否有修改
        EditorGUI.BeginChangeCheck();
        //显示属性
        //第二个参数必须为true，否则无法显示子节点即List内容
        EditorGUILayout.PropertyField(serializedProperty, true);
        //结束检查是否有修改
        if (EditorGUI.EndChangeCheck())
        {//提交修改
            serializedObject.ApplyModifiedProperties();
        }
    }
    /// <summary>
    /// 可视列表
    /// </summary>
    /// <param name="serializedObject"></param>
    /// <param name="serializedProperty"></param>
    /// <param name="scrollPosition"></param>
    /// <param name="height"></param>
    public static void ViewListWidthScroll(SerializedObject serializedObject, SerializedProperty serializedProperty,ref Vector2 scrollPosition , int height)
    {
        // 更新序列化对象
        serializedObject.Update();
        // 开始检查是否有修改
        EditorGUI.BeginChangeCheck();
        // 开始滚动视图
        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition, GUILayout.Height(height)); // 设置滚动区域的高度
        // 显示属性
        // 第二个参数必须为 true，否则无法显示子节点即 List 内容
        EditorGUILayout.PropertyField(serializedProperty, true);
        // 结束滚动视图
        EditorGUILayout.EndScrollView();
        // 结束检查是否有修改
        if (EditorGUI.EndChangeCheck())
        {
            // 提交修改
            serializedObject.ApplyModifiedProperties();
        }
    }
    /// <summary>
    /// 获取选择的资产
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="selectedAssets"></param>
    public static void GetSelectedAssets<T>(ref T[] selectedAssets , string name) where T : UnityEngine.Object
    {
        if (GUILayout.Button("Collect Selection " + name))
        {
            // 获取选中的所有对象
            UnityEngine.Object[] selectedObjects = Selection.objects;
            List<T> assets = new List<T>();

            // 遍历选中的对象并进行类型检查
            foreach (UnityEngine.Object obj in selectedObjects)
            {
                if (obj is T asset)
                {
                    assets.Add(asset);
                }
            }

            // 转换为数组并赋值
            selectedAssets = assets.ToArray();
        }
    }
    /// <summary>
    /// 根据数量获取最佳的方阵宽高
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

        // 计算初始 X 值（√n 的整数部分）
        x = Mathf.FloorToInt(Mathf.Sqrt(n));
        y = Mathf.CeilToInt((float)n / x);

        // 调整 X 和 Y，使 X 和 Y 尽量接近
        while (x * y > n && x > 1)
        {
            x--;
            y = Mathf.CeilToInt((float)n / x);
        }
    }
    /// <summary>
    /// 图片预览
    /// </summary>
    /// <param name="tex"></param>
    public static void TextureViewer(Texture2D tex)
    {
        // 创建一个自定义的标题样式
        GUIStyle titleStyle = new GUIStyle(EditorStyles.boldLabel);
        titleStyle.fontSize = 25;
        // 计算标题的位置以使其居中
        Rect tRect = EditorGUILayout.GetControlRect(GUILayout.Height(50), GUILayout.Width(Screen.width)); // 使用整个窗口宽度来居中
        float titleWidth = titleStyle.CalcSize(new GUIContent("Texture Viewer")).x; // 计算标题的宽度
        Rect centeredRect = new Rect((tRect.x + (tRect.width - titleWidth) / 2), tRect.y, titleWidth, tRect.height);
        GUI.Label(centeredRect, "Texture Viewer", titleStyle);

        if (tex != null)
        {
            // 计算图片的大小以适应窗口
            float aspectRatio = (float)tex.width / tex.height;
            float maxHeight = Screen.height * 0.5f; // 最大高度占屏幕高度的一半
            float maxWidth = maxHeight * aspectRatio;
            if (maxWidth > Screen.width * 0.8f) // 如果宽度超过窗口宽度的80%，则使用窗口宽度的80%作为最大宽度
            {
                maxWidth = Screen.width * 0.8f;
                maxHeight = maxWidth / aspectRatio;
            }
            // 绘制黑色背景
            Rect imageRect = new Rect((Screen.width - maxWidth) / 2, centeredRect.y + centeredRect.height + 10, maxWidth, maxHeight);
            GUI.DrawTexture(new Rect(imageRect.x - 5, imageRect.y - 5, imageRect.width + 10, imageRect.height + 10), Texture2D.whiteTexture);
            GUI.color = new Color(0.1f, 0.1f, 0.1f, 1f);
            GUI.DrawTexture(new Rect(imageRect.x - 5, imageRect.y - 5, imageRect.width + 10, imageRect.height + 10), Texture2D.whiteTexture);
            GUI.color = Color.white;
            // 绘制图片
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
