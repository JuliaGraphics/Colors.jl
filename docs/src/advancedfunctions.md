# Advanced Functions


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

```julia
whitebalance(c::Color, src_white::Color, ref_white::Color)
```

Convert a color `c` viewed under conditions with a given source whitepoint `src_white` to appear the same under different conditions specified by a reference whitepoint `ref_white`.

For example, suppose you take a picture under a fluorescent light of the following color (about 4000 K).
```@example whitebalance
using Colors #hide
Colors.WP_F2 #hide
```
The following picture on the left shows it. However, if you stay under the fluorescent light for a long time, the color of the table may look more whitish than the picture.
So, to get more perceptual colors, i.e. the colors seen in sunlight, you can use `whitebalance(c, Color.WP_F2, Color.WP_D65)`.
The picture on the right shows the result of whitebalancing.
```@example whitebalance
using Main: SampleImages # hide
wb_f2(c) = whitebalance(c, Colors.WP_D65, Colors.WP_F2) # hide
SampleImages.BeadsImageSVG("Original", filter=wb_f2) # hide
```
```@example whitebalance
wb(c) = whitebalance(wb_f2(c), Colors.WP_F2, Colors.WP_D65) # hide
SampleImages.BeadsImageSVG("D65 (whitebalanced)", filter=wb) # hide
```
Note that both of the above two photos are represented in the sRGB color space with the D65 whitepoint. If you assign a color profile with the F2 whitepoint to the photo on the left, and your display device (browser) supports color management, they would be displayed in similar colors.

```@docs
whitebalance
```


## [Simulation of color deficiency ("color blindness")](@id color_deficiency)

Three functions are provided that map colors to a reduced gamut to simulate different types of *dichromacy*, the loss of one of the three types of human photopigments.

*Protanopia*, *deuteranopia*, and *tritanopia* are the loss of long, middle, and short wavelength photopigment, respectively.

These functions take a color and return a new, altered color in the same colorspace.

```julia
protanopic(c::Color, p::Float64)
deuteranopic(c::Color, p::Float64)
tritanopic(c::Color, p::Float64)
```

Also provided are versions of these functions with an extra parameter `p` in `[0, 1]`, giving the degree of photopigment loss, where `1.0` is a complete loss, and `0.0` is no loss at all. The partial loss simulates the anomalous trichromacy, i.e. *protanomaly*, *deuteranomaly* and *tritanomaly*.

```@example deficiency
using Colors #hide
using Main: SampleImages # hide
SampleImages.BeadsImageSVG("Normal") # hide
```
```@example deficiency
SampleImages.BeadsImageSVG("Protanomaly (p=0.7)", filter=(c->protanopic(c, 0.7))) # hide
```
```@example deficiency
SampleImages.BeadsImageSVG("Deuteranomaly (p=0.7)", filter=(c->deuteranopic(c, 0.7))) # hide
```
```@example deficiency
SampleImages.BeadsImageSVG("Tritanomaly (p=0.7)", filter=(c->tritanopic(c, 0.7))) # hide
```

```@docs
protanopic
deuteranopic
tritanopic
```

## Most saturated color

The `MSC(h)` function returns the most saturated color for a given hue `h` (defined in LCHuv space, i.e. in range [0, 360]). Optionally the lightness `l` can also be given, as `MSC(h, l)`. The function calculates the color by finding the edge of the LCHuv space for a given angle (hue).

```@docs
MSC
```
