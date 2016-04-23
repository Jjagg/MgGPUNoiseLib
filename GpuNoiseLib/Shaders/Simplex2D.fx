#include "includeme.fxh"

// map a value in given range to (0, 1)
float MapZeroOne(float value, float minFrom, float maxFrom)
{
    return (value - minFrom) / (maxFrom - minFrom);
}


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
//  This is a modified version of Stefan Gustavson's and Ian McEwan's work at http://github.com/ashima/webgl-noise
//  Modifications are...
//  - faster random number generation
//  - analytical final normalization
//  - space scaled can have an approx feature size of 1.0
//

//
//  Simplex Perlin Noise 2D
//  Return value range of -1.0->1.0
//
float Simplex2D( float2 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/SimplexPerlin2D.glsl

    //  simplex math constants
    const float SKEWFACTOR = 0.36602540378443864676372317075294;            // 0.5*(sqrt(3.0)-1.0)
    const float UNSKEWFACTOR = 0.21132486540518711774542560974902;          // (3.0-sqrt(3.0))/6.0
    const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;    // sqrt( 0.5 )	height of simplex triangle
    const float3 SIMPLEX_POINTS = float3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );  //  simplex triangle geo

    //  establish our grid cell.
    P *= SIMPLEX_TRI_HEIGHT;    // scale space so we can have an approx feature size of 1.0
    float2 Pi = floor( P + dot( P, float2( SKEWFACTOR, SKEWFACTOR ) ) );

    // calculate the hash
    float4 Pt = float4( Pi.xy, Pi.xy + 1.0 );
    Pt = Pt - floor(Pt * ( 1.0 / 71.0 )) * 71.0;
    Pt += float2( 26.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash_x = frac( Pt * ( 1.0 / 951.135664 ) );
    float4 hash_y = frac( Pt * ( 1.0 / 642.949883 ) );

    //  establish vectors to the 3 corners of our simplex triangle
    float2 v0 = Pi - dot( Pi, float2( UNSKEWFACTOR, UNSKEWFACTOR ) ) - P;
    float4 v1pos_v1hash = (v0.x < v0.y) ? float4(SIMPLEX_POINTS.xy, hash_x.y, hash_y.y) : float4(SIMPLEX_POINTS.yx, hash_x.z, hash_y.z);
    float4 v12 = float4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;

    //  calculate the dotproduct of our 3 corner vectors with 3 random normalized vectors
    float3 grad_x = float3( hash_x.x, v1pos_v1hash.z, hash_x.w ) - 0.49999;
    float3 grad_y = float3( hash_y.x, v1pos_v1hash.w, hash_y.w ) - 0.49999;
    float3 grad_results = rsqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * float3( v0.x, v12.xz ) + grad_y * float3( v0.y, v12.yw ) );

    //	Normalization factor to scale the final result to a strict 1.0->-1.0 range
    //	http://briansharpe.wordpress.com/2012/01/13/simplex-noise/#comment-36
    const float FINAL_NORMALIZATION = 99.204334582718712976990005025589;

    //	evaluate and return
    float3 m = float3( v0.x, v12.xz ) * float3( v0.x, v12.xz ) + float3( v0.y, v12.yw ) * float3( v0.y, v12.yw );
    m = max(0.5 - m, 0.0);
    m = m*m;
    return dot(m*m, grad_results) * FINAL_NORMALIZATION;
}

