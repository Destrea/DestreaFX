#include "ReShade.fxh"
#include "ReShadeUI.fxh"


texture2D texColorBuffer : COLOR;

sampler2D samplerColor
{
    Texture = texColorBuffer;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;
};

uniform int Type <
    ui_type = "combo";
    ui_items = "2 Color Palette\0Black and White\0Custom Palette\0Procedural Palette\0Three Bit RGB\0Non-Dither Palette\0None\0";
    ui_category = "General Settings";
> = 2;

uniform bool GammaCorrected < ui_label = "Gamma Correction";   ui_tooltip = "Enables and disables gamma brightness correction."; ui_category = "General Settings";> = true;
uniform float gamma < __UNIFORM_SLIDER_INT1 ui_label = "Gamma level"; ui_tooltip = "Controls the strength of the gamma brightness correction."; ui_category = "General Settings"; ui_min = 1.0; ui_max = 5.0; > = 2.2f;
uniform int bayerLevel < __UNIFORM_SLIDER_INT1 ui_label = "Dither Level"; ui_tooltip="Changes the Bayer dithering effect \"size\" (0 = 2x2, 1 = 4x4, 2 = 8x8)"; ui_category = "General Settings"; ui_min = 1; ui_max = 3; > = 3;
uniform float lumiVar < __UNIFORM_SLIDER_INT1 ui_label = "Dither Strength"; ui_tooltip= "Changes the strength, and 'blending' of the applied dither effect with the surrounding colors."; ui_category = "General Settings"; ui_min = 0.001; ui_max = 1.0; > = 0.7f;


uniform int _CustomPalette <
    ui_label = " ";
    ui_text = "For use with the \"Custom Palette\" type option";
    ui_category = "Custom Color Palette";
    ui_type = "radio";
>;

//Bayer Dither Look-up-table
static float bayer2[2*2] = { 0, 2, 3, 1};
static float bayer4[4*4] = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5};
static float bayer8[8*8] = {0, 32, 8, 40, 2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
    3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21};

float getBayer2(int x, int y)
{
    return float(bayer2[(x%uint(2))+(y % uint(2)) * 2]) * (1.0f / 4.0f) - 0.5f;
}

float getBayer4(int x, int y)
{
    return float(bayer4[(x%uint(4))+(y % uint(4))* 4]) * (1.0f / 16.0f) - 0.5f;
}

float getBayer8(int x, int y)
{
    return float(bayer8[(x%uint(8))+(y % uint(8))* 8]) * (1.0f / 64.0f) - 0.5f;
}

float3 posterize (float3 color, int levels)
{
    return (floor(color * (levels-1) + 0.5)) / (levels-1);
}


uniform float3 ColorMatrix_1 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 1";
ui_category = "Custom Color Palette";
> = float3(0.06274509803921569,0.3254901960784314,0.5647058823529412);

uniform float3 ColorMatrix_2 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 2";
ui_category = "Custom Color Palette";
> = float3(0.10588235294117647,0.5843137254901961,0.5529411764705883);

uniform float3 ColorMatrix_3 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 3";
ui_category = "Custom Color Palette";
> = float3(0.3686274509803922,0.7137254901960784,0.6784313725490196);

uniform float3 ColorMatrix_4 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 4";
ui_category = "Custom Color Palette";
> = float3(0.8470588235294118,00.8627450980392157,0.7058823529411765);

uniform float3 ColorMatrix_5 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 5";
ui_category = "Custom Color Palette";
> = float3(0.996078431372549,0.6588235294117647,0.37254901960784315);

uniform float3 ColorMatrix_6 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 6";
ui_category = "Custom Color Palette";
> = float3(0.8862745098039215,0.3803921568627451,0.34901960784313724);

uniform float3 ColorMatrix_7 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 7";
ui_category = "Custom Color Palette";
> = float3(0.8862745098039215,0.10980392156862745,0.3803921568627451);

uniform float3 ColorMatrix_8 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Palette Color 8";
ui_category = "Custom Color Palette";
> = float3(0.2196078431372549,0.08627450980392157,0.19215686274509805);

uniform float3 ColorMatrix_9 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Dual Palette Color 1";
ui_category = "Two Color Palette";
> = float3(0.8470588235294118,00.8627450980392157,0.7058823529411765);

uniform float3 ColorMatrix_10 < __UNIFORM_COLOR_FLOAT3
ui_min = 0.0;
ui_max = 1.0;
ui_label = "Dual Palette Color 2";
ui_category = "Two Color Palette";
> = float3(0.2196078431372549,0.08627450980392157,0.19215686274509805);


//Placeholder, to eventually be used for more procedural palette generator options
//uniform int ProcType < ui_category = "ProceduralColor";ui_type = "combo";ui_items = "Monochromatic\0Black and White\0Custom Palette\0Procedural Palette\0None\0";> = 2;

uniform int hueSlider < __UNIFORM_SLIDER_INT1 ui_label = "Hue Slider"; ui_tooltip = "Changes the base hue for the 'monochrome' color palette generator."; ui_category = "Procedural Color"; ui_min = 0; ui_max = 359; > = 312;

