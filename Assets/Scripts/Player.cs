using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class Player : MonoBehaviour
{
    private Rigidbody playerRB;
    private Animator playerAnimator;
    [SerializeField] private Transform mainCamera;
    private Vector3 starCamPos;

    [SerializeField] private float moveSpeed = 2f;
    [SerializeField] private float jumpForce = 2f;

    private float input_AD;
    [SerializeField] private int facingDirection = 1;
    [SerializeField] private bool isFacingRight = true;

    [Header("Dush")]
    [SerializeField] private float dushDuration = 0.4f;
    [SerializeField] private float dushSpeed = 10f;
    [SerializeField] private float dushCD = 1f;
    [SerializeField] private float dushTime = 0f;

    [Header("CheckGround")]
    [SerializeField] private LayerMask groundLayer;
    [SerializeField] private float groundCheckedDistance;
    [SerializeField] private bool isGrounded = true;

    void Start()
    {

        playerRB = GetComponent<Rigidbody>();
        playerAnimator = GetComponentInChildren<Animator>();
        starCamPos = mainCamera.position;
    }

    void Update()
    {
        FlipControl();

        Movement();

        CheckInput();

        CheckGrounded();

        AnimaControls();

        CheckDush();

        mainCamera.position = new Vector3(starCamPos.x, starCamPos.y + transform.position.y, starCamPos.z + transform.position.z);

    }

    private void CheckDush()
    {
        dushTime -= Time.deltaTime;
        if (dushTime > 0)
        {
            playerRB.velocity = new Vector3(0, 0, facingDirection * dushSpeed);
        }
    }

    private void CheckGrounded()
    {
        isGrounded = Physics.Raycast(transform.position, Vector3.down, groundCheckedDistance, groundLayer);
    }

    private void Movement()
    {
        
        playerRB.velocity = new Vector3(0, playerRB.velocity.y, input_AD * moveSpeed);
    }

    private void CheckInput()
    {
        input_AD = Input.GetAxisRaw("Horizontal");

        if (Input.GetKeyDown(KeyCode.Space))
        {
            Jump();
        }

        if (Input.GetKeyDown(KeyCode.LeftShift))
        {
            if (dushTime < -dushCD)
            {
                dushTime = dushDuration;
            }     
        }
    }

    private void Jump()
    {
        if (isGrounded)
        {
           playerRB.velocity = new Vector3(0, jumpForce, playerRB.velocity.x);
        }
       
    }

    private void AnimaControls()
    {
        bool isMoving = playerRB.velocity.z != 0;

        playerAnimator.SetFloat("Velocity_y", playerRB.velocity.y);

        playerAnimator.SetBool("isMoving", isMoving);

        playerAnimator.SetBool("isGrounded", isGrounded);

        playerAnimator.SetBool("isDush", dushTime > 0);
    }

    private void Flip()
    {
        facingDirection *= -1;
        isFacingRight = !isFacingRight;
        transform.localEulerAngles = new Vector3(0, -1 * transform.localEulerAngles.y, 0);
    }
        

    private void FlipControl()
    {
        if(playerRB.velocity.z > 0 && !isFacingRight)
        {
            Flip();
        }
        else if (playerRB.velocity.z < 0 && isFacingRight)
        {
            Flip();
        }
    }

    private void OnDrawGizmos()
    {
        Gizmos.DrawLine(transform.position, new Vector3(transform.position.x, -groundCheckedDistance, transform.position.z));
    }
}
