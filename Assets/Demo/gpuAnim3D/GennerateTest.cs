using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

public class GennerateTest : MonoBehaviour
{
    public int startNumber = 10000;
    public int range = 100;
    public bool isMonoOrCompute = true;

    [Header("ต๗สิ")]
    public int totalNumber;
    public int firstAnimID;

    private GpuAnimatorMono animatorMono;
    private GpuAnimatorCompute animatorCompute;
    private List<int> animIDList = new List<int>();
    private List<Matrix4x4> matrixList = new List<Matrix4x4>();

    void Start()
    {
        animatorMono = this.GetComponent<GpuAnimatorMono>();
        animatorCompute = this.GetComponent<GpuAnimatorCompute>();
        RadomMatrix(startNumber, range);
    }

    void Update()
    {
        if (Input.GetKey(KeyCode.T))
        {
            float rotate = Random.Range(0, 360);
            Vector3 randomPosition = new Vector3(Random.Range(-range, range), 0, Random.Range(-range, range));
            Matrix4x4 addMtrix = Matrix4x4.TRS(randomPosition, Quaternion.Euler(0, rotate, 0), Vector3.one);
            matrixList.Add(addMtrix);
            
            animIDList.Add((int)Random.Range(0, 3));
        }
        if (Input.GetKeyDown(KeyCode.R))
        {
            for (int i = 0; i < animIDList.Count; i++)
            {
                animIDList[i] = (animIDList[i] + 1 )% 3;
            }
        }

        firstAnimID = animIDList[0];
        totalNumber = animIDList.Count;

        if (isMonoOrCompute)
        {
            animatorMono.Generation(matrixList, animIDList);
        }
        else
        {
            animatorCompute.GennerationAndPlayAnimation(matrixList, animIDList);
        }
    }

    public void RadomMatrix(int count, int range)
    {
        Matrix4x4 matrix;
        int animID;

        for (int i = 0; i < count; i++)
        {
            float rotate = Random.Range(0, 360);
            Vector3 randomPosition = new Vector3(Random.Range(-range, range), 0, Random.Range(-range, range));
            matrix = Matrix4x4.TRS(randomPosition, Quaternion.Euler(new Vector3(0, rotate, 0)), Vector3.one);
            animID = i % 3;

            matrixList.Add(matrix);
            animIDList.Add(animID);
        }     
    }

    public void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(Vector3.zero, new Vector3(range * 2 , 0 , range * 2));
    }
}
