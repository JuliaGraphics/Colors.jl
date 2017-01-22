# Colors

[![Colors](http://pkg.julialang.org/badges/Colors_0.4.svg)](http://pkg.julialang.org/?pkg=Colors&ver=0.4)
[![Build Status](http://img.shields.io/travis/JuliaGraphics/Colors.jl.svg)](https://travis-ci.org/JuliaGraphics/Colors.jl)
[![codecov.io](http://codecov.io/github/JuliaGraphics/Colors.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaGraphics/Colors.jl?branch=master)

This library provides a wide array of functions for dealing with color. This
includes conversion between colorspaces, measuring distance between colors,
simulating color blindness, and generating color scales for graphics, among
other things.

This was forked from an original repository called `Color.jl` created
by Daniel Jones.  Some tips about migrating from `Color.jl` to
`Colors.jl` are at the end of this README.

## Colorspaces

The colorspaces used by Colors are defined in [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl).  Colors allows you to convert from one colorspace to another using the `convert` function.

E.g.
```julia
convert(RGB, HSL(270, 0.5, 0.5))
```

Depending on the source and destination colorspace, this may not be perfectly
lossless.

The available colorspaces are described in detail in ColorTypes; briefly, the defined spaces are:

- Red-Green-Blue spaces: `RGB`, `BGR`, `RGB1`, `RGB4`, `RGB24`, plus
  transparent versions `ARGB`, `RGBA`, `ABGR`, `BGRA`, and `ARGB32`.

- `HSV`, `HSL`, `HSI`, plus all 6 transparent variants (`AHSV`,
  `HSVA`, `AHSL`, `HSLA`, `AHSI`, `HSIA`)

- `XYZ`, `xyY`, `LMS` and all 6 transparent variants

- `Lab`, `Luv`, `LCHab`, `LCHuv` and all 8 transparent variants

- `DIN99`, `DIN99d`, `DIN99o` and all 6 transparent variants

- Storage formats `YIQ`, `YCbCr` and their transparent variants

- `Gray`, `Gray24`, and the transparent variants `AGray`, `GrayA`, and
  `AGray32`.

## Color Parsing

```jl
c = colorant"red"
c = parse(Colorant, "red")
c = colorant"#7aa457" # hex triplets are also supported
```

Parse a [CSS color specification](https://developer.mozilla.org/en-US/docs/CSS/color). It will parse any CSS color syntax with the exception of `currentColor`.

All CSS/SVG named colors are supported, in addition to X11 named colors, when
their definitions do not clash with SVG.

Returns a `RGB{U8}` color, unless:

- `"hsl(h,s,l)"` was used, in which case an `HSL` color;
- `"rgba(r,g,b,a)"` was used, in which case an `RGBA` color;
- `"hsla(h,s,l,a)"` was used, in which case an `HSLA` color;
- a specific `Colorant` type was specified in the first argument

When writing functions the `colorant"red"` version is preferred, because
the slow step runs when the code is parsed (i.e., during compilation
rather than run-time).

## CIE Standard Observer

`colormatch(wavelen::Real)`

The CIE defines a standard observer, defining typical frequency response curve
for each of the three human cones. This function returns an XYZ color
corresponding to a wavelength specified in nanometers.

## Chromatic Adaptation (white balance)

`whitebalance{T <: Color}(c::T, src_white::Color, ref_white::Color)`

Convert a color `c` viewed under conditions with a given source whitepoint
`src_whitepoint`, to appear the same under a different conditions specified by a
reference whitepoint `ref_white`.

## Color Difference

`colordiff(a::Color, b::Color)`

Evaluate the
[CIEDE2000](http://en.wikipedia.org/wiki/Color_difference#CIEDE2000) color
difference formula. This gives an approximate measure of the perceptual
difference between two colors to a typical viewer. A larger number is returned
for increasingly distinguishable colors.

`colordiff(a::Color, b::Color, m::DifferenceMetric)`

Evaluate the color difference formula specified by the supplied `DifferenceMetric`. Options are as follows:

`DE_2000(kl::Float64, kc::Float64, kh::Float64)`
`DE_2000()`

Specify the color difference using the recommended CIEDE2000 equation, with weighting parameters `kl`, `kc`, and `kh` as provided for in the recommendation. When not provided, these parameters default to 1.

`DE_94(kl::Float64, kc::Float64, kh::Float64)`
`DE_94()`

Specify the color difference using the recommended CIEDE94 equation, with weighting parameters `kl`, `kc`, and `kh` as provided for in the recommendation. When not provided, these parameters default to 1.

`DE_JPC79()`

Specify McDonald's "JP Coates Thread Company" color difference formula.

`DE_CMC(kl::Float64, kc::Float64)`
`DE_CMC()`

Specify the color difference using the CMC equation, with weighting parameters `kl` and `kc`. When not provided, these parameters default to 1.

`DE_BFD(wp::XYZ, kl::Float64, kc::Float64)`
`DE_BFD(kl::Float64, kc::Float64)`
`DE_BFD()`

Specify the color difference using the BFD equation, with weighting parameters `kl` and `kc`. Additionally, a white point can be specified, because the BFD equation must convert between `XYZ` and `LAB` during the computation. When not specified, the constants default to 1, and the white point defaults to CIE D65.

`DE_AB()`

Specify the original, Euclidean color difference equation.

`DE_DIN99()`

Specify the Euclidean color difference equation applied in the `DIN99` uniform color space.

`DE_DIN99d()`

Specify the Euclidean color difference equation applied in the `DIN99` uniform color space.

`DE_DIN99o()`

Specify the Euclidean color difference equation applied in the `DIN99` uniform color space.

## Simulation of color deficiency ("color blindness")

```julia
protanopic(c::Color)
deuteranopic(c::Color)
tritanopic(c::Color)
```

Three functions are provided that map colors to a reduced gamut to simulate
different types of dichromacy, the loss one the three types of human
photopigments. Protanopia, deuteranopia, and tritanopia are the loss of long,
middle, and short wavelength photopigment, respectively.

These functions take a color and return a new, altered color is the same
colorspace .

```julia
protanopic(c::Color, p::Float64)
deuteranopic(c::Color, p::Float64)
tritanopic(c::Color, p::Float64)
```

Also provided are versions of these functions with an extra parameter `p` in
`[0,1]`, giving the degree of photopigment loss. Where 1.0 is a complete loss,
and 0.0 is no loss at all.


## Color Scales

#### `distinguishable_colors`

```julia
distinguishable_colors(n::Integer,seed::Color)
distinguishable_colors{T<:Color}(n::Integer,seed::AbstractVector{T})
```

Generate `n` maximally distinguishable colors in LCHab space.

A seed color or array of seed colors may be provided to `distinguishable_colors`, and the remaining colors will be chosen to be maximally distinguishable from the seed colors and each other.

```julia
distinguishable_colors{T<:Color}(n::Integer, seed::AbstractVector{T};
    transform::Function = identity,
    lchoices::AbstractVector = linspace(0, 100, 15),
    cchoices::AbstractVector = linspace(0, 100, 15),
    hchoices::AbstractVector = linspace(0, 340, 20)
)
```

By default, `distinguishable_colors` chooses maximally distinguishable colors from the outer product of lightness, chroma and hue values specified by `lchoices = linspace(0, 100, 15)`, `cchoices = linspace(0, 100, 15)`, and `hchoices = linspace(0, 340, 20)`. The set of colors that `distinguishable_colors` chooses from may be specified by passing different choices as keyword arguments.

Distinguishability is maximized with respect to the CIEDE2000 color difference formula (see `colordiff`). If a `transform` function is specified, color difference is instead maximized between colors `a` and `b` according to
`colordiff(transform(a), transform(b))`.

#### `linspace`

`linspace(c1::Color, c2::Color, n=100)`

Generates `n` colors in a linearly interpolated ramp from `c1` to
`c2`, inclusive, returning an `Array` of colors

#### `weighted_color_mean`

`weighted_color_mean(w1::Real, c1::Color, c2::Color)`

Returns a color that is the weighted mean of `c1` and `c2`, where `c1`
has a weight 0 ≤ `w1` ≤ 1.

#### `MSC`

`MSC(h)`

Returns the most saturated color for a given hue `h` (defined in LCHuv space, i.e. in range [0, 360]). Optionally the lightness `l` can also be given like `MSC(h, l)`. The color is found by finding the edge of the LCHuv space for a given angle (hue).

## Colormaps

`colormap(cname::String [, N::Int=100; mid=0.5, logscale=false, kvs...])`

Returns a predefined sequential or diverging colormap computed using the algorithm by Wijffelaars, M., et al. (2008).
Optional arguments are the number of colors `N`, position of the middle point `mid` and possibility to switch to log scaling with `logscale` keyword.

Colormaps computed by this algorithm are ensured to have an increasing perceived depth or saturation making them ideal for data visualization. This also means that they are (in most cases) colorblind friendly and suitable for black-and-white printing.

Currently supported colormap names are:

#### Sequential

| Name       | Example |
| ---------- | ------- |
| Blues | ![Blues](images/Blues.png "Blues") |
| Greens | ![Greens](images/Greens.png "Greens") |
| Grays |  |
| Oranges | ![Oranges](images/Oranges.png "Oranges") |
| Purples | ![Purples](images/Purples.png "Purples") |
| Reds | ![Reds](images/Reds.png "Reds") |

#### Diverging

| Name       | Example |
| ---------- | ------- |
| RdBu (from red to blue) | ![RdBu](images/RdBu.png "RdBu") |

It is also possible to create your own colormaps by using the
`sequential_palette(h, [N::Int=100; c=0.88, s=0.6, b=0.75, w=0.15, d=0.0, wcolor=RGB(1,1,0), dcolor=RGB(0,0,1), logscale=false])`

function that creates a sequential map for a hue `h` (defined in LCHuv space). Other possible parameters that you can fine-tune are:

* `N` - number of colors
* `c` - the overall lightness contrast [0,1]
* `s` - saturation [0,1]
* `b` - brightness [0,1]
* `w` - cold/warm parameter, i.e. the strength of the starting color [0,1]
* `d` - depth of the ending color [0,1]
* `wcolor` - starting color (usually defined to be yellow)
* `dcolor` - ending color (depth)
* `logscale` - true/false for toggling logspacing

Two sequential maps can also be combined into a diverging colormap by using the

`diverging_palette(h1, h2 [, N::Int=100; mid=0.5,c=0.88, s=0.6, b=0.75, w=0.15, d1=0.0, d2=0.0, wcolor=RGB(1,1,0), dcolor1=RGB(1,0,0), dcolor2=RGB(0,0,1), logscale=false])`

where the arguments are
* `h1` - the main hue of the left side [0,360]
* `h2` - the main hue of the right side [0,360]

and optional arguments
* `N` - number of colors
* `c` - the overall lightness contrast [0,1]
* `s` - saturation [0,1]
* `b` - brightness [0,1]
* `w` - cold/warm parameter, i.e. the strength of the middle color [0,1]
* `d1` - depth of the ending color in the left side [0,1]
* `d2` - depth of the ending color in the right side [0,1]
* `wcolor` - starting color i.e. the middle color (warmness, usually defined to be yellow)
* `dcolor1` - ending color of the left side (depth)
* `dcolor2` - ending color of the right side (depth)
* `logscale` - true/false for toggling logspacing



# References

What perceptually uniform colorspaces are and why you should be using them:

* Ihaka, R. (2003).
  [Colour for Presentation Graphics](http://www.stat.auckland.ac.nz/~ihaka/downloads/DSC-Color.pdf).
  In K Hornik, F Leisch, A Zeileis (eds.),
  Proceedings of the 3rd International Workshop on Distributed Statistical Computing,
  Vienna, Austria. ISSN 1609-395X
* Zeileis, A., Hornik, K., and Murrell, P. (2009).
  [Escaping RGBland: Selecting colors for statistical graphics](http://epub.wu.ac.at/1692/1/document.pdf).
  Computational Statistics and Data Analysis,
  53(9), 3259–3270. doi:10.1016/j.csda.2008.11.033

Functions in this library were mostly implemented according to:

* Schanda, J., ed.
  [Colorimetry: Understanding the CIE system](http://books.google.pt/books?id=uZadszSGe9MC).
  Wiley-Interscience, 2007.
* Sharma, G., Wu, W., and Dalal, E. N. (2005).
  [The CIEDE2000 color‐difference formula](http://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf):
  Implementation notes, supplementary test data, and mathematical observations.
  Color Research & Application, 30(1), 21–30. doi:10.1002/col
* Ihaka, R., Murrel, P., Hornik, K., Fisher, J. C., and Zeileis, A. (2013).
  [colorspace: Color Space Manipulation](http://CRAN.R-project.org/package=colorspace).
  R package version 1.2-1.
* Lindbloom, B. (2013).
  [Useful Color Equations](http://www.brucelindbloom.com/index.html?ColorCalculator.html)
* Wijffelaars, M., Vliegen, R., van Wijk, J., van der Linden, E-J. (2008). [Generating Color Palettes using Intuitive Parameters](http://magnaview.nl/documents/MagnaView-M_Wijffelaars-Generating_color_palettes_using_intuitive_parameters.pdf)
* Georg A. Klein
  [Industrial Color Physics](http://http://books.google.de/books?id=WsKOAVCrLnwC).
  Springer Series in Optical Sciences, 2010. ISSN 0342-4111, ISBN 978-1-4419-1197-1.

## Migrating from Color.jl

The following script can be helpful:

```sh
# Intended to be run from the top directory in a package
# Do not run this twice on the same source tree without discarding
# the first set of changes.
sed -i 's/\bColor\b/Colors/g' REQUIRE

fls=$(find . -name "*.jl")
sed -i 's/\bColor\b/Colors/g' $fls               # Color -> Colors
sed -i -r 's/\bcolor\("(.*?)"\)/colorant\"\1\"/g' $fls   # color("red") -> colorant"red"
sed -i 's/AbstractAlphaColorValue/TransparentColor/g' $fls
sed -i 's/AlphaColorValue/TransparentColor/g' $fls   # might mean ColorAlpha
sed -i 's/ColorValue/Color/g' $fls
sed -i 's/ColourValue/Color/g' $fls
sed -i -r 's/\bLAB\b/Lab/g' $fls
sed -i -r 's/\bLUV\b/Luv/g' $fls
sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.c\.(\w)\b/\1\.\2/g' $fls      # colval.c.r -> colval.c
# This next one is quite dangerous, esp. for LCHab types...
# ...on the other hand, git diff is nice about showing the things we should fix
sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.c\b/color(\1)/g' $fls

# These are not essential, but they generalize to RGB24 better
# However, they are too error-prone to use by default since other color
# types like Lab have fields with the same names
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.r\b/red(\1)/g' $fls          # c.r -> red(c)
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.g\b/green(\1)/g' $fls
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.b\b/blue(\1)/g' $fls
#sed -i -r 's/\b([a-zA-Z0-9_\.]+)\.alpha\b/alpha(\1)/g' $fls     # c.alpha -> alpha(c)
```

You are strongly advised to check the results carefully; for example,
any object `obj` with a field named `c` will get converted from
`obj.c` to `color(obj)`, and if `obj` is not a `Colorant` this is
surely not what you want.  You can use `git add -p` to review/edit
each change individually.
