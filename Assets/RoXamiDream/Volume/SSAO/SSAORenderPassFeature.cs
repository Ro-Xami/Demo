using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSAOPassRenderFeature : ScriptableRendererFeature
{
    //自定义的Pass
    class CustomRenderPass : ScriptableRenderPass
    {

        const string ProfileTag = "SSAO";
        ProfilingSampler m_ProfilerSampler = new(ProfileTag);

        public Material m_Material;
        public SSAOVolume m_CustomVolume;
        RTHandle CameraColorTarget;
        RTHandle SSAORT;

        private const string SSAOTex = "_VolumetricTex";

        public void GetTempRT(in RenderingData data)
        {
            var ColorDesc = data.cameraData.cameraTargetDescriptor;
            ColorDesc.depthBufferBits = 0;
            RenderingUtils.ReAllocateIfNeeded(ref SSAORT, ColorDesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: SSAOTex);

        }
        public void SetUP(RTHandle cameraColor)
        {
            CameraColorTarget = cameraColor;
        }

        //资源初始化
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureInput(ScriptableRenderPassInput.Color);
            ConfigureTarget(CameraColorTarget);
            ConfigureInput(ScriptableRenderPassInput.Normal);
            //ConfigureInput(ScriptableRenderPassInput.Depth);
        }

        //执行逻辑
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(ProfileTag);

            m_Material.SetFloat("_sampleCount", m_CustomVolume.sampleCount.value);
            m_Material.SetFloat("_radius", m_CustomVolume.radius.value);
            m_Material.SetFloat("_RangeCheck", m_CustomVolume.rangeCheck.value);
            m_Material.SetFloat("_AOInt", m_CustomVolume.aoInt.value);

            using (new ProfilingScope(cmd, m_ProfilerSampler))
            {
                Blitter.BlitCameraTexture(cmd, CameraColorTarget, SSAORT, m_Material, 0);
                Blit(cmd, SSAORT, CameraColorTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            cmd.Dispose();
        }

        //释放已分配的资源
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            //TempRT.Release();
        }

        public void Dispose()
        {
            SSAORT?.Release();
        }
    }

    //------------------------------------------------------------------------------------------

    CustomRenderPass m_ScriptablePass;
    public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    VolumeStack m_VolumeStack;
    SSAOVolume m_CustomVolume;
    private Material m_Material;

    //在初始化的时候调用
    public override void Create()
    {
        m_VolumeStack = VolumeManager.instance.stack;
        m_CustomVolume = m_VolumeStack.GetComponent<SSAOVolume>();

        var m_Shader = Shader.Find("RoXami/CustomRenderFeature/SSAO");
        if (m_Shader == null)
        {
            Debug.LogError("Shader is null");
            return;
        }
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);

        m_ScriptablePass = new CustomRenderPass()
        {
            m_Material = m_Material,
            m_CustomVolume = m_CustomVolume,
            renderPassEvent = m_RenderPassEvent
        };
    }

    //每帧调用，向管线中添加pass
    //可以对ScriptRenderPass排队，且可以将多个通道排队
    //避免访问相机目标，可能尚未被分配，在OnCameraSetup或SetupRenderPass中访问
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldRender(in renderingData)) return;
        renderer.EnqueuePass(m_ScriptablePass);//渲染通道排队
        m_ScriptablePass.GetTempRT(in renderingData);
    }

    //设置pass调用
    //当渲染目标被分配好并准备好使用时，将调用该函数
    //作用：获取渲染数据。（相机目标等）
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
            Destroy(m_Material);
        }
        else
        {
            DestroyImmediate(m_Material);
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

}


