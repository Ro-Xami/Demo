using Autodesk.Fbx;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
public class RoXamiEffectGUI : ShaderGUI
{
    MaterialEditor m_MaterialEditor;

    static bool MainFunctionToggle , MainTexToggle, BaseSettingToggle , CommonSettingToggle = true;
    static bool DistortionToggle, MaskToggle, DissolveToggle, FresnelToggle, VertexOffsetToggle, LightFlowToggle = false;

    MaterialProperty _Cullmode, _BlendMode, _Zwrite,
        _Color, _MainTex, _Rotate, _rotator, _channal, _customDataMove, _USpeed, _VSpeed,
        _distortion, _mask, _dissolve, _fresnel, _vertexOffset, _lightFlow,
        _vertetxOffest_Mask, _dissolve_Mask, _dissolve_Rim, _dissolve_CustomData, _lightFlow_Mask,
        _distortionMap, _distortionStrength, _distortionSpeedU, _distortionSpeedV,
        _maskMap, _maskSpeedU, _maskSpeedV, _maskClip,
        _dissolveMap, _dissolveSpeedU, _dissolveSpeedV, _dissolveSmooth, _dissolveClip, _dissolveMask, _dissolveMaskClip, _dissolveColor,
        _fresnelColor, _fresnelScale, _fresnelPower,
        _vertexOffsetMap, _vertexOffsetStrength, _vertexOffsetSpeedU, _vertexOffsetSpeedV, _vertexOffsetMask, _vertexoffsetMaskClip,
        _lightFlowMap, _lightFlowColor, _lightFlowSpeedU, _lightFlowSpeedV, _lightFlowMask, _lightFlowMaskClip;




    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        FindProperties(properties);

        if (material.GetFloat("_MainFunction") == 1)
        {
            MainFuctionWindow();
        }

        BaseSettingWindow(material);

        MainTexturesWindow(material);

        if (material.GetFloat("_distortion") == 1) { DitortionWindow(); }

        if (material.GetFloat("_dissolve") == 1) { DissolveWindow(material); }
            
        if (material.GetFloat("_mask") == 1) { MaskWindow(); }
            
        if (material.GetFloat("_fresnel") == 1) { FresnelWindow(); }
            
        if (material.GetFloat("_vertexOffset") == 1) { VertexWindow(material); }
            
        if (material.GetFloat("_lightFlow") == 1) { LightFlowWindow(material); }