//
//  Simplex Perlin Noise 2D Deriv
//  Return value range of -1.0->1.0, with format float3( value, xderiv, yderiv )
//
float3 Simplex2D_Deriv( float2 P )
{
    //  https://github.com/BrianSharpe/Wombat/blob/master/SimplexPerlin2D_Deriv.glsl

    //  simplex math constants
    const float SKEWFACTOR = 0.36602540378443864676372317075294;            // 0.5*(sqrt(3.0)-1.0)
    const float UNSKEWFACTOR = 0.21132486540518711774542560974902;          // (3.0-sqrt(3.0))/6.0
    const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;    // sqrt( 0.5 )	height of simplex triangle
    const float3 SIMPLEX_POINTS = float3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );  //  simplex triangle geo

    //  establish our grid cell.
    P *= SIMPLEX_TRI_HEIGHT;    // scale space so we can have an approx feature size of 1.0
    float2 Pi = floor( P + dot( P, float2( SKEWFACTOR, SKEWFACTOR ) ) );

    // calculate the hash
    float4 Pt = float4( Pi.xy, Pi.xy + 1.0 );
    Pt = Pt - floor(Pt * ( 1.0 / 71.0 )) * 71.0;
    Pt += float2( 26.0, 161.0 ).xyxy;
    Pt *= Pt;
    Pt = Pt.xzxz * Pt.yyww;
    float4 hash_x = frac( Pt * ( 1.0 / 951.135664 ) );
    float4 hash_y = frac( Pt * ( 1.0 / 642.949883 ) );

    //  establish vectors to the 3 corners of our simplex triangle
    float2 v0 = Pi - dot( Pi, float2( UNSKEWFACTOR, UNSKEWFACTOR ) ) - P;
    float4 v1pos_v1hash = (v0.x < v0.y) ? float4(SIMPLEX_POINTS.xy, hash_x.y, hash_y.y) : float4(SIMPLEX_POINTS.yx, hash_x.z, hash_y.z);
    float4 v12 = float4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;

    //  calculate the dotproduct of our 3 corner vectors with 3 random normalized vectors
    float3 grad_x = float3( hash_x.x, v1pos_v1hash.z, hash_x.w ) - 0.49999;
    float3 grad_y = float3( hash_y.x, v1pos_v1hash.w, hash_y.w ) - 0.49999;
    float3 norm = rsqrt( grad_x * grad_x + grad_y * grad_y );
    grad_x *= norm;
    grad_y *= norm;
    float3 grad_results = grad_x * float3( v0.x, v12.xz ) + grad_y * float3( v0.y, v12.yw );

    //	evaluate the kernel
    float3 m = float3( v0.x, v12.xz ) * float3( v0.x, v12.xz ) + float3( v0.y, v12.yw ) * float3( v0.y, v12.yw );
    m = max(0.5 - m, 0.0);
    float3 m2 = m*m;
    float3 m4 = m2*m2;

    //  calc the derivatives
    float3 temp = 8.0 * m2 * m * grad_results;
    float xderiv = dot( temp, float3( v0.x, v12.xz ) ) - dot( m4, grad_x );
    float yderiv = dot( temp, float3( v0.y, v12.yw ) ) - dot( m4, grad_y );

    //  Normalization factor to scale the final result to a strict 1.0->-1.0 range
    //  http://briansharpe.wordpress.com/2012/01/13/simplex-noise/#comment-36
    const float FINAL_NORMALIZATION = 99.204334582718712976990005025589;

    //  sum and return all results as a float3
    return float3( dot( m4, grad_results ), xderiv, yderiv ) * FINAL_NORMALIZATION;
}


float4 SinglePS(in VertexShaderOutput input) : COLOR
{
    float value = (Simplex2D(input.Pos) + PostOffset) * PostScale;
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

float4 FbmPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(8)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += Simplex2D(input.Pos * f) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
    sum = (MapZeroOne(sum, -1, 1) + PostOffset) * PostScale;
    return float4(sum, sum, sum, 1.0);
}

float4 FbmBillowedPS(in VertexShaderOutput input) : COLOR
{
    float sum = 0;
    float2 f = Frequency;
    float a = Amplitude;
    [unroll(8)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += abs(Simplex2D(input.Pos * f)) * a;
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
    [unroll(8)]
    for (int i = 0; i < Octaves; i++)
    {
        sum += (1.0 - abs(RidgePower * Simplex2D(input.Pos * f))) * a;
        f *= Lacunarity;
        a *= Persistence;
    }
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
    [unroll(6)]
    for (int i = 0; i < Octaves; i++)
    {
         float3 n = Simplex2D_Deriv(input.Pos * f);
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
    [unroll(6)]
    for (int i = 0; i < Octaves; i++)
    {
        float3 n = Simplex2D_Deriv((input.Pos + Warp * dsum) * Frequency);
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

    float3 n = Simplex2D_Deriv(input.Pos);
    float3 n2 = n * n.x;
    float sum = n2.x;
    float2 dsum_warp = JordanInitWarp * n2.yz;
    float2 dsum_damp = JordanInitDamp * n2.yz;

    f *= Lacunarity;
    float damped_amp = a * Persistence;

    [unroll(5)]
    for(int i=1; i < Octaves; i++)
    {
        n = Simplex2D_Deriv(input.Pos * f + dsum_warp.xy);
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

