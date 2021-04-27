function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    eltypes = (N0f8, N0f16, Float32, Float64)        # eltypes of parametric colors
    feltypes = (Float32, Float64)                    # floating-point eltypes
    pctypes = (Gray, RGB, AGray, GrayA, ARGB, RGBA)  # parametric colors
    cctypes = (Gray24, AGray32, RGB24, ARGB32)       # non-parametric colors
    # conversions
    ## to RGB
    for T in eltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,XYZ)
        precompile(Tuple{typeof(convert),Type{RGB{T}},C{F}})
    end
    ## to XYZ
    for T in feltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,XYZ,RGB)
        precompile(Tuple{typeof(convert),Type{XYZ{T}},C{F}})
    end
    for T in feltypes, F in (N0f8, N0f16)
        precompile(Tuple{typeof(convert),Type{XYZ{T}},RGB{F}})
    end
    # parse
    precompile(Tuple{typeof(parse),Type{ColorTypes.Colorant},String})
    precompile(Tuple{typeof(parse),Type{RGB{N0f8}},String})
    precompile(Tuple{typeof(parse),Type{RGBA{N0f8}},String})
    # colordiff
    for T in eltypes
        precompile(Tuple{typeof(colordiff),RGB{T},RGB{T}})
    end
    precompile(Tuple{typeof(colormap),String})
    precompile(Tuple{typeof(distinguishable_colors),Int})
end
