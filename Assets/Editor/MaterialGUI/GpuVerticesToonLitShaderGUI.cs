using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;

public class GpuVerticesToonLitShaderGUI : ShaderGUI
{
    public MaterialEditor materialEditor;
    public MaterialProperty[] properties;

    public Material material;
    public string[] keyWords;

    bool receiveShadows = true;
    bool setNormal = true;
    bool setSrgb = true;

    bool isSurface = true;
    bool isPbr = true;
    bool isToonShading = true;
    bool isBrush = true;
    bool isAdvance = true;
    bool isPass = true;

    bool shadowCaster = true;
    bool depthOnly = true;
    bool depthNormals = true;

    SurfaceType surfaceType = SurfaceType.Opaque;
    BlendMode blendMode;
    CullMode cullMode = CullMode.back;
    ZWriteMode zWriteMode = 0;
    ZTestMode zTestMode = 0;

    bool isGpuAnim = true;
    //bool isNormalTangent = true;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //base.OnGUI(materialEditor, properties);
        this.materialEditor = materialEditor;
        this.properties = properties;
        this.material = materialEditor.target as Material;
        this.keyWords = material.shaderKeywords;

        Show();
    }

    public void Show()
    {
        //Surface Options
        isSurface = EditorGUILayout.BeginFoldoutHeaderGroup(isSurface, "Surface Options");
        if (isSurface)
        {
            //SurfaceType
            surfaceType = (SurfaceType)EditorGUILayout.EnumPopup("SurfaceType", surfaceType);
            SetsurfaceType(surfaceType);
            GUILayout.Space(2);
            //CullMode
            cullMode = (CullMode)EditorGUILayout.EnumPopup("CullMode", cullMode);
            SetCullMode(cullMode);
            GUILayout.Space(2);
            //Receive Shadows
            receiveShadows = EditorGUILayout.Toggle("Receive Shadows", receiveShadows);
            if (receiveShadows)
            {
                material.EnableKeyword("_ISSHADOW_ON");
            }
            else
            {
                material.DisableKeyword("_ISSHADOW_ON");
            }    
            
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        //PBR
        GUILayout.Space(20);
        isPbr = EditorGUILayout.BeginFoldoutHeaderGroup(isPbr, "Physically Based Rendering");
        if (isPbr)
        {
            //Base
            MaterialProperty color = FindProperty("_BaseColor", properties, true);
            MaterialProperty baseMap = FindProperty("_BaseMap", properties, true);
            GUIContent baseMapContent = new GUIContent(baseMap.displayName, baseMap.textureValue, "BaseMap");
            materialEditor.TexturePropertySingleLine(baseMapContent, baseMap, color);

            GUILayout.Space(2);
            //Normal
            MaterialProperty normalMap = FindProperty("_NormalMap", properties, true);
            MaterialProperty normalStrength = FindProperty("_normalStrength", properties, true);
            GUIContent normalMapContent = new GUIContent(normalMap.displayName, normalMap.textureValue, "NormalMap");

            if (normalMap != null && normalMap.textureValue != null)
            {
                string normalPath = AssetDatabase.GetAssetPath(normalMap.textureValue);
                TextureImporter normalImporter = AssetImporter.GetAtPath(normalPath) as TextureImporter;

                if (normalImporter.textureType != TextureImporterType.NormalMap)
                {
                    setNormal = materialEditor.HelpBoxWithButton(new GUIContent("Texture type needs to be Normal!"), new GUIContent("Fix Now"));
                }
                if (setNormal)
                {
                    setNormal = false;
                    normalImporter.textureType = TextureImporterType.NormalMap;
                    normalImporter.SaveAndReimport();
                }

                materialEditor.TexturePropertySingleLine(normalMapContent, normalMap, normalStrength);
                material.EnableKeyword("_ISNORMALMAP_ON");
            }
            else
            {
                materialEditor.TexturePropertySingleLine(normalMapContent, normalMap);
                material.DisableKeyword("_ISNORMALMAP_ON");
            }

            GUILayout.Space(2);
            //ARM
            MaterialProperty armMap = FindProperty("_MaskMap", properties, true);
            MaterialProperty ao = FindProperty("_ao", properties, true);
            MaterialProperty roughness = FindProperty("_roughness", properties, true);
            MaterialProperty metallic = FindProperty("_metallic", properties, true);

            if (armMap != null && armMap.textureValue != null)
            {
                material.EnableKeyword("_ISARMMAP_ON");

                string armPath = AssetDatabase.GetAssetPath(armMap.textureValue);
                TextureImporter armImporter = AssetImporter.GetAtPath(armPath) as TextureImporter;
                if (armImporter.sRGBTexture == true)
                {
                    setSrgb = materialEditor.HelpBoxWithButton(new GUIContent("Texture sRGB needs to be false!"), new GUIContent("Fix Now"));
                }
                if (setSrgb)
                {
                    setSrgb = false;
                    armImporter.sRGBTexture = false;
                    armImporter.SaveAndReimport();
                }
            }
            else
            {
                material.DisableKeyword("_ISARMMAP_ON");
            }

            GUIContent armContent = new GUIContent(armMap.displayName, armMap.textureValue, "ARM_Map");
            materialEditor.TexturePropertySingleLine(armContent, armMap);
            EditorGUI.indentLevel++;
            materialEditor.RangeProperty(ao, "Ao");
            materialEditor.RangeProperty(roughness, "Roughness");
            materialEditor.RangeProperty(metallic, "Metallic");

            EditorGUI.indentLevel--;
            GUILayout.Space(2);
            //Emission
            MaterialProperty emissionMap = FindProperty("_EmissionMap", properties, true);
            MaterialProperty emissionColor = FindProperty("_emissionColor", properties, true);

            if (emissionMap != null && emissionMap.textureValue != null)
            {
                material.EnableKeyword("_ISEMISSIONMAP_ON");
            }
            else
            {
                material.DisableKeyword("_ISEMISSIONMAP_ON");
            }

            GUIContent emissionContent = new GUIContent(emissionMap.displayName, emissionMap.textureValue, "EmissionMap");
            materialEditor.TexturePropertyWithHDRColor(emissionContent, emissionMap, emissionColor, true);

            GUILayout.Space(2);
            materialEditor.TextureScaleOffsetProperty(baseMap);
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        //ToonShading
        GUILayout.Space(20);
        isToonShading = EditorGUILayout.BeginFoldoutHeaderGroup(isToonShading, "Toon Shading");
        if (isToonShading)
        {
            MaterialProperty lightColor = FindProperty("_lightColor", properties, true);
            MaterialProperty shadowColor = FindProperty("_shadowColor", properties, true);
            MaterialProperty inSpecColor = FindProperty("_inSpecColor", properties, true);
            MaterialProperty specColor = FindProperty("_specColor", properties, true);
            MaterialProperty diffuseMin = FindProperty("_diffuseMin" , properties, true);
            MaterialProperty diffuseMax = FindProperty("_diffuseMax", properties, true);
            MaterialProperty specMin = FindProperty("_specMin", properties, true);
            MaterialProperty specMax = FindProperty("_specMax", properties, true);
            MaterialProperty InSpecMin = FindProperty("_inSpecMin", properties, true);
            MaterialProperty inSpecMax = FindProperty("_inSpecMax", properties, true);
            GUIContent diffuseContent = new GUIContent("Diffuse");
            GUIContent specContent = new GUIContent("Spec");
            GUIContent inSpecContent = new GUIContent("INSpec");

            materialEditor.ColorProperty(lightColor, "LightColor");
            materialEditor.ColorProperty(shadowColor, "ShadowColor");
            materialEditor.MinMaxShaderProperty(diffuseMin, diffuseMax, 0, 1, diffuseContent);
            GUILayout.Space(2);
            materialEditor.ColorProperty(specColor, "SpecColor");
            materialEditor.MinMaxShaderProperty(specMin, specMax, 0, 1, specContent);
            GUILayout.Space(2);
            materialEditor.ColorProperty(inSpecColor, "InSpecColor");
            materialEditor.MinMaxShaderProperty(InSpecMin, inSpecMax, 0, 1, inSpecContent);
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        //Brush
        GUILayout.Space(20);
        isBrush = EditorGUILayout.BeginFoldoutHeaderGroup(isBrush, "Toon Brush");
        if (isBrush)
        {
            MaterialProperty brushMap = FindProperty("", properties, true);
            MaterialProperty brushTransform = FindProperty("Transform", properties, true);
            MaterialProperty brushStrength = FindProperty("Strength", properties, true);
            if (brushMap != null && brushMap.textureValue != null)
            {
                material.EnableKeyword("_ISBRUSH_ON");
            }
            else
            {
                material.DisableKeyword("_ISBRUSH_ON");
            }
            GUIContent brushContent = new GUIContent(brushMap.displayName, brushMap.textureValue, "BrushMap");
            GUIContent brushStrengthContent = new GUIContent("BrushStrength");
            materialEditor.TexturePropertySingleLine(brushContent, brushMap);
            materialEditor.VectorProperty(brushTransform, "BrushTransform");
            materialEditor.Vector3ShaderProperty(brushStrength, brushStrengthContent);
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        //RenderPass
        GUILayout.Space(20);
        isPass = EditorGUILayout.BeginFoldoutHeaderGroup(isPass, "Enabel Render Pass");
        if (isPass)
        {
            shadowCaster = EditorGUILayout.Toggle("ShadowCaster" , shadowCaster);
            if(shadowCaster)
            {
                material.SetShaderPassEnabled("ShadowCaster", true);
            }
            else
            {
                material.SetShaderPassEnabled("ShadowCaster", false);
            }
            GUILayout.Space(2);

            depthOnly = EditorGUILayout.Toggle("DepthOnly" , depthOnly);
            if (depthOnly)
            {
                material.SetShaderPassEnabled("DepthOnly", true);
            }
            else
            {
                material.SetShaderPassEnabled("DepthOnly", false);
            }
            GUILayout.Space(2);

            depthNormals = EditorGUILayout.Toggle("DepthNormals" , depthNormals);
            if (depthNormals)
            {
                material.SetShaderPassEnabled("DepthNormals", true);
            }
            else
            {
                material.SetShaderPassEnabled("DepthNormals", false);
            }
            GUILayout.Space(2);
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        //GpuVerticesAnim
        GUILayout.Space(20);
        MaterialProperty verticesAnimTex = FindProperty("_verticesAnimTex", properties, true);
        isGpuAnim = EditorGUILayout.BeginFoldoutHeaderGroup(isGpuAnim, "GPU VerticesAnim");
        if (isGpuAnim)
        {
            //Base
            
            GUIContent verticesAnimTexContent = new GUIContent(verticesAnimTex.displayName, verticesAnimTex.textureValue, "VerticesAnimTex");
            materialEditor.TexturePropertySingleLine(verticesAnimTexContent, verticesAnimTex);
            GUILayout.Space(2);
            MaterialProperty frameIndex = FindProperty("_frameIndex", properties, true);
            materialEditor.FloatProperty(frameIndex, "Frame Index");

            MaterialProperty normalTangent = FindProperty("_isNormalTangent", properties, true);
            EditorGUI.BeginChangeCheck();
            var isNormalTangent = EditorGUILayout.Toggle("Enable NormalTangent", normalTangent.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                normalTangent.floatValue = isNormalTangent ? 1 : 0;
            }

            if (normalTangent.floatValue == 1)
            {
                material.EnableKeyword("_ISNORMALTANGENT_ON");
            }
            else
            {
                material.DisableKeyword("_ISNORMALTANGENT_ON");
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

        //Advance Options
        GUILayout.Space(20);
        isAdvance = EditorGUILayout.BeginFoldoutHeaderGroup(isAdvance, "Advance Options");
        if (isAdvance)
        {
            zWriteMode = (ZWriteMode)EditorGUILayout.EnumPopup("ZWriteMode", zWriteMode);
            SetZwrite(zWriteMode);
            GUILayout.Space(2);
            zTestMode = (ZTestMode)EditorGUILayout.EnumPopup("ZTestMode", zTestMode);
            SetZTest(zTestMode);
            GUILayout.Space(2);
            materialEditor.EnableInstancingField();
            materialEditor.RenderQueueField();
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

    }

    public enum SurfaceType
    {
        Opaque = 0,
        Transparent = 1,
        AlphaClip = 2,
    };

    public enum BlendMode
    {
        Alpha = 0,
        Premultiply = 1,
        Additive = 2,
        Multiply = 3,
    };

    public enum CullMode
    {
        off = 0,
        face = 1,
        back = 2,
    };

    public enum ZWriteMode
    {
        On = 0,
        Off = 1,
    };

    public enum ZTestMode
    {
        LessEqual = 0,
        GreaterEqual = 1,
        Always = 2,
        Never = 3,
    };

    public void SetsurfaceType(SurfaceType surType)
    {
        switch(surType)
        {
            case SurfaceType.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetOverrideTag("Queue", "Geometry");
                material.SetFloat("_SrcBlend", 1);
                material.SetFloat("_DstBlend", 0);
                material.DisableKeyword("_ISALPHACLIP_ON");
                break;
            case SurfaceType.Transparent:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetOverrideTag("Queue", "Transparent");
                material.DisableKeyword("_ISALPHACLIP_ON");
                EditorGUI.indentLevel++;
                blendMode = (BlendMode)EditorGUILayout.EnumPopup("BlendMode", blendMode);
                EditorGUI.indentLevel--;
                SetBlendMode(blendMode);

                break;
            case SurfaceType.AlphaClip:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetOverrideTag("Queue", "AlphaTest");
                material.SetFloat("_SrcBlend", 1);
                material.SetFloat("_DstBlend", 0);
                material.EnableKeyword("_ISALPHACLIP_ON");
                MaterialProperty cutOut = FindProperty("_cutOut", properties, true);
                EditorGUI.indentLevel++;
                materialEditor.RangeProperty(cutOut, "CutOut");
                EditorGUI.indentLevel--;
                break;
        }
    }

    public void SetBlendMode(BlendMode blendMode)
    {
        
        switch(blendMode)
        {
            case BlendMode.Alpha:
                material.SetFloat("_SrcBlend", 5);
                material.SetFloat("_DstBlend", 10);
                break;
            case BlendMode.Premultiply:
                material.SetFloat("_SrcBlend", 1);
                material.SetFloat("_DstBlend", 10);
                break;
            case BlendMode.Additive:
                material.SetFloat("_SrcBlend", 1);
                material.SetFloat("_DstBlend", 1);
                break;
            case BlendMode.Multiply:
                material.SetFloat("_SrcBlend", 2);
                material.SetFloat("_DstBlend", 0);
                break;
        }
    }

    public void SetCullMode(CullMode mode)
    {
        switch (mode)
        {
            case CullMode.off:
                material.SetFloat("_CullMode", 0);
                break;
            case CullMode.face:
                material.SetFloat("_CullMode", 1);
                break;
            case CullMode.back:
                material.SetFloat("_CullMode", 2);
                break;
        }
    }

    public void SetZwrite(ZWriteMode mode)
    {
        switch(mode)
        {
            case ZWriteMode.On:
                material.SetFloat("_ZWriteMode", 1);
                break;
            case ZWriteMode.Off:
                material.SetFloat("_ZWriteMode", 0);
                break;
        }
    }

    public void SetZTest(ZTestMode mode)
    {
        switch (mode)
        {
            case ZTestMode.LessEqual:
                material.SetFloat("_ZTestMode", 4);
                break;
            case ZTestMode.GreaterEqual:
                material.SetFloat("_ZTestMode", 7);
                break;
            case ZTestMode.Always:
                material.SetFloat("_ZTestMode", 8);
                break;
            case ZTestMode.Never:
                material.SetFloat("_ZTestMode", 1);
                break;
        }
    }
}
