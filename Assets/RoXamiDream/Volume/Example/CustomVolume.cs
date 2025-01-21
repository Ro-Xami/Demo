using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[VolumeComponentMenu("RoXamiDream/CustomVolume")]
public class CustomVolume : VolumeComponent, IPostProcessComponent
{
    public MinFloatParameter MinFloat = new(10f, 0f, true);
    public ClampedFloatParameter ClampFloat = new(0f, 0f, 1f, true);
    public ColorParameter TestColor = new (Color.black, true);

    public bool IsActive()
    {
        return true;
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
