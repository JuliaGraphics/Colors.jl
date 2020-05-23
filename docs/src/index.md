# Introduction

This package provides a wide array of functions for dealing with color.

[Available colorspaces](@ref) include:

- `RGB`, `BGR`, `XRGB`, `RGBX`, `RGB24`
- `HSV`, `HSL`, `HSI`
- `XYZ`, `xyY`, `LMS`
- `Lab`, `Luv`, `LCHab`, `LCHuv`
- `DIN99`, `DIN99d`, `DIN99o`
- `YIQ`, `YCbCr`
- `Gray`, `Gray24`
- and their transparent variants: `ARGB`, `RGBA`, `ARGB32`, `AHSV`, `HSVA`, and so on

## Package Features

- [Color Parsing](@ref)
- [Color Conversions](@ref)
- [Color Differences](@ref)
- [Colormaps and Colorscales](@ref)
- [Simulation of color deficiency](@ref color_deficiency)


## Installation

The package can be installed with the Julia package manager. From the Julia
REPL, type `]` to enter the Pkg REPL mode and run:
```julia
pkg> add Colors
```

## Reexport

Note that Colors is used within other packages (e.g. [Images](https://github.com/JuliaImages/Images.jl))
and may have been [reexport](https://github.com/simonster/Reexport.jl)ed by them.
In addition, the color types used by Colors are defined in [ColorTypes](https://github.com/JuliaGraphics/ColorTypes.jl)
package. Colors reexports the types and functions exported by ColorTypes.
For example, that means:
```julia
julia> using Images; # instead `using Colors`

julia> RGB # You can use the types and functions (re-)exported by Colors.
RGB

julia> RGB === Images.RGB === Colors.RGB === ColorTypes.RGB
true
```
