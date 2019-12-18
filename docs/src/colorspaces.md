# Colorspaces


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

## Color match for CIE Standard Observer

The `colormatch()` function returns an XYZ color corresponding to a wavelength specified in nanometers.

`colormatch(wavelen::Real)`

The CIE defines a *standard observer*, defining a typical frequency response curve for each of the three human eye cones.

For instance, conversion from optical wavelength to RGB can be achieved with:

```@example
using Colors # hide
showable(::MIME"text/plain", ::AbstractVector{C}) where {C<:Colorant} = false # hide
RGB.(colormatch.(350:10:750))
```

```@docs
colormatch
```

## Chromatic Adaptation (white balance)

The `whitebalance()` function converts a color according to a reference white point.

`whitebalance{T <: Color}(c::T, src_white::Color, ref_white::Color)`

Convert a color `c` viewed under conditions with a given source whitepoint `src_whitepoint` to appear the same under different conditions specified by a reference whitepoint `ref_white`.

```@docs
whitebalance
```

## Color Difference

The `colordiff` function gives an approximate value for the difference between two colors.

```jldoctest example
julia> colordiff(colorant"red", parse(Colorant, HSV(360, 0.75, 1)))
8.178248292426845
```

`colordiff(a::Color, b::Color; metric::DifferenceMetric=DE_2000())`

Evaluate the [CIEDE2000](http://en.wikipedia.org/wiki/Color_difference#CIEDE2000) color difference formula by default. This gives an approximate measure of the perceptual difference between two colors to a typical viewer. A larger number is returned for increasingly distinguishable colors.

Options for `DifferenceMetric` are as follows:

| Option                                                 | Action                                        |
| ----------                                             | -------                                       |
|`DE_2000(kl::Float64, kc::Float64, kh::Float64)`        | Specify the color difference using the recommended CIEDE2000 equation, with weighting parameters `kl`, `kc`, and `kh` as provided for in the recommendation.|
|`DE_2000()`                                             | - when not provided, these parameters default to 1.                                                                                                         |
|`DE_94(kl::Float64, kc::Float64, kh::Float64)`          | Specify the color difference using the recommended CIEDE94 equation, with weighting parameters `kl`, `kc`, and `kh` as provided for in the recommendation.  |
|`DE_94()`                                               | - hen not provided, these parameters default to 1.                                                                                                          |
|`DE_JPC79()`                                            | Specify McDonald's "JP Coates Thread Company" color difference formula.                                                                                     |
|`DE_CMC(kl::Float64, kc::Float64)`                      | Specify the color difference using the CMC equation, with weighting parameters `kl` and `kc`.                                                               |
|`DE_CMC()`                                              | - when not provided, these parameters default to 1.                                                                                                         |
|`DE_BFD(wp::XYZ, kl::Float64, kc::Float64)`             | Specify the color difference using the BFD equation, with weighting parameters `kl` and `kc`. Additionally, a white point can be specified, because the BFD equation must convert between `XYZ` and `LAB` during the computation.|
|`DE_BFD(kl::Float64, kc::Float64)`                      |                                                                   |
|`DE_BFD()`                                              | - when not specified, the constants default to 1, and the white point defaults to CIED65.                                                                   |
|`DE_AB()`                                               | Specify the original, Euclidean color difference equation.                                                                                                  |
|`DE_DIN99()`                                            | Specify the Euclidean color difference equation applied in the `DIN99` uniform colorspace.                                                                 |
|`DE_DIN99d()`                                           | Specify the Euclidean color difference equation applied in the `DIN99d` uniform colorspace.                                                                 |
|`DE_DIN99o()`                                           | Specify the Euclidean color difference equation applied in the `DIN99o` uniform colorspace.                                                                 |

```@docs
colordiff
```

## Simulation of color deficiency ("color blindness")

Three functions are provided that map colors to a reduced gamut to simulate different types of *dichromacy*, the loss of one of the three types of human photopigments.

*Protanopia*, *deuteranopia*, and *tritanopia* are the loss of long, middle, and short wavelength photopigment, respectively.

These functions take a color and return a new, altered color in the same colorspace.

```julia
protanopic(c::Color, p::Float64)
deuteranopic(c::Color, p::Float64)
tritanopic(c::Color, p::Float64)
```

Also provided are versions of these functions with an extra parameter `p` in `[0, 1]`, giving the degree of photopigment loss, where 1.0 is a complete loss, and 0.0 is no loss at all.

```@docs
protanopic
deuteranopic
tritanopic
```
