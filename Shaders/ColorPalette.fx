#include "ReShade.fxh"
#include "ReShadeUI.fxh"


// ColorPalette.fx implements a fragment shader that replaces the backbuffer's colors with the closest
// color picked from the color palette. This custom color palette can be made up of any 8 colors, chosen by the user.
// Each color is able to be picked using the UI using a color wheel, RGB, HSV or Hex values.

// Additionally, a color "Posterization" effect is used, to limit the number of colors present in the source image, allowing
// the color palette to be better applied. In the future I'm planning to re-work the posterization functionality, to produce better results,
// and to add a dithering option, either as part of this .fx file, or on its own.


texture2D texColorBuffer : COLOR;

sampler2D samplerColor
{
    Texture = texColorBuffer;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;
};


// Color Limit/Quantize Settings
uniform bool Enable_color_limit <
    ui_label = "Color Limiting";
    ui_tooltip = "Enables the color quantize (limit) filtering";
    ui_category = "Color options";
> = 1;

uniform int Color_levels < __UNIFORM_SLIDER_INT1
    ui_min = 4;
    ui_max = 256;
    ui_label = "Color Levels";
    ui_tooltip = "The max number of colors that will be displayed on screen";
    ui_category = "Color options";
> = 8;


// Color Palette Settings
uniform bool Enable_palette <
    ui_label = "Color Palette";
    ui_tooltip = "Enables the color palette filter, with the specified colors";
    ui_category = "Color options";
> = 1;

uniform float3 ColorMatrix_1 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 1";
> = float3(0.06274509803921569,0.3254901960784314,0.5647058823529412);

uniform float3 ColorMatrix_2 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 2";
> = float3(0.10588235294117647,0.5843137254901961,0.5529411764705883);

uniform float3 ColorMatrix_3 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 3";
> = float3(0.3686274509803922,0.7137254901960784,0.6784313725490196);

uniform float3 ColorMatrix_4 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 4";
> = float3(0.8470588235294118,00.8627450980392157,0.7058823529411765);

uniform float3 ColorMatrix_5 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 5";
> = float3(0.996078431372549,0.6588235294117647,0.37254901960784315);

uniform float3 ColorMatrix_6 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 6";
> = float3(0.8862745098039215,0.3803921568627451,0.34901960784313724);

uniform float3 ColorMatrix_7 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 7";
> = float3(0.8862745098039215,0.10980392156862745,0.3803921568627451);

uniform float3 ColorMatrix_8 < __UNIFORM_COLOR_FLOAT3
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Palette Color 8";
> = float3(0.2196078431372549,0.08627450980392157,0.19215686274509805);




float posterize (float val, int levels)
{
    return round(val * float(levels)) / float(levels);
}

float3 ToonPass(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    //Grab the screen color from the backbuffer at the current texcoord
    float3 final_color = tex2D(samplerColor,texcoord).rgb;

    //Initialize the color palette with the selected colors
    float3 palette[8];
    palette[0] = ColorMatrix_1;
    palette[1] = ColorMatrix_2;
    palette[2] = ColorMatrix_3;
    palette[3] = ColorMatrix_4;
    palette[4] = ColorMatrix_5;
    palette[5] = ColorMatrix_6;
    palette[6] = ColorMatrix_7;
    palette[7] = ColorMatrix_8;

    //Color Posterization, reduced down to the color limit set.
    if(Enable_color_limit)
    {
        final_color += float3(posterize(final_color.r,Color_levels),posterize(final_color.g,Color_levels),posterize(final_color.b,Color_levels));
    }

    //Applies the color palette, according to the "distance" calated from the original color, to the closest palette color.
    if(Enable_palette)
    {
        //Color_levels = 8;

        float3 difference = final_color - palette[0];
        float dist = dot(difference,difference);

        float closest_distance = dist;
        float3 closest_color = palette[0];

        for(int i = 0; i < 8; i++)
        {
            difference = final_color - palette[i];
            dist = dot(difference,difference);

            if(dist < closest_distance)
            {
                closest_distance = dist;
                closest_color = palette[i];
            }
        }
        final_color = closest_color;
    }

    return final_color;
}


float3 PS_Toon( float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 color = ToonPass(position, texcoord);
    return color.rgb;
}

technique ColorPalette
{
   
	pass Toon
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Toon;
	}
	
}
