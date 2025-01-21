using System;
using UnityEngine;
[Serializable]
public class GpuVerticesAnimations
{
    [HideInInspector] public string animtionName;
    public int startFrame = 0;
    public int frameLength = 0;
    public bool isLoop = false;
}