uniform int satuStep < __UNIFORM_SLIDER_INT1 ui_label = "Monochrome Saturation Step"; ui_tooltip = "Changes how much the Saturation is changed for each generated color."; ui_category = "Procedural Color";ui_min = 1; ui_max = 15; > = 5;   //1-15%

uniform int lumiStep < __UNIFORM_SLIDER_INT1 ui_label = "Monochrome Luminance Step"; ui_tooltip = "Changes how much the Luminance is changed for each generated color."; ui_category = "Procedural Color"; ui_min = 15; ui_max = 30; > = 30; // 15-30%



//Custom modulo operator, since the builtin ReShade one doesnt allow modulo on negative values.
float mod(float v,float d)
{
    return v - (floor(v/d) * d);
}

//sRGB to linear RGB conversion, for gamma correction.
float srgbToLinear(float b)
{
    if(b <= 0.04045)
    {
        return (b/12.92);
    }
    else
    {
        return pow(((b+0.055)/1.055),gamma);
    }
}

float gammaUncorrect(float val)
{
    return pow(val, (1.0/gamma));
}

float3 RGBtoHSL(float3 color)
{
    float R = color.r;
    float G = color.g;
    float B = color.b;

    float minVal = min(min(R, G), B);
    float maxVal = max(max(R, G), B);
    float delta = maxVal - minVal;

    float hue;
    if(maxVal == R)
    {
        hue = 60 * (mod(((G-B) / (delta)),6));
    }
    else if(maxVal == G)
    {
        hue = 60 * (2.0f + ((B-R)/(delta)));
    }
    else if(maxVal == B)
    {
        hue = 60 * (4.0f + (R-G)/(delta));
    }

    //hue *= 60;

    //Luminance
    float luminance = (maxVal + minVal)/2.0f;

    //Saturation
    float saturation = 0.0;
    if(delta != 0.0)
    {
        saturation = (delta) / (1.0f- abs(2.0f * luminance - 1.0f));
    }
    return float3(hue,saturation,luminance);
}

float3 HSLtoRGB(float3 HSL)
{
    float H = HSL.r;
    float S = HSL.g;
    float L = HSL.b;

    float R, G, B;

    //chrominance calc
    float C = (1.0f-abs(2.0f * L -1.0f)) * S;

    float X = C * (1.0f - abs(mod((H/60),2.0f) - 1.0f));

    float m = L - (C/2.0f);

    //calculate the RGB values now.
    if(0 <= H && H < 60)
    {
        return float3(C + m,X + m,0.0f + m);
    }
    else if(60 <= H && H < 120)
    {
        return float3(X + m,C + m,0.0f + m);
    }
    else if(120 <= H && H < 180)
    {
        return float3(0.0f + m,C + m,X + m);
    }
    else if(180 <= H && H < 240)
    {
        return float3(0.0f + m,X + m,C + m);
    }
    else if(240 <= H && H < 300)
    {
        return float3(X + m,0.0f + m,C + m);
    }
    else if(300 <= H && H < 360)
    {
        return float3(C + m,0.0f + m,X + m);
    }

   // return float3((temp.r+m), (temp.g+m), (temp.b+m));

}

float3 findClosestColorPair(float3 palette[2], float3 attempt, int maxLumi)
{
    float shortest = pow((palette[maxLumi].r - attempt.r),2) + pow((palette[maxLumi].g - attempt.g),2) + pow((palette[maxLumi].b - attempt.b),2);
    float3 closestColor = palette[maxLumi];
    for(int i = 0; i < 2; i++)
    {
        float dist = pow((palette[i].r - attempt.r),2) + pow((palette[i].g - attempt.g),2) + pow((palette[i].b - attempt.b),2);
        if(dist <= shortest)
        {
            shortest = dist;
            closestColor = palette[i];
        }
    }
    return closestColor;
}


float3 findClosestColorFrom(float3 palette[8], float3 attempt, int maxLumi)
{	
    //maxLumi = 3;
	float shortest = pow((palette[maxLumi].r - attempt.r),2) + pow((palette[maxLumi].g - attempt.g),2) + pow((palette[maxLumi].b - attempt.b),2);
	//float shortest = 1000;
    float3 closestColor = palette[maxLumi];
	for(int i = 0; i < 8; i++)
	{
		float dist = pow((palette[i].r - attempt.r),2) + pow((palette[i].g - attempt.g),2) + pow((palette[i].b - attempt.b),2);
		//float3 paletteColor = float3(palette[i].r, palette[i].g, palette[i].b);
        //float dist = colorCompare(paletteColor, attempt);
		if(dist <= shortest)
		{
			shortest = dist;
			closestColor = palette[i];
		}
	}
	return closestColor;
}

int highestLumi(float3 palette[8])
{
    int index = 0;
    float highest = 0;
    for(int i = 0; i < 8; i++)
    {
        float lumi = RGBtoHSL(palette[i]).b;
        if(lumi > highest)
        {
            highest = lumi;
            index = i;
        }
    }
    return index;
}

