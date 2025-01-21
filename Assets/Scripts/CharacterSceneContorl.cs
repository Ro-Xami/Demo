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

    // [Header("�����Ƶ������")][SerializeField] private GameObject _camera;    //���п���
    [Header("���������")]
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
        //ͨ�����̵�F �����л��Ƿ�����Ŀ��Χ������ת
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

    //ͨ�����̵�W��A��S��D����������ƶ��ķ�������
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

    //���������Χ��������ת�ķ�������
    private void LookAround()
    {
        float mouseX = Input.GetAxis("Mouse X") * _sensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * _sensitivity;
        MainCamera.transform.RotateAround(_target.transform.position, Vector3.up, mouseX);
        MainCamera.transform.RotateAround(_target.transform.position, MainCamera.transform.right, -mouseY);
        MainCamera.transform.LookAt(_target.transform);
    }

    //���������������ת�ķ�������
    private void Around()
    {
        float rotateX = 0;
        float rotateY = 0;
        rotateX = MainCamera.transform.localEulerAngles.x - Input.GetAxis("Mouse Y") * _sensitivity;
        rotateY = MainCamera.transform.localEulerAngles.y + Input.GetAxis("Mouse X") * _sensitivity;

        MainCamera.transform.localEulerAngles = new Vector3(rotateX, rotateY, 0);
    }
}
