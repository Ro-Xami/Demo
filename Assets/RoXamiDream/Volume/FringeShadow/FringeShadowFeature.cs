using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FringeShadowFeature : ScriptableRendererFeature
{
    class FringeShadowRenderPass : ScriptableRenderPass
    {
        const string ProfileTag = "Fringe Shadow";
        ProfilingSampler m_ProfilerSampler = new(ProfileTag);

        public Material m_Material;
        RTHandle CameraColorTarget;
        RTHandle TempRT;
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

        }
        public override void OnCameraCleanup(CommandBuffer cmd)
        {

        }
    }

    FringeShadowRenderPass m_ScriptablePass;

    Material m_Material;
    public override void Create()
    {
        m_ScriptablePass = new FringeShadowRenderPass();
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

        var m_Shader = Shader.Find("");
        if (m_Shader != null)
        {
            Debug.LogError("Shader is null");
            return;
        }
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);

        m_ScriptablePass = new FringeShadowRenderPass()
        {
            m_Material = m_Material
        };
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