int highLumiPair(float3 palette[2])
{
    int index = 0;
    float highest = 0;
    for(int i = 0; i < 2; i++)
    {
        float lumi = RGBtoHSL(palette[i]).b;
        if(lumi > highest)
        {
            highest = lumi;
            index = i;
        }
    }
    return index;
}


float3 monochromeGen(float3 color, float sat, float lum)
{
    return float3(color.r, color.g + sat, color.b + lum);
}

float3 PS_Dither(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 luminanceVec = float3(0.299, 0.587, 0.114);

    //Custom Color Palettes. 8-color and 2-color
    float3 paletteC[8] = {ColorMatrix_1,ColorMatrix_2,ColorMatrix_3,ColorMatrix_4,ColorMatrix_5,ColorMatrix_6,ColorMatrix_7,ColorMatrix_8};
    float3 palette2[2] = {ColorMatrix_9, ColorMatrix_10};

	float3 vec = float3(0.21, 0.72, 0.07);

    float3 color = tex2D(samplerColor, texcoord).rgb;
    float3 final_color = color;

    float3 thresh = float3(1.0/8, 1.0/8, 1.0/8);
    int x = texcoord.x * BUFFER_WIDTH;
    int y = texcoord.y * BUFFER_HEIGHT;
	
    //Bayer factor selection
    float bayerValues[3];
    bayerValues[0] = getBayer2(x % 2,y % 2);
    bayerValues[1] = getBayer4(x % 4,y % 4);
    bayerValues[2] = getBayer8(x % 8,y % 8);
    float factor = bayerValues[bayerLevel-1];

    float3 linearRGB = final_color;
    float3 pColor;
    float3 attempt;

    //Gamma correction and sRGB -> Linear RGB conversion
    if(GammaCorrected)
    {
        linearRGB = float3(srgbToLinear(final_color.r), srgbToLinear(final_color.g),srgbToLinear(final_color.b));
    }

    //Two Color & Black and White Dither
    if(Type == 0 || Type == 1)
    {

        float3 palette[2];
        attempt = linearRGB - (factor * thresh) - lumiVar/10.0;
        if(Type == 1)
        {
            //Black and White color Palette
            palette = {float3(0.0,0.0,0.0), float3(1.0,1.0,1.0)};
        }
        else
        {
            palette = palette2;
        }
        int maxLumi = highLumiPair(palette);
        pColor = findClosestColorPair(palette, attempt, maxLumi);



    }
    else if(Type == 2)  //Custom Color Palette
    {
        attempt = linearRGB - (factor * thresh) - lumiVar/10.0;
        int maxLumi = highestLumi(paletteC);
        pColor = findClosestColorFrom(paletteC, attempt, maxLumi);

    }
    else if(Type == 3)  //Procedural Palette generation
    {

        linearRGB = dot(linearRGB, luminanceVec);
        float3 monoPalette[8];
        float3 baseColor = float3(hueSlider, .436, .153);
        monoPalette[0] = baseColor;
        attempt = linearRGB + factor * thresh;
        float sat = satuStep/100.0f;
        float lum = lumiStep/100.0f;
        for(int i = 1; i < 8; i++)
        {
            monoPalette[i] = monochromeGen(monoPalette[i-1],sat,lum);
        }
        for(int j = 0; j <= 7; j++)
        {
            monoPalette[j] = HSLtoRGB(monoPalette[j]);
        }
        int maxLumi = highestLumi(monoPalette);
        pColor = findClosestColorFrom(monoPalette, attempt, maxLumi);



    }
    else if(Type == 4)  //Three-Bit RGB dither
    {
        //3 bit RGB format color palette.
        float3 threeBitRGB[8] = {float3(0,0,0),float3(255,255,255),float3(255,0,0),float3(0,255,0),float3(0,0,255),float3(255,255,0),float3(0,255,255),float3(255,0,255)};
        attempt = linearRGB - (factor * thresh) - lumiVar/10.0;
        int maxLumi = highestLumi(threeBitRGB);
        float3 closestColor = findClosestColorFrom(threeBitRGB, attempt, maxLumi);
        pColor = closestColor;
    }
    else if(Type == 5)  //"None"
    {
        int maxLumi = highestLumi(paletteC);
        pColor = findClosestColorFrom(paletteC, linearRGB, maxLumi);
    }
    else if(Type == 6)  //"None"
    {
        attempt = linearRGB + factor * thresh;
        pColor = attempt;
        if(GammaCorrected)
        {
            pColor = float3(gammaUncorrect(pColor.r), gammaUncorrect(pColor.g),gammaUncorrect(pColor.b));

        }
    }

    return pColor;
}

technique DestreaFX_Dither < ui_label = "DestreaFX Dithering and Palette Swap"; ui_tooltip = "A variety of effects utilizing a Bayer Ordered Dither, and color palette swapping."; >
{

    pass Dither
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Dither;
    }

}
