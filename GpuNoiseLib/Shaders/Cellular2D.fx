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
//  This represents a modified version of Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//  The noise is optimized to use a 2x2 search window instead of 3x3
//  Modifications are...
//  - faster random number generation
//  - analytical final normalization
//  - random point offset is restricted to prevent artifacts
//

//
//  Cellular Noise 2D
//  produces a range of 0.0->1.0
//
float Cellular2D( float2 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Cellular2D.glsl

    //  establish our grid cell and unit position
    float2 Pi = floor(P);
    float2 Pf = P - Pi;

    //  calculate the hash
    float4 Pt = float4( Pi.xy, Pi.xy + 1.0 );
    Pt = Pt - floor(Pt * ( 1.0 / 71.0 )) * 71.0;
    Pt += float2( 26.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash_x = frac( Pt * ( 1.0 / 951.135664 ) );
    float4 hash_y = frac( Pt * ( 1.0 / 642.949883 ) );

    //  generate the 4 points
    hash_x = hash_x * 2.0 - 1.0;
    hash_y = hash_y * 2.0 - 1.0;
    const float JITTER_WINDOW = 0.25;   // 0.25 will guarentee no artifacts
    hash_x = ( ( hash_x * hash_x * hash_x ) - sign( hash_x ) ) * JITTER_WINDOW + float4( 0.0, 1.0, 0.0, 1.0 );
    hash_y = ( ( hash_y * hash_y * hash_y ) - sign( hash_y ) ) * JITTER_WINDOW + float4( 0.0, 0.0, 1.0, 1.0 );

    //  return the closest squared distance
    float4 dx = Pf.xxxx - hash_x;
    float4 dy = Pf.yyyy - hash_y;
    float4 d = dx * dx + dy * dy;
    d.xy = min(d.xy, d.zw);
    return min(d.x, d.y) * ( 1.0 / 1.125 ); // return a value scaled to 0.0->1.0
}

//
//  Cellular Noise 2D Deriv
//  Return value range of 0.0->1.0, with format float3( value, xderiv, yderiv )
//
float3 Cellular2D_Deriv( float2 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/Cellular2D_Deriv.glsl

    //  establish our grid cell and unit position
    float2 Pi = floor(P);
    float2 Pf = P - Pi;

    //  calculate the hash
    float4 Pt = float4( Pi.xy, Pi.xy + 1.0 );
    Pt = Pt - floor(Pt * ( 1.0 / 71.0 )) * 71.0;
    Pt += float2( 26.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash_x = frac( Pt * ( 1.0 / 951.135664 ) );
    float4 hash_y = frac( Pt * ( 1.0 / 642.949883 ) );

    //  generate the 4 points
    hash_x = hash_x * 2.0 - 1.0;
    hash_y = hash_y * 2.0 - 1.0;
    const float JITTER_WINDOW = 0.25;   // 0.25 will guarentee no artifacts
    hash_x = ( ( hash_x * hash_x * hash_x ) - sign( hash_x ) ) * JITTER_WINDOW + float4( 0.0, 1.0, 0.0, 1.0 );
    hash_y = ( ( hash_y * hash_y * hash_y ) - sign( hash_y ) ) * JITTER_WINDOW + float4( 0.0, 0.0, 1.0, 1.0 );

    //	return the closest squared distance + derivatives ( thanks to Jonathan Dupuy )
    float4 dx = Pf.xxxx - hash_x;
    float4 dy = Pf.yyyy - hash_y;
    float4 d = dx * dx + dy * dy;
    float3 t1 = d.x < d.y ? float3( d.x, dx.x, dy.x ) : float3( d.y, dx.y, dy.y );
    float3 t2 = d.z < d.w ? float3( d.z, dx.z, dy.z ) : float3( d.w, dx.w, dy.w );
    return ( t1.x < t2.x ? t1 : t2 ) * float3( 1.0, 2.0, 2.0 ) * ( 1.0 / 1.125 ); // return a value scaled to 0.0->1.0
}


float4 SinglePS(in VertexShaderOutput input) : COLOR
{
    float value = (Cellular2D(input.Pos) + PostOffset) * PostScale;
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

float RidgePower; // Ridged;

float Warp; // Swiss and Jordan

// Jordan only
float JordanInitGain;
float JordanInitWarp;
float JordanInitDamp;
float JordanDamp;
float JordanDampScale;

// ###################  PERLIN  #####################

float4 FbmPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(12)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += (Cellular2D(input.Pos * f) - 0.5) * a;
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
        sum += abs(Cellular2D(input.Pos * f) * 0.5) * a;
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
    [unroll(11)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += (2.0 - abs(RidgePower * Cellular2D(input.Pos * f))) * a;
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
    [unroll(8)]
    for (int i = 0; i < Octaves; i++)
    {
         float3 n = Cellular2D_Deriv(input.Pos * f);
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
    [unroll(8)]
    for (int i = 0; i < Octaves; i++)
    {
        float3 n = Cellular2D_Deriv((input.Pos + Warp * dsum) * Frequency);
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

    float3 n = Cellular2D_Deriv(input.Pos);
    float3 n2 = n * n.x;
    float sum = n2.x;
    float2 dsum_warp = JordanInitWarp * n2.yz;
    float2 dsum_damp = JordanInitDamp * n2.yz;

    f *= Lacunarity;
    float damped_amp = a * Persistence;

    [unroll(7)]
    for(int i=1; i < Octaves; i++)
    {
        n = Cellular2D_Deriv(input.Pos * f + dsum_warp.xy);
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
