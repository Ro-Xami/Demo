using System.Collections.Generic;
using UnityEngine;

public class GpuAnimatorMono : MonoBehaviour
{
    public GameObject prefab;

    private int frame = 60;
    private GpuAnimations[] animations;
    private MaterialPropertyBlock propertyBlock;
    private Mesh mesh;
    private Material mat;
    private List<float> timer = new List<float>(100000);
    private List<int> lastID = new List<int>(100000);
    private float[] frameIndex;

    private void Start()
    {
        mesh = prefab.GetComponent<MeshFilter>().sharedMesh;
        mat = prefab.GetComponent<MeshRenderer>().sharedMaterial;
        frame = prefab.GetComponent<GpuAnimator>().fps;
        animations = prefab.GetComponent<GpuAnimator>().animations;
    }

    public void Generation(List<Matrix4x4> matrix, List<int> animID)
    {
        int number = matrix.Count;
        frameIndex = new float[number];
        for (int i = 0 ; i < number ; i++)
        {
            if (lastID.Count < number)
            {
                for (int j = 0; j < number - lastID.Count; j++)
                {
                    lastID.Add(0);
                    
                }
            }
            if (timer.Count < number)
            {
                for (int k = 0; k< number - timer.Count; k++)
                {
                    timer.Add(0);
                }
            }

            if (lastID[i] != animID[i])
            {
                timer[i] = 0;
                lastID[i] = animID[i];
            }
            else
            {
                timer[i] += Time.deltaTime * frame;
            }

            timer[i] = getFrameByLoop(animations[animID[i]].frameLength, timer[i], animations[animID[i]].isLoop);
            //Debug.Log(timer[i]);
            frameIndex[i] = animations[animID[i]].startFrame + timer[i];
            //Debug.Log(frameIndex[i]);
        }
        propertyBlock = new MaterialPropertyBlock();
        propertyBlock.SetFloatArray("_animationPlayedData", frameIndex);
        Graphics.DrawMeshInstanced(mesh, 0, mat, matrix, propertyBlock);
        //Debug.Log(matrix.Count);
    }

    private float getFrameByLoop(int length, float time , bool loop)
    {  
        float frame;
        if(time > length)
        {
            if(loop)
            {
                frame = 0;
            }
            else
            {
                frame = length;
            }
        }
        else
        {
            frame = time;
        }
        return frame;
    }
}
