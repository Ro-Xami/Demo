using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomRenderPassFeature : ScriptableRendererFeature
{
    //自定义的Pass
    class CustomRenderPass : ScriptableRenderPass
    {
        const string ProfileTag = "自定义后处理 Custom Render Feature";
        ProfilingSampler m_ProfilerSampler = new(ProfileTag);

        public Material m_Material;
        public CustomVolume m_CustomVolume;
        public ScriptableRenderPassInput m_Input;
        RTHandle CameraColorTarget;
        RTHandle TempRT;

        public void GetTempRT(in RenderingData data)
            {
            RenderingUtils.ReAllocateIfNeeded(ref TempRT, data.cameraData.cameraTargetDescriptor);
        }
        public void SetUP(RTHandle cameraColor)
        {
            CameraColorTarget = cameraColor;
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureInput(m_Input);
            ConfigureTarget(CameraColorTarget);
        }

        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(ProfileTag);

            Vector4 TestColor = new Vector4()
            {
                x = m_CustomVolume.TestColor.value.r,
                y = m_CustomVolume.TestColor.value.g,
                z = m_CustomVolume.TestColor.value.b,
                w = m_CustomVolume.TestColor.value.a,
            };
            m_Material.SetColor("_Color", TestColor);
            m_Material.SetFloat("_MinFloat", m_CustomVolume.MinFloat.value);
            m_Material.SetFloat("_RangeFloat", m_CustomVolume.ClampFloat.value);

            using (new ProfilingScope(cmd, m_ProfilerSampler))
            {
                CoreUtils.SetRenderTarget(cmd, TempRT);
                Blitter.BlitTexture(cmd, CameraColorTarget, TempRT, m_Material, 0);
                CoreUtils.SetRenderTarget(cmd, CameraColorTarget);
                Blitter.BlitCameraTexture(cmd, CameraColorTarget, CameraColorTarget, m_Material, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            cmd.Dispose();
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            TempRT.Release();
        }
    }

    //------------------------------------------------------------------------------------------

    CustomRenderPass m_ScriptablePass;
    public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    public ScriptableRenderPassInput m_Input = ScriptableRenderPassInput.Color;
    VolumeStack m_VolumeStack;
    CustomVolume m_CustomVolume;
    Material m_Material;

    //在初始化的时候调用
    public override void Create()
    {
        m_VolumeStack = VolumeManager.instance.stack;
        m_CustomVolume = m_VolumeStack.GetComponent<CustomVolume>();

        var m_Shader = Shader.Find("Jian/CustomRenderFeature/CustomPost");
        if (m_Shader ==null)
        {
            Debug.LogError("Shader is null");
            return;
        }
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);

        m_ScriptablePass = new CustomRenderPass()
        {
            m_Material = m_Material,
            m_CustomVolume = m_CustomVolume,
            m_Input = m_Input,
            renderPassEvent = m_RenderPassEvent
        };
    }

    //每帧调用，将Pass添加进渲染流程
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldRender(in renderingData)) return;
        renderer.EnqueuePass(m_ScriptablePass);
        m_ScriptablePass.GetTempRT(in renderingData);
    }

    //设置pass调用
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        m_ScriptablePass.SetUP(renderer.cameraColorTargetHandle);
        //base.SetupRenderPasses(renderer, renderingData);
    }

    //清除渲染流程时调用
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

#if UNITY_EDITOR
        //如有需要,在此处销毁生成的资源,如Material等
        if (EditorApplication.isPlaying)
        {
            //Destroy(m_Material);
        }
        else
        {
            //DestroyImmediate(m_Material);
        }
#else
                      //Destroy(material);
#endif
    }
    bool ShouldRender(in RenderingData data)
    {
        if (!data.cameraData.postProcessEnabled || data.cameraData.cameraType != CameraType.Game)
        {
            return false;
        }
        if (m_ScriptablePass == null)
        {
            Debug.LogError($"RenderPass = null!");
            return false;
        }
        return true;
    }




    //-----------------------------------------------------------------------
    //渲染顺序
    //RF Create();

    //循环开始，每帧一轮
    //RF AddPass();
    //RF SetupRenderPass();
    //Pass OnCameraSetup();
    //Pass Exceute();
    //Pass OnCameraCleanup();
    //循环结束

    //RF Dispose();

}


