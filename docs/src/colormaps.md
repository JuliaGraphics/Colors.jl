# Colormaps

This package provides some pre-defined colormaps (described below). There are also several other packages which provide colormaps:

- [PerceptualColourMaps](https://github.com/peterkovesi/PerceptualColourMaps.jl)
- [ColorBrewer](https://github.com/timothyrenner/ColorBrewer.jl)
- [ColorSchemes.jl](https://github.com/JuliaGraphics/ColorSchemes.jl)
- [NoveltyColors](https://github.com/randyzwitch/NoveltyColors.jl)

## Predefined sequential and diverging colormaps

`colormap(cname::String [, N::Int=100; mid=0.5, logscale=false, kvs...])`

Returns a predefined sequential or diverging colormap computed using the algorithm by Wijffelaars, M., et al. (2008).

The optional arguments are:

- the number of colors `N`
- position of the middle point `mid`
- the use of logarithmic scaling with the `logscale` keyword

Colormaps computed by this algorithm are guaranteed to have an increasing perceived depth or saturation making them ideal for data visualization. This also means that they are (in most cases) color-blind friendly and suitable for black-and-white printing.

The currently supported colormap names are:

### Sequential

| Name       | Example                                       |
| ---------- | -------                                       |
| Blues      | ![Blues](assets/figures/Blues.png)            |
| Greens     | ![Greens](assets/figures/Greens.png)          |
| Grays      |                                               |
| Oranges    | ![Oranges](assets/figures/Oranges.png)        |
| Purples    | ![Purples](assets/figures/Purples.png)        |
| Reds       | ![Reds](assets/figures/Reds.png)              |

### Diverging

| Name       | Example                                       |
| ---------- | -------                                       |
| RdBu (from red to blue) | ![RdBu](assets/figures/RdBu.png)  |

```@docs
colormap
```

## Sequential and diverging color palettes

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
