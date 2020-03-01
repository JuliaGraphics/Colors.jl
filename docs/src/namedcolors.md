# Named Colors

The names of available colors are stored in alphabetical order in the dictionary `Colors.color_names`:

```julia
color_names = Dict(
    "aliceblue"            => (240, 248, 255),
    "antiquewhite"         => (250, 235, 215),
    "antiquewhite1"        => (255, 239, 219),
    ...
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
