# Color Differences

The [`colordiff`](@ref) function gives an approximate value for the difference between two colors.

```jldoctest example; setup = :(using Colors)
julia> colordiff(colorant"red", colorant"darkred")
23.754149863643036

julia> colordiff(colorant"red", colorant"blue")
52.88136782250768

julia> colordiff(HSV(0, 0.75, 0.5), HSL(0, 0.75, 0.5))
19.485910662571335
```

```julia
    colordiff(a::Color, b::Color; metric=DE_2000())
```

Evaluate the [CIEDE2000](http://en.wikipedia.org/wiki/Color_difference#CIEDE2000) color difference formula by default. This gives an approximate measure of the perceptual difference between two colors to a typical viewer. A larger number is returned for increasingly distinguishable colors.

Options for `metric` are as follows:

| Metric             | Summary                                                                       |
|:-------------------|:------------------------------------------------------------------------------|
|[`DE_2000`](@ref)   | The color difference using the recommended CIE Delta E 2000 equation.         |
|[`DE_94`](@ref)     | The color difference using the recommended CIE Delta E 94 equation.           |
|[`DE_JPC79`](@ref)  | McDonald's "JP Coates Thread Company" color difference formula.               |
|[`DE_CMC`](@ref)    | The color difference using the CMC l:c equation.                              |
|[`DE_BFD`](@ref)    | The color difference using the BFD equation.                                  |
|[`DE_AB`](@ref)     | The original ΔE*, Euclidean color difference equation in the `Lab` colorspace.|
|[`DE_DIN99`](@ref)  | The Euclidean color difference equation applied in the `DIN99` colorspace.    |
|[`DE_DIN99d`](@ref) | The Euclidean color difference equation applied in the `DIN99d` colorspace.   |
|[`DE_DIN99o`](@ref) | The Euclidean color difference equation applied in the `DIN99o` colorspace.   |


The following charts show the differences between the three colors for each
metric with the default parameters:
```@example diff
using Colors # hide
using Main: ColorDiffCharts # hide
ColorDiffCharts.ColorDiffChartSVG(DE_2000()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_94()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_JPC79()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_CMC()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_BFD()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_AB()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_DIN99()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_DIN99d()) # hide
```
```@example diff
ColorDiffCharts.ColorDiffChartSVG(DE_DIN99o()) # hide
```
The difference in the size of circles in the charts above represents the
difference in the scale. The radii of the circles are all 20 in their scale
units, so larger circles mean that the metric returns smaller values. Therefore,
we should not compare the color differences between different metrics.

```@docs
colordiff
DE_2000()
DE_94()
DE_JPC79()
DE_CMC()
DE_BFD()
DE_AB()
DE_DIN99()
DE_DIN99d()
DE_DIN99o()
```
