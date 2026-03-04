struct VertexInput {
    float3 position : POSITION;
    float3 color    : COLOR;
};

struct VertexOutput {
    float3 color;
    float4 sv_position : SV_Position;
};

struct Globals {
    row_major float4x4 view;
    row_major float4x4 proj;
    float time;
    int2 resoution;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> push;

[shader("vertex")]
VertexOutput vert_main(VertexInput input) {
    VertexOutput output;
    output.sv_position = mul(push.mvp, float4(input.position, 1.0));
    output.color = input.color;
    return output;
}



[shader("fragment")]
float4 frag_main(VertexOutput inVert) : SV_Target
{
    float3 color = inVert.color;
    return float4(color, 1.0);
}