        CommonSettingWindow();
    }

    private void DitortionWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        DistortionToggle = Foldout(DistortionToggle, "贴图扭曲");
        if (DistortionToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("扭曲贴图"), _distortionMap);
            if (_distortionMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_distortionMap, "扭曲贴图");

                m_MaterialEditor.ShaderProperty(_distortionStrength, "扭曲强度");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_distortionSpeedU, "横向移动速度");
                m_MaterialEditor.ShaderProperty(_distortionSpeedV, "纵向移动速度");
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    private void MaskWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        MaskToggle = Foldout(MaskToggle, "遮罩图");
        if (MaskToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("遮罩图"), _maskMap);
            if (_maskMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_maskMap, "遮罩图");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_maskSpeedU, "横向移动速度");
                m_MaterialEditor.ShaderProperty(_maskSpeedV, "纵向移动速度");
                m_MaterialEditor.ShaderProperty(_maskClip, "遮罩图裁剪");
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    private void DissolveWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        DissolveToggle = Foldout(DissolveToggle, "溶解图");
        if (DissolveToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("溶解图"), _dissolveMap);
            if (_dissolveMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_dissolveMap, "溶解图");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_dissolveSpeedU, "横向移动速度");
                m_MaterialEditor.ShaderProperty(_dissolveSpeedV, "纵向移动速度");
                m_MaterialEditor.ShaderProperty(_dissolveSmooth, "溶解边缘平滑");
                EditorGUILayout.EndVertical();

                m_MaterialEditor.ShaderProperty(_dissolve_Mask, "是否开启溶解遮罩");
                if (material.GetFloat("_dissolve_Mask") == 1)
                {
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("溶解遮罩图"), _dissolveMask);
                    if (_dissolveMask.textureValue != null)
                    {
                        m_MaterialEditor.TextureProperty(_dissolveMask, "溶解遮罩图");
                        m_MaterialEditor.ShaderProperty(_dissolveMaskClip, "遮罩图裁剪");
                    }
                }
            }

            m_MaterialEditor.ShaderProperty(_dissolve_Rim, "溶解边缘");
            if (material.GetFloat("_dissolve_Rim") == 1)
            {
                m_MaterialEditor.ShaderProperty(_dissolveColor, "溶解边缘颜色");
            }

            m_MaterialEditor.ShaderProperty(_dissolve_CustomData, "CustomData控制溶解");
            if (material.GetFloat("_dissolve_CustomData") == 1)
            {
                m_MaterialEditor.ShaderProperty(_dissolveClip, "溶解控制");
            }
        }
        EditorGUI.indentLevel--;
        EditorGUILayout.EndVertical();
    }

    private void FresnelWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        FresnelToggle = Foldout(FresnelToggle, "菲涅尔");
        if (FresnelToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(_fresnelColor, "菲涅尔颜色");
            GUILayout.Space(5);
            m_MaterialEditor.ShaderProperty(_fresnelPower, "菲涅尔锐化");
            GUILayout.Space(5);
            m_MaterialEditor.ShaderProperty(_fresnelScale, "非菲涅尔部分强度");
            GUILayout.Space(5);

            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    private void LightFlowWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        LightFlowToggle = Foldout(LightFlowToggle, "流光");
        if (LightFlowToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("流光贴图"), _lightFlowMap, _lightFlowColor);
            if (_lightFlowMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_lightFlowMap, "流光贴图");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_lightFlowSpeedU, "横向移动速度");
                m_MaterialEditor.ShaderProperty(_lightFlowSpeedV, "纵向移动速度");
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
            m_MaterialEditor.ShaderProperty(_lightFlow_Mask, "是否启用遮罩图");
            if (material.GetFloat("_lightFlow_Mask") == 1)
            {
                m_MaterialEditor.ShaderProperty(_lightFlowMaskClip, "遮罩图裁剪");
            }
        }
        EditorGUILayout.EndVertical();
    }

    private void VertexWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        VertexOffsetToggle = Foldout(VertexOffsetToggle, "顶点置换");
        if (VertexOffsetToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("顶点贴图"), _vertexOffsetMap);
            if (_vertexOffsetMap.textureValue != null)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.TextureScaleOffsetProperty(_vertexOffsetMap);
                EditorGUILayout.EndVertical();
                m_MaterialEditor.ShaderProperty(_vertexOffsetStrength, "顶点偏移强度");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_vertexOffsetSpeedU, "横向移动速度");
                m_MaterialEditor.ShaderProperty(_vertexOffsetSpeedV, "纵向移动速度");
                EditorGUILayout.EndVertical();
                m_MaterialEditor.ShaderProperty(_vertetxOffest_Mask, "是否使用顶点遮罩图");
                if (material.GetFloat("_vertetxOffest_Mask") == 1)
                {
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("遮罩图"), _vertexOffsetMask);
                    m_MaterialEditor.TextureProperty(_vertexOffsetMask, "遮罩图");
                    m_MaterialEditor.ShaderProperty(_vertexoffsetMaskClip, "遮罩图裁剪");
                }
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    public void CommonSettingWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        CommonSettingToggle = Foldout(CommonSettingToggle, "综合设置");
        if (CommonSettingToggle)
        {
            EditorGUI.indentLevel++;
            EditorGUI.BeginChangeCheck();
            {
                MaterialProperty[] props = { };
                base.OnGUI(m_MaterialEditor, props);
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }
    public void MainTexturesWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        MainTexToggle = Foldout(MainTexToggle, "主贴图");
        if (MainTexToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("主贴图"), _MainTex, _Color);
            if (_MainTex.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_MainTex, "主贴图");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_Rotate, "是否开启贴图旋转");
                if (material.GetFloat("_Rotate") == 1)
                {
                    EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                    m_MaterialEditor.ShaderProperty(_rotator, "贴图旋转");
                    EditorGUILayout.EndVertical();
                }
                m_MaterialEditor.ShaderProperty(_channal, "是否使用R通道作为A通道");
                m_MaterialEditor.ShaderProperty(_customDataMove, "贴图流光来自Custom Data");
                if (material.GetFloat("_customDataMove") == 0)
                {
                    EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                    m_MaterialEditor.ShaderProperty(_USpeed, "U流动");
                    m_MaterialEditor.ShaderProperty(_VSpeed, "v流动");
                    EditorGUILayout.EndVertical();
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }
    public void BaseSettingWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        BaseSettingToggle = Foldout(BaseSettingToggle, "基础设置");
        if (BaseSettingToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(_Cullmode, "剔除模式");
            m_MaterialEditor.ShaderProperty(_Zwrite, "是否深度写入");
            m_MaterialEditor.ShaderProperty(_BlendMode, "模式选择add或者alpha");

            var src = BlendMode.One;
            var dst = BlendMode.OneMinusSrcAlpha;
            if (material.GetFloat("_BlendMode") == 0)
            {
                src = BlendMode.One;
                dst = BlendMode.One;
            }
            else if (material.GetFloat("_BlendMode") == 1)
            {
                src = BlendMode.SrcAlpha;
                dst = BlendMode.OneMinusSrcAlpha;
            }
            material.SetInt("_SrcBlend", (int)src);
            material.SetInt("_DstBlend", (int)dst);
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }
    public void MainFuctionWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        MainFunctionToggle = Foldout(MainFunctionToggle, "主体功能");
        if (MainFunctionToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(_distortion, "扭曲");
            m_MaterialEditor.ShaderProperty(_mask, "遮罩");
            m_MaterialEditor.ShaderProperty(_dissolve, "溶解");
            m_MaterialEditor.ShaderProperty(_fresnel, "菲涅尔");
            m_MaterialEditor.ShaderProperty(_vertexOffset, "顶点置换");
            m_MaterialEditor.ShaderProperty(_lightFlow, "流光");
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }
    void FindProperties(MaterialProperty[] properties)
    {
        _Cullmode = FindProperty("_Cullmode", properties);
        _BlendMode = FindProperty("_BlendMode", properties);
        _Zwrite = FindProperty("_Zwrite", properties);
        _Color = FindProperty("_Color", properties);
        _MainTex = FindProperty("_MainTex", properties);
        _Rotate = FindProperty("_Rotate", properties);
        _rotator = FindProperty("_rotator", properties);
        _channal = FindProperty("_channal", properties);
        _customDataMove = FindProperty("_customDataMove", properties);
        _USpeed = FindProperty("_USpeed", properties);
        _VSpeed = FindProperty("_VSpeed", properties);
        _distortion = FindProperty("_distortion", properties);
        _mask = FindProperty("_mask", properties);
        _dissolve = FindProperty("_dissolve", properties);
        _fresnel = FindProperty("_fresnel", properties);
        _vertexOffset = FindProperty("_vertexOffset", properties);
        _lightFlow = FindProperty("_lightFlow", properties);
        _vertetxOffest_Mask = FindProperty("_vertetxOffest_Mask", properties);
        _dissolve_Mask = FindProperty("_dissolve_Mask", properties);
        _dissolve_Rim = FindProperty("_dissolve_Rim", properties);
        _dissolve_CustomData = FindProperty("_dissolve_CustomData", properties);
        _lightFlow_Mask = FindProperty("_lightFlow_Mask", properties);
        _distortionMap = FindProperty("_distortionMap", properties);
        _distortionStrength = FindProperty("_distortionStrength", properties);
        _distortionSpeedU = FindProperty("_distortionSpeedU", properties);
        _distortionSpeedV = FindProperty("_distortionSpeedV", properties);
        _maskMap = FindProperty("_maskMap", properties);
        _maskSpeedU = FindProperty("_maskSpeedU", properties);
        _maskSpeedV = FindProperty("_maskSpeedV", properties);
        _maskClip = FindProperty("_maskClip", properties);
        _dissolveMap = FindProperty("_dissolveMap", properties);
        _dissolveSpeedU = FindProperty("_dissolveSpeedU", properties);
        _dissolveSpeedV = FindProperty("_dissolveSpeedV", properties);
        _dissolveSmooth = FindProperty("_dissolveSmooth", properties);
        _dissolveClip = FindProperty("_dissolveClip", properties);
        _dissolveMask = FindProperty("_dissolveMask", properties);
        _dissolveMaskClip = FindProperty("_dissolveMaskClip", properties);
        _dissolveColor = FindProperty("_dissolveColor", properties);
        _fresnelColor = FindProperty("_fresnelColor", properties);
        _fresnelScale = FindProperty("_fresnelScale", properties);
        _fresnelPower = FindProperty("_fresnelPower", properties);
        _vertexOffsetMap = FindProperty("_vertexOffsetMap", properties);
        _vertexOffsetStrength = FindProperty("_vertexOffsetStrength", properties);
        _vertexOffsetSpeedU = FindProperty("_vertexOffsetSpeedU", properties);
        _vertexOffsetSpeedV = FindProperty("_vertexOffsetSpeedV", properties);
        _vertexOffsetMask = FindProperty("_vertexOffsetMask", properties);
        _vertexoffsetMaskClip = FindProperty("_vertexoffsetMaskClip", properties);
        _lightFlowMap = FindProperty("_lightFlowMap", properties);
        _lightFlowColor = FindProperty("_lightFlowColor", properties);
        _lightFlowSpeedU = FindProperty("_lightFlowSpeedU", properties);
        _lightFlowSpeedV = FindProperty("_lightFlowSpeedV", properties);
        _lightFlowMask = FindProperty("_lightFlowMask", properties);
        _lightFlowMaskClip = FindProperty("_lightFlowMaskClip", properties);
    }
    static bool Foldout(bool display, string title)
    {
        var style = new GUIStyle();
        style.font = new GUIStyle(EditorStyles.boldLabel).font;
        style.border = new RectOffset(15, 15, 4, 4);
        style.fixedHeight = 22;
        style.contentOffset = new Vector2(20f, 3f);
        style.fontSize = 11;
        style.normal.textColor = new Color(0.0f, 0.0f, 0.0f);

        var rect = GUILayoutUtility.GetRect(16f, 25f, style);
        GUI.Box(rect, title, style);

        var e = Event.current;

        var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
        if (e.type == EventType.Repaint)
        {
            EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
        }
        if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
        {
            display = !display;
            e.Use();
        }
        return display;
    }
}