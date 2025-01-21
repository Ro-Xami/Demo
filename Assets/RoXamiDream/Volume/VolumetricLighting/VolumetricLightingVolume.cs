using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[VolumeComponentMenu("RoXamiDream/VolumetricLighting")]
public class VolumetricLightingVolume : VolumeComponent, IPostProcessComponent
{
    public ColorParameter VolumetricColor = new(Color.white, true);
    public ClampedFloatParameter LightIntensity = new(0.001f, 0f, 0.1f, true);
    public MinFloatParameter LightPower = new(1f, 0f, true);
    public MinFloatParameter MaxDistance = new(1000f, 0f, true);
    public ClampedFloatParameter StepSize = new(0.01f, 0f, 0.1f, true);
    public MinFloatParameter MaxStepSize = new(200f, 0f, true);
    public MinFloatParameter BlurRange = new(1f, 0f, true);
    public ClampedIntParameter BlurNumber = new(3, 0, 50, true);
    public bool IsActive()
    {
        return true;
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
