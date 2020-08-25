# Colormaps and Colorscales

## Color interpolation

### Generating a range of colors

The [`range()`](@ref) function has a method that accepts colors:

```julia
    Base.range(start::T; stop::T, length=100) where T<:Colorant
```

This generates N (=`length`) colors in a linearly interpolated ramp from `start`
to `stop`, inclusive, returning an `Array` of colors.

```jldoctest example
julia> using Colors

julia> c1 = colorant"red"
RGB{N0f8}(1.0,0.0,0.0)

julia> c2 = colorant"green"
RGB{N0f8}(0.0,0.502,0.0)

julia> range(c1, stop=c2, length=15)
15-element Array{RGB{N0f8},1} with eltype RGB{FixedPointNumbers.N0f8}:
 RGB{N0f8}(1.0,0.0,0.0)
 RGB{N0f8}(0.929,0.035,0.0)
 RGB{N0f8}(0.859,0.071,0.0)
 RGB{N0f8}(0.784,0.106,0.0)
 RGB{N0f8}(0.714,0.145,0.0)
 RGB{N0f8}(0.643,0.18,0.0)
 RGB{N0f8}(0.573,0.216,0.0)
 RGB{N0f8}(0.502,0.251,0.0)
 RGB{N0f8}(0.427,0.286,0.0)
 RGB{N0f8}(0.357,0.322,0.0)
 RGB{N0f8}(0.286,0.357,0.0)
 RGB{N0f8}(0.216,0.396,0.0)
 RGB{N0f8}(0.141,0.431,0.0)
 RGB{N0f8}(0.071,0.467,0.0)
 RGB{N0f8}(0.0,0.502,0.0)
```
If you use Julia through Juno or IJulia, you can get the following color swatches.
```@example range
using Colors # hide
showable(::MIME"text/plain", ::AbstractVector{C}) where {C<:Colorant} = false # hide
range(colorant"red", stop=colorant"green", length=15)
```
The intermediate colors depend on their colorspace. For example:
```@example range
range(HSL(colorant"red"), stop=HSL(colorant"green"), length=15)
```
The [`range`](@ref) and [`weighted_color_mean`](@ref) described below support
colors with hues which are out of the range [0, 360]. The hues of generated
colors are normalized into [0, 360].
```@example range
range(HSV(0,1,1), stop=HSV(-360,1,1), length=90) # inverse rotation
```
```@example range
range(LCHab(70,70,0), stop=LCHab(70,70,720), length=90) # multiple rotations
```
While sometimes useful in particular circumstances, typically it is recommended
that the hue be within [0, 360]. See [`normalize_hue`](@ref).

```@docs
Base.range
```
### Weighted color means

The [`weighted_color_mean()`](@ref) function returns a color that is the weighted mean of `c1` and `c2`, where `c1` has a weight 0 ≤ `w1` ≤ 1.

For example:

```jldoctest example
julia> weighted_color_mean(0.5, colorant"red", colorant"green")
RGB{N0f8}(0.502,0.251,0.0)
```

```@docs
weighted_color_mean
```

## Colormaps

This package provides some pre-defined colormaps (described below). There are also several other packages which provide colormaps:

