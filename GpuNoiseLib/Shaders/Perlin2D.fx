#include "includeme.fxh"

// map a value in given range to (0, 1)
float MapZeroOne(float value, float minFrom, float maxFrom)
{
    return (value - minFrom) / (maxFrom - minFrom);
}

// ##################################################
// ##################  WOMBAT  ######################
// ##################################################

//
//  Wombat
//  An efficient texture-free GLSL procedural noise library
//  Source: https://github.com/BrianSharpe/Wombat
//  Derived from: https://github.com/BrianSharpe/GPU-Noise-Lib
//
//  I'm not one for copyrights.  Use the code however you wish.
//  All I ask is that credit be given back to the blog or myself when appropriate.
//  And also to let me know if you come up with any changes, improvements, thoughts or interesting uses for this stuff. :)
//  Thanks!
//
//  Brian Sharpe
//  brisharpe CIRCLE_A yahoo DOT com
//  http://briansharpe.wordpress.com
//  https://github.com/BrianSharpe
//

//
//  Perlin Noise 2D
//  Return value range of -1.0->1.0
//
float Perlin2D(float2 P)
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Perlin2D.glsl

    // establish our grid cell and unit position
    float2 Pi = floor(P);
    float4 Pf_Pfmin1 = P.xyxy - float4(Pi, Pi + 1.0);

    // calculate the hash
    float4 Pt = float4(Pi.xy, Pi.xy + 1.0);
    Pt = Pt - floor(Pt * (1.0 / 71.0)) * 71.0;
    Pt += float2(26.0, 161.0).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash_x = frac(Pt * (1.0 / 951.135664));
    float4 hash_y = frac(Pt * (1.0 / 642.949883));

    // calculate the gradient results
    float4 grad_x = hash_x - 0.49999;
    float4 grad_y = hash_y - 0.49999;
    float4 grad_results = rsqrt(grad_x * grad_x + grad_y * grad_y) * (grad_x * Pf_Pfmin1.xzxz + grad_y * Pf_Pfmin1.yyww);

    // Classic Perlin Interpolation
    grad_results *= 1.4142135623730950488016887242097;  // scale things to a strict -1.0->1.0 range  *= 1.0/sqrt(0.5)
    float2 blend = Pf_Pfmin1.xy * Pf_Pfmin1.xy * Pf_Pfmin1.xy * (Pf_Pfmin1.xy * (Pf_Pfmin1.xy * 6.0 - 15.0) + 10.0);
    float4 blend2 = float4(blend, float2(1.0 - blend));
    return dot(grad_results, blend2.zxzx * blend2.wwyy);
}

//
//  Perlin Noise 2D Deriv
//  Return value range of -1.0->1.0, with format vec3( value, xderiv, yderiv )
//
float3 Perlin2D_Deriv(float2 P)
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Perlin2D_Deriv.glsl

    // establish our grid cell and unit position
    float2 Pi = floor(P);
    float4 Pf_Pfmin1 = P.xyxy - float4(Pi, Pi + 1.0);

    // calculate the hash
    float4 Pt = float4(Pi.xy, Pi.xy + 1.0);
    Pt = Pt - floor(Pt * (1.0 / 71.0)) * 71.0;
    Pt += float2(26.0, 161.0).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash_x = frac(Pt * (1.0 / 951.135664));
    float4 hash_y = frac(Pt * (1.0 / 642.949883));

    // calculate the gradient results
    float4 grad_x = hash_x - 0.49999;
    float4 grad_y = hash_y - 0.49999;
    float4 norm = rsqrt(grad_x * grad_x + grad_y * grad_y);
    grad_x *= norm;
    grad_y *= norm;
    float4 dotval = (grad_x * Pf_Pfmin1.xzxz + grad_y * Pf_Pfmin1.yyww);

    //	C2 Interpolation
    float4 blend = Pf_Pfmin1.xyxy * Pf_Pfmin1.xyxy * (Pf_Pfmin1.xyxy * (Pf_Pfmin1.xyxy * (Pf_Pfmin1.xyxy * float2(6.0, 0.0).xxyy + float2(-15.0, 30.0).xxyy) + float2(10.0, -60.0).xxyy) + float2(0.0, 30.0).xxyy);

    //	Convert our data to a more parallel format
    float3 dotval0_grad0 = float3(dotval.x, grad_x.x, grad_y.x);
    float3 dotval1_grad1 = float3(dotval.y, grad_x.y, grad_y.y);
    float3 dotval2_grad2 = float3(dotval.z, grad_x.z, grad_y.z);
    float3 dotval3_grad3 = float3(dotval.w, grad_x.w, grad_y.w);

    //	evaluate common constants
    float3 k0_gk0 = dotval1_grad1 - dotval0_grad0;
    float3 k1_gk1 = dotval2_grad2 - dotval0_grad0;
    float3 k2_gk2 = dotval3_grad3 - dotval2_grad2 - k0_gk0;

    //	calculate final noise + deriv
    float3 results = dotval0_grad0
                    + blend.x * k0_gk0
                    + blend.y * (k1_gk1 + blend.x * k2_gk2);
    results.yz += blend.zw * (float2( k0_gk0.x, k1_gk1.x) + blend.yx * k2_gk2.xx );
    return results * 1.4142135623730950488016887242097;  // scale things to a strict -1.0->1.0 range  *= 1.0/sqrt(0.5)
}


