using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumetricLightingRenderPassFeature : ScriptableRendererFeature
{
    //�Զ����Pass
    class CustomRenderPass : ScriptableRenderPass
    {

        const string ProfileTag = "VolumeTricLighting";
        ProfilingSampler m_ProfilerSampler = new(ProfileTag);

        public Material m_Material;
        public VolumetricLightingVolume m_CustomVolume;
        RTHandle CameraColorTarget;
        RTHandle VolumetricRT;
        RTHandle BlurRT;
        RTHandle CombineRT;
        private const string VolumetricTex = "_VolumetricTex";
        private const string BlurTex = "_BlurTex";

        public void GetTempRT(in RenderingData data)
        {
            var ColorDesc = data.cameraData.cameraTargetDescriptor;
            ColorDesc.depthBufferBits = 0;
            RenderingUtils.ReAllocateIfNeeded(ref VolumetricRT, ColorDesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: VolumetricTex);
            RenderingUtils.ReAllocateIfNeeded(ref BlurRT, ColorDesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: BlurTex);
            RenderingUtils.ReAllocateIfNeeded(ref CombineRT, ColorDesc);
        }
        public void SetUP(RTHandle cameraColor)
        {
            CameraColorTarget = cameraColor;
        }

        //��Դ��ʼ��
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureInput(ScriptableRenderPassInput.Color);
            ConfigureInput(ScriptableRenderPassInput.Depth);
            ConfigureTarget(CameraColorTarget);
        }

        //ִ���߼�
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(ProfileTag);

            Vector4 VolumetricColor = new Vector4()
            {
                x = m_CustomVolume.VolumetricColor.value.r,
                y = m_CustomVolume.VolumetricColor.value.g,
                z = m_CustomVolume.VolumetricColor.value.b,
                w = m_CustomVolume.VolumetricColor.value.a,
            };
            m_Material.SetColor("_VolumetricColor", VolumetricColor);
            m_Material.SetFloat("_MaxDistance", m_CustomVolume.MaxDistance.value);
            m_Material.SetFloat("_StepSize", m_CustomVolume.StepSize.value);
            m_Material.SetFloat("_MaxStepSize", m_CustomVolume.MaxStepSize.value);
            m_Material.SetFloat("_LightIntensity", m_CustomVolume.LightIntensity.value);
            m_Material.SetFloat("_LightPower", m_CustomVolume.LightPower.value);
            m_Material.SetFloat("_BlurInt", m_CustomVolume.BlurRange.value);

            using (new ProfilingScope(cmd, m_ProfilerSampler))
            {
                //��������Ⲣ�������
                Blit(cmd, CameraColorTarget, VolumetricRT);
                Blitter.BlitTexture(cmd, CameraColorTarget, VolumetricRT, m_Material, 0);
                m_Material.SetTexture(VolumetricRT.name, VolumetricRT); 
                //ģ������Ⲣ�������
                for (int i =0; i <= m_CustomVolume.BlurNumber.value; i++)
                {
                    Blitter.BlitTexture(cmd, CameraColorTarget, BlurRT, m_Material, 1);
                    Blit(cmd, BlurRT, VolumetricRT);
                }
                m_Material.SetTexture(BlurRT.name, BlurRT);
                //�ϲ�ģ�������������ɫ��ͼ
                Blitter.BlitCameraTexture(cmd, CameraColorTarget, CombineRT, m_Material, 2);
                Blit(cmd, CombineRT, CameraColorTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            cmd.Dispose();
        }

        //�ͷ��ѷ������Դ
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            //TempRT.Release();
        }

        public void Dispose()
        {
            VolumetricRT?.Release();
            BlurRT?.Release();
            CombineRT?.Release();
        }
    }

    //------------------------------------------------------------------------------------------

    CustomRenderPass m_ScriptablePass;
    public RenderPassEvent m_RenderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    VolumeStack m_VolumeStack;
    VolumetricLightingVolume m_CustomVolume;
    private Material m_Material;

    //�ڳ�ʼ����ʱ�����
    public override void Create()
    {
        m_VolumeStack = VolumeManager.instance.stack;
        m_CustomVolume = m_VolumeStack.GetComponent<VolumetricLightingVolume>();

        var m_Shader = Shader.Find("RoXami/CustomRenderFeature/VolumetricLighting");
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

    //ÿ֡���ã�����������pass
    //���Զ�ScriptRenderPass�Ŷӣ��ҿ��Խ����ͨ���Ŷ�
    //����������Ŀ�꣬������δ�����䣬��OnCameraSetup��SetupRenderPass�з���
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldRender(in renderingData)) return;
        renderer.EnqueuePass(m_ScriptablePass);//��Ⱦͨ���Ŷ�
        m_ScriptablePass.GetTempRT(in renderingData);
    }

    //����pass����
    //����ȾĿ�걻����ò�׼����ʹ��ʱ�������øú���
    //���ã���ȡ��Ⱦ���ݡ������Ŀ��ȣ�
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        m_ScriptablePass.SetUP(renderer.cameraColorTargetHandle);
        //base.SetupRenderPasses(renderer, renderingData);
    }

    //�����Ⱦ����ʱ����
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

#if UNITY_EDITOR
        //������Ҫ,�ڴ˴��������ɵ���Դ,��Material��
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




    //-----------------------------------------------------------------------
    //��Ⱦ˳��
    //RF Create();

    //ѭ����ʼ��ÿ֡һ��
    //RF AddPass();
    //RF SetupRenderPass();
    //Pass OnCameraSetup();
    //Pass Exceute();
    //Pass OnCameraCleanup();
    //ѭ������

    //RF Dispose();

}


