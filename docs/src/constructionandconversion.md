# Construction and Conversion


## Available colorspaces

The colorspaces used by Colors are defined in [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl). Briefly, the defined spaces are:

- Red-Green-Blue spaces: `RGB`, `BGR`, `XRGB`, `RGBX`, `RGB24`, plus transparent versions `ARGB`, `RGBA`, `ABGR`, `BGRA`, and `ARGB32`.

- `HSV`, `HSL`, `HSI`, plus all 6 transparent variants (`AHSV`, `HSVA`, `AHSL`, `HSLA`, `AHSI`, `HSIA`)

- `XYZ`, `xyY`, `LMS` and all 6 transparent variants

- `Lab`, `Luv`, `LCHab`, `LCHuv` and all 8 transparent variants

- `DIN99`, `DIN99d`, `DIN99o` and all 6 transparent variants

- Storage formats `YIQ`, `YCbCr` and their transparent variants

- `Gray`, `Gray24`, and the transparent variants `AGray`, `GrayA`, and `AGray32`.

## Converting colors

Colors.jl allows you to convert from one colorspace to another using the `convert` function.

For example:

```jldoctest example
julia> using Colors

julia> convert(RGB, HSL(270, 0.5, 0.5))
RGB{Float64}(0.5,0.25,0.75)
```

Depending on the source and destination colorspace, this may not be perfectly lossless.

## Color Parsing


```jldoctest example
julia> c = colorant"red"
RGB{N0f8}(1.0,0.0,0.0)

julia> parse(Colorant, "red")
RGB{N0f8}(1.0,0.0,0.0)

julia> parse(Colorant, HSL(1, 1, 1))
HSL{Float32}(1.0f0,1.0f0,1.0f0)

julia> colorant"#FF0000"
RGB{N0f8}(1.0,0.0,0.0)

julia> parse(Colorant, RGBA(1, 0.5, 1, 0.5))
RGBA{Float64}(1.0,0.5,1.0,0.5)
```

You can parse any [CSS color specification](https://developer.mozilla.org/en-US/docs/CSS/color) with the exception of `currentColor`.

All CSS/SVG named colors are supported, in addition to X11 named colors, when their definitions do not clash with SVG.

When writing functions the `colorant"red"` version is preferred, because the slow step runs when the code is parsed (i.e., during compilation rather than run-time).

```@docs
@colorant_str
hex
parse
```