float4 SinglePS(in VertexShaderOutput input) : COLOR
{
    float value = (Perlin2D(input.Pos) + PostOffset) * PostScale;
    return float4(value, value, value, 1.0);
}

// ##################################################
// ##################  FBM SHADERS  #################
// ##################################################

// All
int Octaves;
float2 Frequency;
float Amplitude;
float2 Lacunarity;
float Persistence;

float RidgePower; // Ridged

float Warp; // Swiss and Jordan

// Jordan only
float JordanInitGain;
float JordanInitWarp;
float JordanInitDamp;
float JordanDamp;
float JordanDampScale;

// ###################  PERLIN  #####################

float4 FbmPerlinPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += Perlin2D(input.Pos * f) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = (MapZeroOne(sum, -1, 1) + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

float4 FbmPerlinBillowedPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += abs(Perlin2D(input.Pos * f)) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

float4 FbmPerlinRidgedPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(11)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += (1.0 - abs(RidgePower * Perlin2D(input.Pos * f))) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// Found on http://www.decarpentier.nl/scape-procedural-basics, who got it from 
// the amazing Inigo Quillez (creator of http://www.shadertoy.com, check it out)
float4 FbmPerlinIQPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0.5;
    // sum of derivatives
    float2 dsum = float2(0.0, 0.0);
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(7)]
    for (int i = 0; i < Octaves; i++)
    {
         float3 n = Perlin2D_Deriv(input.Pos * f);
         dsum += n.yz;
         sum += a * n.x / (1 + dot(dsum, dsum));
         f *= Lacunarity;
         a *= Persistence;
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// Source of Swiss (after the country): http://www.decarpentier.nl/scape-procedural-extensions
float4 FbmPerlinSwissPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0.0;
    // weighted sum of derivatives
    float2 dsum = float2(0.0, 0.0);
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(8)]
    for (int i = 0; i < Octaves; i++)
    {
        float3 n = Perlin2D_Deriv((input.Pos + Warp * dsum) * Frequency);
        sum += a * (1 - abs(n.x));
        dsum += a * n.yz * -n.x;
        f *= Lacunarity;
        a *= Persistence * saturate(sum);
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// Source of Jordan (also after the country): http://www.decarpentier.nl/scape-procedural-extensions
float4 FbmPerlinJordanPS(in VertexShaderOutput input) : COLOR
{
    float2 f = Frequency;
    float a = JordanInitGain;

    float3 n = Perlin2D_Deriv(input.Pos);
    float3 n2 = n * n.x;
    float sum = n2.x;
    float2 dsum_warp = JordanInitWarp * n2.yz;
    float2 dsum_damp = JordanInitDamp * n2.yz;

    f *= Lacunarity;
    float damped_amp = a * Persistence;

    [unroll(6)]
    for(int i=1; i < Octaves; i++)
    {
        n = Perlin2D_Deriv(input.Pos * f + dsum_warp.xy);
        n2 = n * n.x;
        sum += damped_amp * n2.x;
        dsum_warp += Warp * n2.yz;
        dsum_damp += JordanDamp * n2.yz;
        f *= Lacunarity;
        a *= Persistence;
        damped_amp = a * (1 - JordanDampScale / (1 + dot(dsum_damp, dsum_damp)));
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// ##################################################
// ##################  TECHNIQUES  ##################
// ##################################################

TECHNIQUE(Single,      MainVS, SinglePS);
TECHNIQUE(Fbm,         MainVS, FbmPerlinPS);
TECHNIQUE(FbmBillow,   MainVS, FbmPerlinBillowedPS);
TECHNIQUE(FbmRidged,   MainVS, FbmPerlinRidgedPS);
TECHNIQUE(FbmIQ,       MainVS, FbmPerlinIQPS);
TECHNIQUE(FbmSwiss,    MainVS, FbmPerlinSwissPS);
TECHNIQUE(FbmJordan,   MainVS, FbmPerlinJordanPS);
