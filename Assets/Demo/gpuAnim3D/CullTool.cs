using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class CullTool
{
    //一个点和一个法向量确定一个平面
   public static Vector4 GetPlaneFromPositionNormal(Vector3 n, Vector3 p)
    {
        return new Vector4(n.x, n.y, n.z, -Vector3.Dot(n, p));
    }

    //三点确定一个平面
   public static Vector4 GetPlaneFromPoints(Vector3 a, Vector3 b, Vector3 c)
    {
        Vector3 n = Vector3.Normalize(Vector3.Cross(b - a, c - a));
        return GetPlaneFromPositionNormal(n , a);
    }

    //获取视锥体远平面的四个点
    public static Vector3[] GetCameraFarClipPlanePoint(Camera camera)
    {
        Vector3[] farP = new Vector3[4];
        Vector3 camPos = camera.transform.position;
        Vector3 center = camPos + camera.transform.forward * camera.farClipPlane;
        float upLength = camera.farClipPlane * Mathf.Tan(camera.fieldOfView / 2 * Mathf.Deg2Rad);
        float rightLength = upLength * camera.aspect;
        Vector3 up = upLength * camera.transform.up;
        Vector3 right = rightLength * camera.transform.right;
        farP[0] = center - up - right;//左下角
        farP[1] = center - up + right;//右下角
        farP[2] = center + up - right;//左上角
        farP[3] = center + up + right;//右下角
        return farP;
    }

    //获取视锥体的六个平面
    public static Vector4[] GetFrustumPlane(Camera camera)
    {
        Vector4[] planes = new Vector4[6];
        Transform transform = camera.transform;
        Vector3 cameraPosition = transform.position;
        Vector3[] points = GetCameraFarClipPlanePoint(camera);
        //顺时针
        planes[0] = GetPlaneFromPoints(cameraPosition, points[0], points[2]);//left
        planes[1] = GetPlaneFromPoints(cameraPosition, points[3], points[1]);//right
        planes[2] = GetPlaneFromPoints(cameraPosition, points[1], points[0]);//bottom
        planes[3] = GetPlaneFromPoints(cameraPosition, points[2], points[3]);//up
        planes[4] = GetPlaneFromPositionNormal(-transform.forward, transform.position + transform.forward * camera.nearClipPlane);//near
        planes[5] = GetPlaneFromPositionNormal(transform.forward, transform.position + transform.forward * camera.farClipPlane);//far
        return planes;
    }
}