- [PerceptualColourMaps](https://github.com/peterkovesi/PerceptualColourMaps.jl)
- [ColorBrewer](https://github.com/timothyrenner/ColorBrewer.jl)
- [ColorSchemes.jl](https://github.com/JuliaGraphics/ColorSchemes.jl)
- [NoveltyColors](https://github.com/randyzwitch/NoveltyColors.jl)


### Predefined sequential and diverging colormaps

The `colormap()` function returns a predefined sequential or diverging colormap computed using the algorithm by Wijffelaars, M., et al. (2008).

`colormap(cname::String [, N::Int=100; mid=0.5, logscale=false, kvs...])`

The optional arguments are:

- the number of colors `N`
- position of the middle point `mid`
- the use of logarithmic scaling with the `logscale` keyword

Colormaps computed by this algorithm are guaranteed to have an increasing perceived depth or saturation making them ideal for data visualization. This also means that they are (in most cases) color-blind friendly and suitable for black-and-white printing.

The currently supported colormap names are:

#### Sequential

- "Blues"
```@example colormap
using Colors # hide
using Main: Colormaps # hide
Colormaps.ColormapSVG(colormap("Blues", 32)) # hide
```

- "Greens"
```@example colormap
Colormaps.ColormapSVG(colormap("Greens", 32)) # hide
```

- "Grays"
```@example colormap
Colormaps.ColormapSVG(colormap("Grays", 32)) # hide
```

- "Oranges"
```@example colormap
Colormaps.ColormapSVG(colormap("Oranges", 32)) # hide
```

- "Purples"
```@example colormap
Colormaps.ColormapSVG(colormap("Purples", 32)) # hide
```

- "Reds"
```@example colormap
Colormaps.ColormapSVG(colormap("Reds", 32)) # hide
```

#### Diverging

- "RdBu" (from red to blue)
```@example colormap
Colormaps.ColormapSVG(colormap("RdBu", 32)) # hide
```

###

```@docs
colormap
```

### Sequential and diverging color palettes

You can create your own color palettes by using `sequential_palette()`:

`sequential_palette(h, [N::Int=100; c=0.88, s=0.6, b=0.75, w=0.15, d=0.0, wcolor=RGB(1,1,0), dcolor=RGB(0,0,1), logscale=false])`

which creates a sequential map for a hue `h` (defined in LCHuv space).

Other possible parameters that you can fine tune are:

* `N` - number of colors
* `c` - the overall lightness contrast [0,1]
* `s` - saturation [0,1]
* `b` - brightness [0,1]
* `w` - cold/warm parameter, i.e. the strength of the starting color [0,1]
* `d` - depth of the ending color [0,1]
* `wcolor` - starting color (usually defined to be yellow)
* `dcolor` - ending color (depth)
* `logscale` - true/false for toggling logspacing

Two sequential maps can also be combined into a diverging colormap by using:

`diverging_palette(h1, h2 [, N::Int=100; mid=0.5,c=0.88, s=0.6, b=0.75, w=0.15, d1=0.0, d2=0.0, wcolor=RGB(1,1,0), dcolor1=RGB(1,0,0), dcolor2=RGB(0,0,1), logscale=false])`

where the arguments are:

* `h1` - the main hue of the left side [0,360]
* `h2` - the main hue of the right side [0,360]

and the optional arguments are:

* `N` - number of colors
* `c` - the overall lightness contrast [0,1]
* `s` - saturation [0,1]
* `b` - brightness [0,1]
* `w` - cold/warm parameter, i.e. the strength of the middle color [0,1]
* `d1` - depth of the end color in the left side [0,1]
* `d2` - depth of the end color in the right side [0,1]
* `wcolor` - starting color i.e. the middle color (warmness, usually defined to be yellow)
* `dcolor1` - end color of the left side (depth)
* `dcolor2` - end color of the right side (depth)
* `logscale` - true/false for toggling logspacing

```@docs
sequential_palette
diverging_palette
```

## Generating distinguishable colors

`distinguishable_colors()` generates `n` maximally distinguishable colors in LCHab space. A seed color or array of seed colors can be provided, and the remaining colors will be chosen to be maximally distinguishable from the seed colors and each other.

```julia
distinguishable_colors(n::Integer, seed::Color)
distinguishable_colors{T<:Color}(n::Integer,seed::AbstractVector{T})
```

By default, `distinguishable_colors` chooses maximally distinguishable colors from the outer product of lightness, chroma, and hue values specified by `lchoices = range(0, stop=100, length=15)`, `cchoices = range(0, stop=100, length=15)`, and `hchoices = range(0, stop=342, length=20)`. The set of colors that `distinguishable_colors` chooses from can be specified by passing different choices as keyword arguments.

```julia
distinguishable_colors{T<:Color}(n::Integer, seed::AbstractVector{T};
    dropseed = false,
    transform::Function = identity,
    lchoices::AbstractVector = range(0, stop=100, length=15),
    cchoices::AbstractVector = range(0, stop=100, length=15),
    hchoices::AbstractVector = range(0, stop=342, length=20)
)
```

Distinguishability is maximized with respect to the CIEDE2000 color difference formula (see `colordiff` in [Color Differences](@ref)). If a `transform` function is specified, color difference is instead maximized between colors `a` and `b` according to `colordiff(transform(a), transform(b))`.

Color arrays generated by `distinguishable_colors` are particularly useful for improving the readability of multiple trace plots.
Here’s an example using [`PyPlot`](https://github.com/JuliaPy/PyPlot.jl):

```julia
using PyPlot, Colors
vars = 1:10
cols = distinguishable_colors(length(vars), [RGB(1,1,1), RGB(0,0,0)], dropseed=true)
pcols = map(col -> (red(col), green(col), blue(col)), cols)
xs = 0:12
for i in vars
    plot(xs, map(x -> rand() + 0.1x - 0.5i, xs), c = pcols[i])
end
legend(vars, loc="upper right", bbox_to_anchor=[1.1, 1.])
```
```@setup pyplot
using Colors
cols = distinguishable_colors(10, [RGB(1,1,1), RGB(0,0,0)], dropseed=true) # see above
src_cols = ["c721dd", "d14a00", "008c00", "007fb1", "d1ac00",
            "870036", "ff8fa1", "00008b", "2eff71", "675200"]
patterns = Dict(zip(src_cols, hex.(cols, :rrggbb)))
path = joinpath("assets", "figures")
open(joinpath(path, "pyplot-seed-dcols.svg"), "w") do out
    for line in eachline(joinpath(path, "pyplot-seed-dcols-src.svg"))
        m = match(r"^(.+stroke:#)(.{6})(.+)$", line)
        if m === nothing || !(m.captures[2] in src_cols)
            println(out, line)
        else
            println(out, m.captures[1], patterns[m.captures[2]], m.captures[3])
        end
    end
end
```
![pyplot seed ex](assets/figures/pyplot-seed-dcols.svg)

To ensure that the generated colors stand out against the default white
background and black texts, `white` and `black`
(`[RGB(1,1,1), RGB(0,0,0)]`) were used as seed colors to `distinguishable_colors()`,
then dropped from the resulting array with `dropseed=true`.

The `distinguishable_colors` returns a vector of length `n` regardless of the
`dropseed` option. If `dropseed` is `true`, the leading seed colors will be
dropped, and the succeeding values ​​of `length(seed)` will be appended to the
end.
```@example dropseed;
using Colors #hide
showable(::MIME"text/plain", ::AbstractMatrix{C}) where {C<:Colorant} = false # hide

permutedims(hcat(
    distinguishable_colors(10, [RGB(1,1,1), RGB(0,0,0)], dropseed=false),
    distinguishable_colors(10, [RGB(1,1,1), RGB(0,0,0)], dropseed=true),
    distinguishable_colors(12, [RGB(1,1,1), RGB(0,0,0)])[3:end] # manually drop the seed colors
))
```
!!! compat "Colors v0.10"
    `dropseed` requires at least Colors v0.10. If you use an older version, drop
    the seed manually.

```@docs
distinguishable_colors
```
