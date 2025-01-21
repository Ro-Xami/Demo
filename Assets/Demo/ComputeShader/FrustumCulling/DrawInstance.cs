using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class DrawInstance : MonoBehaviour
{
    public GameObject prefab;
    public int instanceCount;
    public int instanceRange = 500;
    public float cullingFarPlane = 1000f;

    public ComputeShader compute;

    private Mesh mesh;
    private Material material;
    private Bounds bounds;

    private Camera mainCamera;
    private Vector3 per_playerPos = Vector3.zero;
    private Quaternion per_playerRot = Quaternion.identity;

    private int kernel;
    private Matrix4x4[] matrix;
    private Vector4[] cameraPlanes = new Vector4[6];
    
    private ComputeBuffer inputBuffer;
    private ComputeBuffer outputBuffer;

    private ComputeBuffer argsBuffer;
    private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    private Bounds DrawBounds = new Bounds();
    private MaterialPropertyBlock matPropertyBlock;

    void Start()
    {
        compute = Instantiate(compute);
        mainCamera = Camera.main;
        //初始化所需的Mesh，Mat，Bound
        mesh = prefab.GetComponent<MeshFilter>().sharedMesh;
        material = prefab.GetComponent<MeshRenderer>().sharedMaterial;
        bounds = prefab.GetComponent<MeshRenderer>().bounds;
        //初始化ComputeShader变量
        matrix = RadomMatrix(instanceCount, instanceRange);
        kernel = compute.FindKernel("FrustumCulling");
        inputBuffer = new ComputeBuffer(instanceCount, sizeof(float) * 16);
        outputBuffer = new ComputeBuffer(instanceCount, sizeof(float) * 16,ComputeBufferType.Append);
        inputBuffer.SetData(matrix);
        //给ComputeShader赋值
        compute.SetBuffer(kernel, "input", inputBuffer);
        compute.SetFloat("inputCount", instanceCount);
        compute.SetVector("boxCenter", bounds.center);
        compute.SetVector("boxExtents", bounds.extents);
        compute.SetBuffer(kernel, "VisibleBuffer", outputBuffer);
        //似乎是固定写法
        DrawBounds.size = Vector3.one * cullingFarPlane;
        args[0] = mesh.GetIndexCount(0);
        args[1] = 0;
        args[2] = mesh.GetIndexStart(0);
        args[3] = mesh.GetBaseVertex(0);
        args[4] = 0;
        argsBuffer = new ComputeBuffer(5, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);
        matPropertyBlock = new MaterialPropertyBlock();
        matPropertyBlock.SetBuffer("IndirectShaderDataBuffer", outputBuffer);

    }

    void Update()
    {
        if (IsRenderCameraChange())
        {
            outputBuffer.SetCounterValue(0);
            cameraPlanes = CullTool.GetFrustumPlane(mainCamera);
            compute.SetVectorArray("cameraPlanes", cameraPlanes);
            //似乎是固定写法
            int threadGroupX = 0;
            threadGroupX = instanceCount / 64;
            if (instanceCount % 64 != 0) ++threadGroupX;
            compute.Dispatch(kernel, threadGroupX, 1, 1);
            ComputeBuffer.CopyCount(outputBuffer, argsBuffer, sizeof(uint));
        }

        Graphics.DrawMeshInstancedIndirect(mesh, 0, material, DrawBounds, argsBuffer, 0, matPropertyBlock);
    }

    private void OnDestroy()
    {
        inputBuffer?.Release();
        outputBuffer?.Release();
        argsBuffer?.Release();
    }

    public Matrix4x4[] RadomMatrix(int count, int range)
    {
        Matrix4x4[] matrix = new Matrix4x4[count];

        for (int i = 0; i < count; i++)
        {
            Vector3 randomPosition = new Vector3(Random.Range(-range, range), 0, Random.Range(-range, range)) + this.transform.position;
            matrix[i] = Matrix4x4.TRS(randomPosition, Quaternion.identity, Vector3.one);
        }

        return matrix;
    }

    public bool IsRenderCameraChange()
    {
        if (per_playerPos != mainCamera.transform.position ||
            per_playerRot != mainCamera.transform.rotation)
        {
            per_playerPos = mainCamera.transform.position;
            per_playerRot = mainCamera.transform.rotation;
            return true;
        }
        return false;
    }

    public void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(this.transform.position, new Vector3(instanceRange * 2 , 0 , instanceRange * 2) );
    }
}
