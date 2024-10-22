# Construction and Conversion


## Available colorspaces

The colorspaces used by Colors are defined in [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl). Briefly, the defined spaces are:

- Red-Green-Blue spaces: `RGB`, `BGR`, `XRGB`, `RGBX`, `RGB24`, plus transparent versions `ARGB`, `RGBA`, `ABGR`, `BGRA`, and `ARGB32`.

- `HSV`, `HSL`, `HSI`, plus all 6 transparent variants (`AHSV`, `HSVA`, `AHSL`, `HSLA`, `AHSI`, `HSIA`)
```@example cross
using Colors # hide
using Main: CrossSectionalCharts # hide
CrossSectionalCharts.crosssection(HSV) # hide
```
```@example cross
CrossSectionalCharts.crosssection(HSL) # hide
```
```@example cross
CrossSectionalCharts.crosssection(HSI) # hide
```
- `XYZ`, `xyY`, `LMS` and all 6 transparent variants

- `Lab`, `Luv`, `LCHab`, `LCHuv` and all 8 transparent variants
```@example cross
CrossSectionalCharts.crosssection(Lab) # hide
```
```@example cross
CrossSectionalCharts.crosssection(Luv) # hide
```
```@example cross
CrossSectionalCharts.crosssection(LCHab) # hide
```
```@example cross
CrossSectionalCharts.crosssection(LCHuv) # hide
```
- `Oklab`, `Oklch` and their transparent variants
```@example cross
CrossSectionalCharts.crosssection(Oklab) # hide
```
```@example cross
CrossSectionalCharts.crosssection(Oklch) # hide
```
- `DIN99`, `DIN99d`, `DIN99o` and all 6 transparent variants

- Storage formats `YIQ`, `YCbCr` and their transparent variants
```@example cross
CrossSectionalCharts.crosssection(YIQ) # hide
```
```@example cross
CrossSectionalCharts.crosssection(YCbCr) # hide
```
- `Gray`, `Gray24`, and the transparent variants `AGray`, `GrayA`, and `AGray32`.


## Color Parsing

You can parse any [CSS color specification](https://developer.mozilla.org/en-US/docs/CSS/color)
with the exception of `currentColor`. You can construct colors from strings
using the [`@colorant_str`](@ref) macro and the [`parse`](@ref) function.

```jldoctest example
julia> using Colors

julia> colorant"red" # named color
RGB{N0f8}(1.0, 0.0, 0.0)

julia> parse(Colorant, "DeepSkyBlue") # color names are case-insensitive
RGB{N0f8}(0.0, 0.749, 1.0)

julia> colorant"#FF0000" # 6-digit hex notation
RGB{N0f8}(1.0, 0.0, 0.0)

julia> colorant"#f00" # 3-digit hex notation
RGB{N0f8}(1.0, 0.0, 0.0)

julia> colorant"rgb(255,0,0)" # rgb() notation with integers in [0, 255]
RGB{N0f8}(1.0, 0.0, 0.0)

julia> colorant"rgba(255,0,0,0.6)" # with alpha in [0, 1]
RGBA{N0f8}(1.0, 0.0, 0.0, 0.6)

julia> colorant"rgba(100%,80%,0.0%,0.6)" # with percentages
RGBA{N0f8}(1.0, 0.8, 0.0, 0.6)

julia> parse(ARGB, "rgba(255,0,0,0.6)") # you can specify the return type
ARGB{N0f8}(1.0, 0.0, 0.0, 0.6)

julia> colorant"hsl(120, 100%, 25%)" # hsl() notation
HSL{Float32}(120.0, 1.0, 0.25)

julia> colorant"hsla(120, 100%, 25%, 60%)" # hsla() notation
HSLA{Float32}(120.0, 1.0, 0.25, 0.6)

julia> colorant"transparent" # transparent "black"
RGBA{N0f8}(0.0, 0.0, 0.0, 0.0)
```

All CSS/SVG named colors are supported, in addition to X11 named colors, when their definitions do not clash with SVG.
You can find all names and their color swatches in [Named Colors](@ref) page.

When writing functions the `colorant"red"` version is preferred, because the slow step runs when the code is parsed (i.e., during compilation rather than run-time).

The element types of the return types depend on the colorspaces, i.e. the `hsl()`
and `hsla()` notations return `HSL`/`HSLA` colors with `Float32` elements, and
other notations return `RGB`/`RGBA` colors with `N0f8` elements. The result
colors can be converted to `RGB{N0f16}` (for example) using:

```jldoctest example
julia> using FixedPointNumbers

julia> RGB{N0f16}(colorant"indianred")
RGB{N0f16}(0.80392, 0.36078, 0.36078)
```
or
```jldoctest example
julia> parse(RGB{N0f16}, "indianred")
RGB{N0f16}(0.80392, 0.36078, 0.36078)
```


You can convert colors to hexadecimal strings using the [`hex`](@ref) function.
Note that the conversion result does not have the prefix `"#"`.

```jldoctest example
julia> col = colorant"#C0FFEE"
RGB{N0f8}(0.753, 1.0, 0.933)

julia> hex(col)
"C0FFEE"
```

## Color Conversions

Colors.jl allows you to convert from one colorspace to another using the `convert` function.

For example:

```jldoctest example
julia> convert(RGB, HSL(270, 0.5, 0.5)) # without the element type
RGB{Float64}(0.5, 0.25, 0.75)

julia> convert(RGB{N0f8}, HSL(270, 0.5, 0.5)) # with the element type
RGB{N0f8}(0.502, 0.251, 0.749)
```

Depending on the source and destination colorspace, this may not be perfectly lossless.

## Transparent - Opaque Conversions

Colors.jl allows you to convert colors to transparent or opaque types.

```jldoctest example
julia> col = colorant"yellow"
RGB{N0f8}(1.0, 1.0, 0.0)

julia> transparent = alphacolor(col, 0.5)  # or coloralpha(col)
ARGB{N0f8}(1.0, 1.0, 0.0, 0.502)

julia> opaque = color(transparent)
RGB{N0f8}(1.0, 1.0, 0.0)
```

---

```@docs
@colorant_str
parse
hex
normalize_hue
mean_hue
```
