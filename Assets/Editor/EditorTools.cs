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
    public static string GuiSetFilePath(string savePath , string fileName)
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
}
