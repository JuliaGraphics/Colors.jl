# Named colors

The names of available colors are stored in alphabetical order in the dictionary `Colors.color_names`:

```julia
color_names = Dict(
    "aliceblue"            => (240, 248, 255),
    "antiquewhite"         => (250, 235, 215),
    "antiquewhite1"        => (255, 239, 219),
    ...
```

Named colors are available as `RGB{N0f8}` using:

```jldoctest example
julia> using Colors

julia> color = colorant"indianred"
RGB{N0f8}(0.804,0.361,0.361)
```

or

```jldoctest example
julia> cname = "indianred"
"indianred"

julia> color = parse(Colorant, cname)
RGB{N0f8}(0.804,0.361,0.361)
```

or

```jldoctest example
julia> color = parse(RGB, cname)
RGB{N0f8}(0.804,0.361,0.361)
```

```@example chart
using Main: NamedColorCharts # hide
NamedColorCharts.ColorChartSVG("whites") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("reds") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("oranges") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("yellows") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("greens") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("cyans") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("blues") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("purples") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("pinks") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("browns") # hide
```

```@example chart
NamedColorCharts.ColorChartSVG("grays") # hide
```

!!! info
    Colors.jl supports the CSS/SVG named colors and the X11 named colors. The
    CSS/SVG named colors come from the 16 colors defined in HTML3.2 and the X11
    named colors. There are some unnatural definitions due to the different
    origins. For example, "LightGray" is lighter than "Gray", but "DarkGray" is
    also lighter than "Gray".


These colors can be converted to `RGB{N0f32}` (for example) using:

```jldoctest example
julia> using FixedPointNumbers

julia> RGB{N0f32}(color)
RGB{N0f32}(0.803922,0.360784,0.360784)
```

or

```jldoctest example
julia> parse(RGB{N0f32}, cname)
RGB{N0f32}(0.803922,0.360784,0.360784)
```
