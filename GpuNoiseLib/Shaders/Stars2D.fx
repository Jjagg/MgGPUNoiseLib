#include "includeme.fxh"

float ProbabilityThresh; //	probability a star will be drawn  ( 0.0->1.0 )
float MaxDimness;        // the maximal dimness of a star ( 0.0->1.0   0.0 = all stars bright,  1.0 = maximum variation
float TwoOverRadius;     //	fixed radius for the stars.  radius range is 0.0->1.0  shader requires 2.0/radius as input.

float4 FAST32_hash_2D_Cell( float2 gridcell )	//	generates 4 different random numbers for the single given cell point
{
    //	gridcell is assumed to be an integer coordinate
    static const float2 OFFSET = float2( 26.0, 161.0 );
    static const float DOMAIN = 71.0;
    static const float4 SOMELARGEFLOATS = float4( 951.135664, 642.949883, 803.202459, 986.973274 );
    float2 P = gridcell - floor(gridcell * ( 1.0 / DOMAIN )) * DOMAIN;
    P += OFFSET.xy;
    P *= P;
    return frac( (P.x * P.y) * ( 1.0 / SOMELARGEFLOATS.xyzw ) );
}
float Falloff_Xsq_C1( float xsq ) { xsq = 1.0 - xsq; return xsq*xsq; }	// ( 1.0 - x*x )^2   ( Used by Humus for lighting falloff in Just Cause 2.  GPUPro 1 )

//
//	Stars2D
//	http://briansharpe.files.wordpress.com/2011/12/starssample.jpg
//
//	procedural texture for creating a starry background.  ( looks good when combined with a nebula/space-like colour texture )
//	NOTE:  Any serious game implementation should hard-code these parameter values for efficiency.
//
//	Return value range of 0.0->1.0
//
float4 Stars2DPS(in VertexShaderOutput input) : COLOR0
{
    //	establish our grid cell and unit position
    float2 Pi = floor(input.Pos);
    float2 Pf = input.Pos - Pi;

    //	calculate the hash.
    float4 hash = FAST32_hash_2D_Cell( Pi );

    //	user variables
    float VALUE = 1.0 - MaxDimness * hash.z;

    //	calc the noise and return
    Pf *= TwoOverRadius;
    Pf -= ( TwoOverRadius - 1.0 );
    Pf += hash.xy * ( TwoOverRadius - 2.0 );
    float val = ( hash.w < ProbabilityThresh ) ? ( Falloff_Xsq_C1( min( dot( Pf, Pf ), 1.0 ) ) * VALUE ) : 0.0;
    return float4(1.0, 1.0, 1.0, 1.0) * val;
}

TECHNIQUE(Stars2D, MainVS, Stars2DPS);