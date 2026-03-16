# DestreaFX
Modular post processing shaders built for ReShade, intended for use with Final Fantasy XIV gameplay and GPose.

For installation and setup walkthroughs, refer to the [wiki]().

## Example Screenshots

### Dithering Shader
#### Original Image
![example1](./Examples/NoShader.png) <br>
#### Comparison
![example2](./Examples/ShaderLines.png) <br>
#### Close-up 3Bit RGB
![example3](./Examples/Shader3BitClose.png) <br>
#### Color palette-swapped
![example4](./Examples/ShaderPaletteND.png) <br>
#### 2-Tone Black and White
![example5](./Examples/ShaderBW.png) <br>

### References: <br>
Joel Yliluoma's dithering algorithm: https://bisqwit.iki.fi/story/howto/dither/jy/ <br>
Normal-map generation from DisplayDepth.fx: https://github.com/crosire/reshade-shaders/tree/slim/Shaders <br>
Sobel Operator: https://en.wikipedia.org/wiki/Sobel_operator <br>
General Edge-detection ref: https://www.youtube.com/watch?v=gg40RWiaHRY <br>
Color Posterization: https://lettier.github.io/3d-game-shaders-for-beginners/posterization.html <br>
Default Color Palette: https://lospec.com/palette-list/vividmemory8 <br>
