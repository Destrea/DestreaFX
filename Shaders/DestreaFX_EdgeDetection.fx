#include "ReShade.fxh"
#include "ReShadeUI.fxh"


// This shader uses the Depth buffer, and an approximated normal buffer, along with the sobel operation,
// to approximate edges of objects, and allowing those edges to be re-colored as overlayed outlines.

// When used with Final Fantasy 14, this shader requires ReShade's global Preprocessor definitions to be set so that
// "RESHADE_DEPTH_INPUT_IS_REVERSED" is set to 1, as the depth buffer was reversed with FFXIV's Dawntrail expansion.


// The Normal buffer approximation used was taken directly from "DisplayDepth.fx" made by Daodan.
// I'll likely edit it in the future to reduce the number artifacts that are present when using it
// with Final Fantasy 14, to provide both cleaner outlines, and reduce the number of "edges" it detects
// in weird locations on character models.



//Texture/samplers
texture2D texDepthBuffer : DEPTH;
texture2D texColorBuffer : COLOR;

sampler2D depthBuff
{
    Texture = texDepthBuffer;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;
};

texture2D normalTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D normalSampler
{
    Texture = normalTex;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;
};

sampler2D colorBuff
{
    Texture = texColorBuffer;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;
};

texture2D edgeTexture
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D EdgeDetect
{
    Texture = edgeTexture;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;
};

//Uniforms / UI Options
uniform float normthreshold <
ui_min = 0.0000f;
ui_max = 5.0000f;
ui_label = "Normal Threshold";
ui_tooltip = "Changes the required \"floor\" value for an edge, on the Normal Buffer.";
ui_type = "slider";
> = 1.95f;

uniform float depthreshold <
ui_min = 0.0000f;
ui_max = 1.0000f;
ui_label = "Depth Threshold";
ui_tooltip = "Changes the required \"floor\" value for an edge, on the Depth Buffer.";
ui_type = "slider";
> = 0.25f;

uniform float depth_weight <
ui_min = 0.0;
ui_max = 10.0;
ui_label = "Depth Buffer Weight";
ui_tooltip = "Changes the number of edges found using the Depth Buffer.";
ui_type = "slider";
> = 10.0f;

uniform float norm_weight <
ui_min = 0.0;
ui_max = 10.0;
ui_label = "Normal Buffer Weight";
ui_tooltip = "Changes the number of edges found using the Normal Buffer.";
ui_type = "slider";
> = 10.0f;

static float zNear = 0.1f;
static float zFar = 10.0f;

uniform float3 Outline_color < __UNIFORM_COLOR_FLOAT3
ui_label = "Outline Color";
ui_tooltip = "Choose an outline color";
> = float3(0.0,0.0,0.0);

static float3x3 Gx = float3x3(-1,-2,-1,0,0,0,1,2,1);
static float3x3 Gy = float3x3(-1,0,1,-2,0,2,-1,0,1);


float luminance(float3 color)
{
    const float3 weight = float3(0.2125, 0.7154, 0.0721);
    return dot(weight, color);
}

float3 colAvg(float3 color)
{
	float avg = (color.r + color.g + color.b)/3.0;
	return float3(avg,avg,avg);
}


//Normal buffer approximations
float3 GetNormals(float2 texcoord)
{
    float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
    float2 cPos = texcoord.xy;
    float2 nPos = cPos  - offset.zy;
    float2 ePos = cPos + offset.xz;
    float3 vCenter = float3(cPos - 0.5, 1) * ReShade::GetLinearizedDepth(cPos);
    float3 vNorth = float3(nPos - 0.5, 1) * ReShade::GetLinearizedDepth(nPos);
    float3 vEast = float3(ePos - 0.5, 1) * ReShade::GetLinearizedDepth(ePos);

    return normalize(cross(vCenter - vNorth, vCenter - vEast)) * 0.5 + 0.5;
}

// Outputting the normal buffer to an actual sampler
float4 SetNormalBuff( float4 position: SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 normal = GetNormals(texcoord);
    return float4(normal, 1.0);
}

//Calculations for the scaled depth buffer, for determining which objects are in the foreground/background when compared.
float DepthCalc(float2 texcoord)
{
	float linear_depth = ReShade::GetLinearizedDepth(texcoord);
	float scaled_depth = (zFar - zNear)/(zNear + linear_depth * (zNear-zFar));
	return scaled_depth;
}


//Sobel operation on the depth buffer.
// Convolves with both the Gx and Gy kernels, finding edges between objects that are in front of/behind others.
float sobel_depth(float2 texcoord, float2 offset)
{
    float xSobDepth = 0.0f;
    float ySobDepth = 0.0f;

    for (int row = 0; row < 3; row++)
    {
        for( int col = 0; col < 3; col ++)
        {
            float depth = DepthCalc(texcoord + offset.xy * float2(col-1, row-1));
            xSobDepth += Gx[row][col] * depth_weight/100.0f * depth;
            ySobDepth += Gy[row][col] * depth_weight/100.0f * depth;
        }
    }


    return sqrt(pow(xSobDepth, 2.0) + pow(ySobDepth, 2.0));
}


//Sobel operation on the normal buffer.
// Convolves again with the Gx and Gy kernels, using luminance, and the normal buffer, to determine where edges are on
// an object, or between multiple objects, where depth maybe won't find one.
float sobel_normal(float2 texcoord, float2 offset)
{
    float xSobNorm = 0.0f;
    float ySobNorm = 0.0f;

    for (int row = 0; row < 3; row++)
    {
        for( int col = 0; col < 3; col ++)
        {
            float3 avg = colAvg(tex2D(normalSampler, texcoord + offset.xy * float2(col-1, row-1)).rgb);
            float lumi = luminance(avg);
            xSobNorm += Gx[row][col] * norm_weight * lumi;
            ySobNorm += Gy[row][col] * norm_weight * lumi;
        }
    }


    return sqrt(pow(xSobNorm, 2.0) + pow(ySobNorm, 2.0));
}


// Thresholds the normal and depth sobel results, giving control over how "many" of the less certain
// edges are output. Afterwards, it'll combine the results together, and mix it with the backbuffer's color.

//This pass also outputs the end result onto the screen.
float4 PS_EdgeDetect( float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 offset = BUFFER_PIXEL_SIZE;
    float4 color = tex2D(colorBuff, texcoord);

    float edge_depth = sobel_depth(texcoord, offset);
    float edge_normal = sobel_normal(texcoord, offset);
    if( edge_depth < 10 * depthreshold)
    {
    	edge_depth = 0.0f;
    }
    if( edge_normal < 5 * normthreshold)
    {
    	edge_normal = 0.0f;
    }


    float4 normoutline = smoothstep(0.3, 1.0,  edge_normal);
    float4 depthoutline = smoothstep(0.8, 4.0,  edge_depth);
    
    
    float4 final_color = normoutline.rgba;
    final_color += depthoutline.rgba;
	float4 outline = (float4(final_color.rgb,1.0) * float4(Outline_color,1.0) )/ (float4(final_color.rgb,1.0) + float4(Outline_color,1.0));
    color -= final_color;
	color += 5 *  clamp(outline,0.0000f, 1.0000f);
    return color;
}




technique DestreaFX_EdgeDetect < ui_label = "Edge detection and Outline"; ui_tooltip = "Approximates edges of an image, and can apply outlines to them."; >
{



    pass Normal
    {
        RenderTarget = normalTex;
        VertexShader = PostProcessVS;
        PixelShader = SetNormalBuff;
    }

    pass End
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_EdgeDetect;
    }

}
