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
        DistortionToggle = Foldout(DistortionToggle, "��ͼŤ��");
        if (DistortionToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Ť����ͼ"), _distortionMap);
            if (_distortionMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_distortionMap, "Ť����ͼ");

                m_MaterialEditor.ShaderProperty(_distortionStrength, "Ť��ǿ��");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_distortionSpeedU, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_distortionSpeedV, "�����ƶ��ٶ�");
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    private void MaskWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        MaskToggle = Foldout(MaskToggle, "����ͼ");
        if (MaskToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("����ͼ"), _maskMap);
            if (_maskMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_maskMap, "����ͼ");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_maskSpeedU, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_maskSpeedV, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_maskClip, "����ͼ�ü�");
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    private void DissolveWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        DissolveToggle = Foldout(DissolveToggle, "�ܽ�ͼ");
        if (DissolveToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("�ܽ�ͼ"), _dissolveMap);
            if (_dissolveMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_dissolveMap, "�ܽ�ͼ");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_dissolveSpeedU, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_dissolveSpeedV, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_dissolveSmooth, "�ܽ��Եƽ��");
                EditorGUILayout.EndVertical();

                m_MaterialEditor.ShaderProperty(_dissolve_Mask, "�Ƿ����ܽ�����");
                if (material.GetFloat("_dissolve_Mask") == 1)
                {
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("�ܽ�����ͼ"), _dissolveMask);
                    if (_dissolveMask.textureValue != null)
                    {
                        m_MaterialEditor.TextureProperty(_dissolveMask, "�ܽ�����ͼ");
                        m_MaterialEditor.ShaderProperty(_dissolveMaskClip, "����ͼ�ü�");
                    }
                }
            }

            m_MaterialEditor.ShaderProperty(_dissolve_Rim, "�ܽ��Ե");
            if (material.GetFloat("_dissolve_Rim") == 1)
            {
                m_MaterialEditor.ShaderProperty(_dissolveColor, "�ܽ��Ե��ɫ");
            }

            m_MaterialEditor.ShaderProperty(_dissolve_CustomData, "CustomData�����ܽ�");
            if (material.GetFloat("_dissolve_CustomData") == 1)
            {
                m_MaterialEditor.ShaderProperty(_dissolveClip, "�ܽ����");
            }
        }
        EditorGUI.indentLevel--;
        EditorGUILayout.EndVertical();
    }

    private void FresnelWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        FresnelToggle = Foldout(FresnelToggle, "������");
        if (FresnelToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(_fresnelColor, "��������ɫ");
            GUILayout.Space(5);
            m_MaterialEditor.ShaderProperty(_fresnelPower, "��������");
            GUILayout.Space(5);
            m_MaterialEditor.ShaderProperty(_fresnelScale, "�Ƿ���������ǿ��");
            GUILayout.Space(5);

            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    private void LightFlowWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        LightFlowToggle = Foldout(LightFlowToggle, "����");
        if (LightFlowToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("������ͼ"), _lightFlowMap, _lightFlowColor);
            if (_lightFlowMap.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_lightFlowMap, "������ͼ");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_lightFlowSpeedU, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_lightFlowSpeedV, "�����ƶ��ٶ�");
                EditorGUILayout.EndVertical();
            }
            EditorGUI.indentLevel--;
            m_MaterialEditor.ShaderProperty(_lightFlow_Mask, "�Ƿ���������ͼ");
            if (material.GetFloat("_lightFlow_Mask") == 1)
            {
                m_MaterialEditor.ShaderProperty(_lightFlowMaskClip, "����ͼ�ü�");
            }
        }
        EditorGUILayout.EndVertical();
    }

    private void VertexWindow(Material material)
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        VertexOffsetToggle = Foldout(VertexOffsetToggle, "�����û�");
        if (VertexOffsetToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("������ͼ"), _vertexOffsetMap);
            if (_vertexOffsetMap.textureValue != null)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.TextureScaleOffsetProperty(_vertexOffsetMap);
                EditorGUILayout.EndVertical();
                m_MaterialEditor.ShaderProperty(_vertexOffsetStrength, "����ƫ��ǿ��");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_vertexOffsetSpeedU, "�����ƶ��ٶ�");
                m_MaterialEditor.ShaderProperty(_vertexOffsetSpeedV, "�����ƶ��ٶ�");
                EditorGUILayout.EndVertical();
                m_MaterialEditor.ShaderProperty(_vertetxOffest_Mask, "�Ƿ�ʹ�ö�������ͼ");
                if (material.GetFloat("_vertetxOffest_Mask") == 1)
                {
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("����ͼ"), _vertexOffsetMask);
                    m_MaterialEditor.TextureProperty(_vertexOffsetMask, "����ͼ");
                    m_MaterialEditor.ShaderProperty(_vertexoffsetMaskClip, "����ͼ�ü�");
                }
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.EndVertical();
    }

    public void CommonSettingWindow()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        CommonSettingToggle = Foldout(CommonSettingToggle, "�ۺ�����");
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
        MainTexToggle = Foldout(MainTexToggle, "����ͼ");
        if (MainTexToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.TexturePropertySingleLine(new GUIContent("����ͼ"), _MainTex, _Color);
            if (_MainTex.textureValue != null)
            {
                m_MaterialEditor.TextureProperty(_MainTex, "����ͼ");
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                m_MaterialEditor.ShaderProperty(_Rotate, "�Ƿ�����ͼ��ת");
                if (material.GetFloat("_Rotate") == 1)
                {
                    EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                    m_MaterialEditor.ShaderProperty(_rotator, "��ͼ��ת");
                    EditorGUILayout.EndVertical();
                }
                m_MaterialEditor.ShaderProperty(_channal, "�Ƿ�ʹ��Rͨ����ΪAͨ��");
                m_MaterialEditor.ShaderProperty(_customDataMove, "��ͼ��������Custom Data");
                if (material.GetFloat("_customDataMove") == 0)
                {
                    EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                    m_MaterialEditor.ShaderProperty(_USpeed, "U����");
                    m_MaterialEditor.ShaderProperty(_VSpeed, "v����");
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
        BaseSettingToggle = Foldout(BaseSettingToggle, "��������");
        if (BaseSettingToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(_Cullmode, "�޳�ģʽ");
            m_MaterialEditor.ShaderProperty(_Zwrite, "�Ƿ����д��");
            m_MaterialEditor.ShaderProperty(_BlendMode, "ģʽѡ��add����alpha");

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
        MainFunctionToggle = Foldout(MainFunctionToggle, "���幦��");
        if (MainFunctionToggle)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(_distortion, "Ť��");
            m_MaterialEditor.ShaderProperty(_mask, "����");
            m_MaterialEditor.ShaderProperty(_dissolve, "�ܽ�");
            m_MaterialEditor.ShaderProperty(_fresnel, "������");
            m_MaterialEditor.ShaderProperty(_vertexOffset, "�����û�");
            m_MaterialEditor.ShaderProperty(_lightFlow, "����");
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