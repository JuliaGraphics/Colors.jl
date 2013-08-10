# Color

This library provides a wide array of functions for dealing with color. This
includes conversion between colorspaces, measuring distance between colors,
simulating color blindness, and generating color scales for graphics, among
other things.


## Colorspaces

What follows is a synopsis of every colorspace implemented in Color.jl. Any
color value can be converted to a similar value in any other colorspace using
the `convert` function.

E.g.
```julia
convert(RGB, HSL(270, 0.5, 0.5))
```

Depending on the source and destination colorspace, this may not be perfectly
lossless.

### RGB

The sRGB colorspace.

```julia
immutable RGB <: ColorValue
    r::Float64 # Red in [0,1]
    g::Float64 # Green in [0,1]
    b::Float64 # Blue in [0,1]
end
```

### HSV

Hue-Saturation-Value. A common projection of RGB to cylindrical coordinates.
This is also sometimes called "HSB" for Hue-Saturation-Brightness.

```julia
immutable HSV <: ColorValue
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    v::Float64 # Value in [0,1]
end
```

### HSL

Hue-Saturation-Lightness. Another common projection of RGB to cylindrical
coordinates.

```julia
immutable HSL <: ColorValue
    h::Float64 # Hue in [0,360]
    s::Float64 # Saturation in [0,1]
    l::Float64 # Lightness in [0,1]
end
```

### XYZ

The XYZ colorspace standardized by the CIE in 1931, based on experimental
measurements of color perception culminating in the CIE standard observer (see
`cie_color_match`)

```julia
immutable XYZ <: ColorValue
    x::Float64
    y::Float64
    z::Float64
end
```

### LAB

A percuptually uniform colorpsace standardized by the CIE in 1976. See also LUV,
a similar colorspace standardized the same year.

```julia
immutable LAB <: ColorValue
    l::Float64 # Luminance in approximately [0,100]
    a::Float64 # Red/Green
    b::Float64 # Blue/Yellow
end
```

### LUV

A percuptually uniform colorpsace standardized by the CIE in 1976. See also LAB,
a similar colorspace standardized the same year.

```julia
immutable LUV <: ColorValue
    l::Float64 # Luminance
    u::Float64 # Red/Green
    v::Float64 # Blue/Yellow
end
```


### LCHab

The LAB colorspace reparameterized using cylindrical coordinates.

```julia
immutable LCHab <: ColorValue
    l::Float64 # Luminance in [0,100]
    c::Float64 # Chroma
    h::Float64 # Hue in [0,360]
end
```


### LCHuv

The LUV colorspace reparameterized using cylindrical coordinates.

```julia
immutable LCHuv <: ColorValue
    l::Float64 # Luminance
    c::Float64 # Chroma
    h::Float64 # Hue
```

### LMS

Long-Medium-Short cone response values. Multiple methods of converting to LMS
space have been defined. Here the [CAT02](https://en.wikipedia.org/wiki/CIECAM02#CAT02) chromatic adaptation matrix is used.

```
immutable LMS <: ColorValue
    l::Float64 # Long
    m::Float64 # Medium
    s::Float64 # Short
end
```

### RGB24

An RGB color represented as 8-bit values packed into a 32-bit integer.

```julia
immutable RGB24 <: ColorValue
    color::Uint32
end
```

## Color Parsing

`color(desc::String)`

Parse a [CSS color
specification](https://developer.mozilla.org/en-US/docs/CSS/color). It will
parse any CSS color syntax with the exception of `transparent`, `rgba()`,
`hsla()` (since this library has no notion of transparency), and `currentColor`.

All CSS/SVG named colors are supported, in addition to X11 named colors, when
their definitions do not clash with SVG.

A `RGB` color is returned, except when the `hsl()` syntax is used, which returns
a `HSL` value.

## CIE Standard Observer

`cie_color_match(wavelen::Real)`

The CIE defines a standard observer, defining typical frequency response curve
for each of the three human cones. This function returns an XYZ color
corresponding to a wavelength specified in nanometers.  

## Chromatic Adaptation (white balance)

`whitebalance{T <: ColorValue}(c::T, src_white::ColorValue, ref_white::ColorValue)`

Convert a color `c` viewed under conditions with a given source whitepoint
`src_whitepoint`, to appear the same under a different conditions specified by a
reference whitepoint `ref_white`.

## Color Difference

`colordiff(a::ColorValue, b::ColorValue)`

Evaluate the
[CIEDE2000](http://en.wikipedia.org/wiki/Color_difference#CIEDE2000) color
difference formula. This gives an approximate measure of the perceptual
difference between two colors to a typical viewer. A large number is returned
for increasingly distinguishable colors.

## Simulation of color blindness

```julia
protanopic(c::ColorValue)
deuteranopic(c::ColorValue)
tritanopic(c::ColorValue)
```

Three functions are provided that map colors to a reduced gamut to simulate
different types of dichromacy, the loss one the three types of human
photopigments. Protanopia, deuteranopia, and tritanopia are the loss of long,
middle, and short wavelength photopigment, respectively.

These functions take a color and return a new, altered color is the same
colorspace .

```julia
protanopic(c::ColorValue, p::Float64)
deuteranopic(c::ColorValue, p::Float64)
tritanopic(c::ColorValue, p::Float64)
```

Also provided are versions of these functions with an extra parameter `p` in
`[0,1]`, giving the degree of photopigment loss. Where 1.0 is a complete loss,
and 0.0 is no loss at all.


## Color Scales

`distinguishable_colors(n::Integer, transform::Function, seed::ColorValue, ls::Vector{Float64}, cs::Vector{Float64}, hs::Vector{Float64})`

Generate `n` maximally distinguishable colors in LCHab space.

The algorithm builds up the palette starting from a color `seed`, and choosing
the other n-1 over the Cartesian product of provided possible lightness
(`ls`), chroma (`cs`), and hue (`hs`) values.

Distinguishability is maximized with respect to the CIEDE2000 color difference
formula (see `colordiff`), after first applying a transformation function
(`transform`). I.e. the difference between two colors `a` and `b` is computed as
`colordiff(transform(a), transform(b))`.


`linspace(c1::ColorValue, c2::ColorValue, n=100)`

Generates `n` colors in a linearly interpolated ramp from `c1` to
`c2`, inclusive, returning an `Array` of colors

`weighted_color_mean(w1::Real, c1::ColorValue, c2::ColorValue)`

Returns a color that is the weighted mean of `c1` and `c2`, where `c1`
has a weight 0 ≤ `w1` ≤ 1.

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
