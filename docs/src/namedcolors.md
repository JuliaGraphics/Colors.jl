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

```julia
julia> using Colors

julia> color = colorant"indianred"
RGB{N0f8}(0.804,0.361,0.361)
```

or

```julia
julia> cname = "indianred"
"indianred"

julia> color = parse(Colorant, cname)
RGB{N0f8}(0.804,0.361,0.361)
```

![Reds](assets/figures/namedcolorchart-reds.svg)

![Oranges](assets/figures/namedcolorchart-oranges.svg)

![Yellows](assets/figures/namedcolorchart-yellows.svg)

![Greens](assets/figures/namedcolorchart-greens.svg)

![Greens](assets/figures/namedcolorchart-cyans.svg)

![Blues](assets/figures/namedcolorchart-blues.svg)

![Purples](assets/figures/namedcolorchart-purples.svg)

![Browns](assets/figures/namedcolorchart-browns.svg)

![Pinks](assets/figures/namedcolorchart-pinks.svg)

![Whites](assets/figures/namedcolorchart-whites.svg)

![Grays](assets/figures/namedcolorchart-grays.svg)


These colors can be converted to `RGB{N0f32}` (for example) using:

```julia
julia> using FixedPointNumbers
julia> RGB{N0f32}(color)
RGB{N0f32}(0.803922,0.360784,0.360784)
```

