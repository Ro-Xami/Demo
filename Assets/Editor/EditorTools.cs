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
    public static string GuiSetFilePath(string savePath , string fileName)
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
}
