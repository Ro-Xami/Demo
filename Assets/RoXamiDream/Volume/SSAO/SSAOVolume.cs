using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[VolumeComponentMenu("RoXamiDream/SSAO")]
public class SSAOVolume : VolumeComponent, IPostProcessComponent
{
    public ClampedIntParameter sampleCount = new ClampedIntParameter(22, 1, 128);
    public ClampedFloatParameter radius = new ClampedFloatParameter(0.5f, 0f, 0.8f);
    public ClampedFloatParameter rangeCheck = new ClampedFloatParameter(0f, 0f, 10f);
    public ClampedFloatParameter aoInt = new ClampedFloatParameter(1f, 0f, 10f);

    public ClampedFloatParameter blurRadius = new ClampedFloatParameter(1f, 0f, 3f);
    public ClampedFloatParameter bilaterFilterFactor = new ClampedFloatParameter(0.1f, 0f, 1f);

    public ColorParameter aoColor = new ColorParameter(Color.black, false);
    public BoolParameter _aoOnly = new BoolParameter(false);
    public bool IsActive()
    {
        return true;
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
