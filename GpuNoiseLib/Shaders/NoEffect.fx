float4 MainVS(float4 Position : POSITION0) : POSITION0
{
    return Position;
}

float4 MainPS() : COLOR
{
    return float4(1.0, 0.0, 0.0, 1.0);
}

technique ThisIsStillNotWorking
{
    pass
    {
        VertexShader = compile vs_4_0 MainVS();
        PixelShader = compile ps_4_0 MainPS();
    }
}