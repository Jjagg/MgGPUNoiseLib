#include "includeme.fxh"

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
//  Value Noise 2D
//  Return value range of 0.0->1.0
//
float Value2D(float2 P)
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Value2D.glsl

    //	establish our grid cell and unit position
    float2 Pi = floor(P);
    float2 Pf = P - Pi;

    //	calculate the hash.
    float4 Pt = float4( Pi.xy, Pi.xy + 1.0 );
    Pt = Pt - floor(Pt * ( 1.0 / 71.0 )) * 71.0;
    Pt += float2( 26.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash = frac( Pt * ( 1.0 / 951.135664 ) );

    //	blend the results and return
    float2 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
    float4 blend2 = float4( blend, 1.0 - blend);
    return dot( hash, blend2.zxzx * blend2.wwyy );
}

//
//  Value Noise 2D Deriv
//  Return value range of 0.0->1.0, with format float3( value, xderiv, yderiv )
//
float3 Value2D_Deriv( float2 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Value2D_Deriv.glsl

    //	establish our grid cell and unit position
    float2 Pi = floor(P);
    float2 Pf = P - Pi;

    //	calculate the hash.
    float4 Pt = float4( Pi.xy, Pi.xy + 1.0 );
    Pt = Pt - floor(Pt * ( 1.0 / 71.0 )) * 71.0;
    Pt += float2( 26.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash = frac( Pt * ( 1.0 / 951.135664 ) );

    //	blend the results and return
    float4 blend = Pf.xyxy * Pf.xyxy * ( Pf.xyxy * ( Pf.xyxy * ( Pf.xyxy * float2( 6.0, 0.0 ).xxyy + float2( -15.0, 30.0 ).xxyy ) + float2( 10.0, -60.0 ).xxyy ) + float2( 0.0, 30.0 ).xxyy );
    float4 res0 = lerp( hash.xyxz, hash.zwyw, blend.yyxx );
    return float3( res0.x, 0.0, 0.0 ) + ( res0.yyw - res0.xxz ) * blend.xzw;
}

float4 SinglePS(in VertexShaderOutput input) : COLOR
{
    float value = (Value2D(input.Pos) + PostOffset) * PostScale;
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


float4 FbmPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += (Value2D(input.Pos * f) - 0.5) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = sum / 2.0 + 0.5;
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

float4 FbmBillowedPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += abs(Value2D(input.Pos * f) * 0.5) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

float4 FbmRidgedPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += (2.0 - abs(RidgePower * Value2D(input.Pos * f))) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = sum / 2.0 + 0.5;
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// Found on http://www.decarpentier.nl/scape-procedural-basics, who got it from 
// the amazing Inigo Quillez (creator of http://www.shadertoy.com, check it out)
float4 FbmIQPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0.5;
    // sum of derivatives
    float2 dsum = float2(0.0, 0.0);
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
         float3 n = Value2D_Deriv(input.Pos * f);
         dsum += n.yz;
         sum += a * n.x / (1 + dot(dsum, dsum));
         f *= Lacunarity;
         a *= Persistence;
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// Source of Swiss (after the country): http://www.decarpentier.nl/scape-procedural-extensions
float4 FbmSwissPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0.0;
    // weighted sum of derivatives
    float2 dsum = float2(0.0, 0.0);
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        float3 n = Value2D_Deriv((input.Pos + Warp * dsum) * Frequency);
        sum += a * (1 - abs(n.x));
        dsum += a * n.yz * -n.x;
        f *= Lacunarity;
        a *= Persistence * saturate(sum);
    }
    sum = (sum + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

// Source of Jordan (also after the country): http://www.decarpentier.nl/scape-procedural-extensions
float4 FbmJordanPS(in VertexShaderOutput input) : COLOR
{
    float2 f = Frequency;
    float a = JordanInitGain;

    float3 n = Value2D_Deriv(input.Pos);
    float3 n2 = n * n.x;
    float sum = n2.x;
    float2 dsum_warp = JordanInitWarp * n2.yz;
    float2 dsum_damp = JordanInitDamp * n2.yz;

    f *= Lacunarity;
    float damped_amp = a * Persistence;

    [unroll(12)]
    for(int i=1; i < Octaves; i++)
    {
        n = Value2D_Deriv(input.Pos * f + dsum_warp.xy);
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
TECHNIQUE(Fbm,         MainVS, FbmPS);
TECHNIQUE(FbmBillow,   MainVS, FbmBillowedPS);
TECHNIQUE(FbmRidged,   MainVS, FbmRidgedPS);
TECHNIQUE(FbmIQ,       MainVS, FbmIQPS);
TECHNIQUE(FbmSwiss,    MainVS, FbmSwissPS);
TECHNIQUE(FbmJordan,   MainVS, FbmJordanPS);
