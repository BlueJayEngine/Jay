uniform float4x4 uMVP;

struct VertexInput {
    [[vk::location(0)]] float3 position : POSITION;
    [[vk::location(1)]] float3 color : COLOR0;
};

struct VertexOutput {
    [[vk::location(0)]] float3 color : COLOR0;
    float4 position : SV_Position;
};

[shader("vertex")]
VertexOutput vertMain(VertexInput input) {
    VertexOutput output;
    output.position = mul(uMVP, float4(input.position, 1.0));
    output.color = input.color;
    return output;
}

[shader("fragment")]
float4 fragMain(VertexOutput input) : SV_Target {
    return float4(input.color, 1.0);
}
