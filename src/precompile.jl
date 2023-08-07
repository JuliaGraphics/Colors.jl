function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    eltypes = (N0f8, N0f16, Float32, Float64)        # eltypes of parametric colors
    feltypes = (Float32, Float64)                    # floating-point eltypes
    pctypes = (Gray, RGB, AGray, GrayA, ARGB, RGBA)  # parametric colors
    cctypes = (Gray24, AGray32, RGB24, ARGB32)       # non-parametric colors
    # conversions
    ## from/to XYZ
    for T in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,Oklab,Oklch)
        precompile(Tuple{typeof(convert),Type{C{T}},XYZ{T}})
        precompile(Tuple{typeof(convert),Type{XYZ{T}},C{T}})
    end
    for T in feltypes, F in eltypes
        precompile(Tuple{typeof(convert),Type{RGB{F}},XYZ{T}})
        precompile(Tuple{typeof(convert),Type{XYZ{T}},RGB{F}})
    end
    ## to RGB
    for T in eltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,Oklab,Oklch)
        precompile(Tuple{typeof(convert),Type{RGB{T}},C{F}})
    end
    # parse
    precompile(Tuple{typeof(parse),Type{ColorTypes.Colorant},String})
    precompile(Tuple{typeof(parse),Type{RGB{N0f8}},String})
    precompile(Tuple{typeof(parse),Type{RGBA{N0f8}},String})
    # colordiff
    for T in eltypes
        # Currently, there is a problem with `Float64` related to `cos`/`sin`.
        T === Float64 && continue
        precompile(Tuple{typeof(colordiff),RGB{T},RGB{T}})
    end
    precompile(Tuple{typeof(colormap),String})
    precompile(Tuple{typeof(colormap),String,Int})
    precompile(Tuple{typeof(distinguishable_colors),Int})
end
