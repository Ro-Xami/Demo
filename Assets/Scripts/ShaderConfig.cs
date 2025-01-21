using UnityEngine;

[CreateAssetMenu(fileName = "ShaderConfig", menuName = "Config/Shader", order = 1)]
public class ShaderConfig : ScriptableObject
{
    public string playerName = "ShaderConfig";
    public Texture2D toonBrush;

}