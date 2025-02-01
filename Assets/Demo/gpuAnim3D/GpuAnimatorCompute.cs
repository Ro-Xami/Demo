using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UIElements;

public class GpuAnimatorCompute : MonoBehaviour
{
    public GameObject prefab;
    public int instanceMaxCount;
    public Bounds drawBounds; 
    public ComputeShader compute;

    private int frame;
    private GpuAnimations[] animations;
    private int instanceCount;
    private Mesh mesh;
    private Material material;
    private Bounds bounds;
    Bounds camBounds = new Bounds();

    private Camera mainCamera;

    private int kernel;
    private Vector4[] cameraPlanes = new Vector4[6];

    private ComputeBuffer inputBuffer;
    private ComputeBuffer outputBuffer;
    private ComputeBuffer rwBuffer;

    private ComputeBuffer argsBuffer;
    private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    private MaterialPropertyBlock matPropertyBlock;

    private List<GpuVerticesDataInput> gpuVerticesDataInputs = new List<GpuVerticesDataInput>();

    public struct GpuVerticesDataInput
    {
        public Matrix4x4 trsMtrix;
        public int animID;
        public int isLoop;
        public float startFrame;
        public float animationLength;
    }

    void Start()
    {
        compute = Instantiate(compute);
        mainCamera = Camera.main;
        //初始化所需的Mesh，Mat，Bound
        mesh = prefab.GetComponent<MeshFilter>().sharedMesh;
        material = prefab.GetComponent<MeshRenderer>().sharedMaterial;
        bounds = prefab.GetComponent<MeshRenderer>().bounds;
        frame = prefab.GetComponent<GpuAnimator>().frame;
        animations = prefab.GetComponent<GpuAnimator>().animations;
        //初始化ComputeShader变量
        kernel = compute.FindKernel("GpuAnimationRenderer");
        inputBuffer = new ComputeBuffer(instanceMaxCount, sizeof(float) * 16 + sizeof(int) + sizeof(int) + sizeof(float) + sizeof(float));
        outputBuffer = new ComputeBuffer(instanceMaxCount, sizeof(float) * 16 + sizeof(float) * 4, ComputeBufferType.Append);
        rwBuffer = new ComputeBuffer(instanceMaxCount, sizeof(float) * 3 + sizeof(int) * 2, ComputeBufferType.Raw);
        //argsBuffer是DrawMeshInstancedIndirect的固定写法
        args[0] = mesh.GetIndexCount(0);
        args[1] = 0;
        args[2] = mesh.GetIndexStart(0);
        args[3] = mesh.GetBaseVertex(0);
        args[4] = 0;
        argsBuffer = new ComputeBuffer(5, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);
        matPropertyBlock = new MaterialPropertyBlock();
        matPropertyBlock.SetBuffer("gpuBufferData", outputBuffer);

    }

    public void GennerationAndPlayAnimation(List<Matrix4x4> matrix, List<int> animationID)
    {
        if (matrix.Count > instanceMaxCount)
        {
            instanceCount = instanceMaxCount;
            Debug.LogWarning("InstanceCount Over MaxInctanceCount! , it Will only could return to MaxInctanceCount");
        }
        else
        {
            instanceCount = matrix.Count;
        }
        gpuVerticesDataInputs.Clear();
        for (int i = 0; i < instanceCount; i++)
        {
            GpuVerticesDataInput dataInput = new GpuVerticesDataInput()
            {
                trsMtrix = matrix[i],
                animID = animationID[i],
                isLoop = animations[animationID[i]].isLoop?1:0,
                startFrame = animations[animationID[i]].startFrame,
                animationLength = animations[animationID[i]].frameLength,
            };
            gpuVerticesDataInputs.Add(dataInput);
        }
        
        inputBuffer.SetData(gpuVerticesDataInputs);
        //给ComputeShader赋值
        compute.SetBuffer(kernel, "inputBuffer", inputBuffer);
        compute.SetBuffer(kernel, "rwData", rwBuffer);
        compute.SetFloat("deltaTime", Time.deltaTime);
        compute.SetFloat("frame", frame);
        compute.SetFloat("inputCount", instanceCount);
        compute.SetVector("boxCenter", bounds.center);
        compute.SetVector("boxExtents", bounds.extents);
        compute.SetBuffer(kernel, "outputBuffer", outputBuffer);

        outputBuffer.SetCounterValue(0);
        cameraPlanes = CullTool.GetFrustumPlane(mainCamera);
        compute.SetVectorArray("cameraPlanes", cameraPlanes);
        //给computeShader分配线程组
        int threadGroupX = 0;
        threadGroupX = instanceCount / 64;
        if (instanceCount % 64 != 0) ++threadGroupX;
        compute.Dispatch(kernel, threadGroupX, 1, 1);
        ComputeBuffer.CopyCount(outputBuffer, argsBuffer, sizeof(uint));

        camBounds.center = drawBounds.center + mainCamera.transform.position;
        camBounds.extents = drawBounds.extents;
        Graphics.DrawMeshInstancedIndirect(mesh, 0, material, camBounds, argsBuffer, 0, matPropertyBlock);
    }

    private void OnDestroy()
    {
        inputBuffer?.Release();
        outputBuffer?.Release();
        argsBuffer?.Release();
        rwBuffer?.Release();
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawWireCube(drawBounds.center + Camera.main.transform.position, drawBounds.extents);
    }
}
