using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterSceneContorl : MonoBehaviour
{
    [SerializeField]private Animator animator;
    [SerializeField] private int BodyAnimCounts = 9;
    [SerializeField] private int FaceAnimCounts = 7;
    private int BodyID = 1;
    private int FaceID = 1;

    private bool _isF = true;

    private Vector2 _cameraLook;

    // [Header("所控制的摄像机")][SerializeField] private GameObject _camera;    //可有可无
    [Header("摄像机控制")]
    [SerializeField] private Transform MainCamera;
    [SerializeField] private GameObject _target;
    [SerializeField] private float _sensitivity = 2.0f;
    [SerializeField] private float _speed = 0.1f;
    void Start()
    {

    }

    void Update()
    {

        AnimControl();

        W_A_S_D();
        //通过键盘的F 控制切换是否锁定目标围绕着旋转
        if (Input.GetKeyUp(KeyCode.F))
        {
            _isF = !_isF;
            Debug.Log("isF=" + _isF);
        }

        if (!_isF)
        {
            if (Input.GetMouseButton(0))
            {
                Around();
            }
        }
        else
        {
            if (Input.GetMouseButton(0))
            {
                LookAround();
            }
        }
    }

    private void AnimControl()
    {
        if (BodyID < 1)
        {
            BodyID = BodyAnimCounts;
        }
        if (BodyID > BodyAnimCounts)
        {
            BodyID = 1;
        }
        if (FaceID < 1)
        {
            FaceID = FaceAnimCounts;
        }
        if (FaceID > FaceAnimCounts)
        {
            FaceID = 1;
        }

        if (Input.GetKeyDown(KeyCode.UpArrow))
        {
            FaceID += 1;
        }
        if (Input.GetKeyDown(KeyCode.DownArrow))
        {
            FaceID -= 1;
        }
        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            BodyID += 1;
        }
        if (Input.GetKeyDown(KeyCode.LeftArrow))
        {
            BodyID -= 1;
        }

        animator.SetInteger ("BodyControl", BodyID);
        animator.SetInteger("FaceControl", FaceID);
    }

    //通过键盘的W、A、S、D控制摄像机移动的方法函数
    private void W_A_S_D()
    {
        if (Input.GetKey(KeyCode.W))
        {
            MainCamera.transform.Translate(Vector3.forward * _speed);
        }

        if (Input.GetKey(KeyCode.S))
        {
            MainCamera.transform.Translate(Vector3.back * _speed);
        }

        if (Input.GetKey(KeyCode.A))
        {
            MainCamera.transform.Translate(Vector3.left * _speed);
        }

        if (Input.GetKey(KeyCode.D))
        {
            MainCamera.transform.Translate(Vector3.right * _speed);
        }
    }

    //控制摄像机围绕物体旋转的方法函数
    private void LookAround()
    {
        float mouseX = Input.GetAxis("Mouse X") * _sensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * _sensitivity;
        MainCamera.transform.RotateAround(_target.transform.position, Vector3.up, mouseX);
        MainCamera.transform.RotateAround(_target.transform.position, MainCamera.transform.right, -mouseY);
        MainCamera.transform.LookAt(_target.transform);
    }

    //控制摄像机自由旋转的方法函数
    private void Around()
    {
        float rotateX = 0;
        float rotateY = 0;
        rotateX = MainCamera.transform.localEulerAngles.x - Input.GetAxis("Mouse Y") * _sensitivity;
        rotateY = MainCamera.transform.localEulerAngles.y + Input.GetAxis("Mouse X") * _sensitivity;

        MainCamera.transform.localEulerAngles = new Vector3(rotateX, rotateY, 0);
    }
}
