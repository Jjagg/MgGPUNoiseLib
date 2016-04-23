#include "includeme.fxh"

float RadiusLow;
float RadiusHigh;

//
//	PolkaDot Noise 2D
//	http://briansharpe.files.wordpress.com/2011/12/polkadotsample.jpg
//	http://briansharpe.files.wordpress.com/2012/01/polkaboxsample.jpg
//	TODO, these images have random intensity and random radius.  This noise now has intensity as proportion to radius.  Images need updated.  TODO
//
//	Generates a noise of smooth falloff polka dots.
//	Allow for control on radius.  Intensity is proportional to radius
//	Return value range of 0.0->1.0
//
float4 PolkaDot2DPS(in VertexShaderOutput input) : COLOR0
{
    float2 P = input.Pos;
    //	establish our grid cell and unit position
    float2 Pi = floor(P);
    float2 Pf = P - Pi;

    //  calculate the hash.
    //  gridcell is assumed to be an integer coordinate
    static const float2 OFFSET = float2(26.0, 161.0);
    static const float DOMAIN = 71.0;
    static const float SOMELARGEFLOAT = 951.135664;
    float4 grid = float4( Pi.xy, Pi.xy + 1.0 );
    grid = grid - floor(grid * ( 1.0 / DOMAIN )) * DOMAIN;	//	truncate the domain
    grid += OFFSET.xyxy;								//	offset to interesting part of the noise
    grid *= grid;											//	calculate and return the hash
    float4 hash = frac(grid.xzxz * grid.yyww * (1.0 / SOMELARGEFLOAT));

    //	user variables
    float RADIUS = max( 0.0, RadiusLow + hash.z * ( RadiusHigh - RadiusLow ) );
    float VALUE = RADIUS / max( RadiusHigh, RadiusLow );	//	new keep value in proportion to radius.  Behaves better when used for bumpmapping, distortion and displacement

    //	calc the noise and return
    RADIUS = 2.0/RADIUS;
    Pf *= RADIUS;
    Pf -= ( RADIUS - 1.0 );
    Pf += hash.xy * ( RADIUS - 2.0 );
    //Pf *= Pf;		//	this gives us a cool box looking effect
    float xsq = 1.0 - min(dot(Pf, Pf), 1.0); 
    float val = xsq * xsq * xsq * VALUE;
    return float4(val, val, val, 1.0);
}

TECHNIQUE(PolkaDot2D, MainVS, PolkaDot2DPS);