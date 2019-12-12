function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    eltypes = (N0f8, N0f16, Float32, Float64)        # eltypes of parametric colors
    feltypes = (Float32, Float64)                    # floating-point eltypes
    pctypes = (Gray, RGB, AGray, GrayA, ARGB, RGBA)  # parametric colors
    cctypes = (Gray24, AGray32, RGB24, ARGB32)       # non-parametric colors
    # conversions
    ## to RGB
    for T in eltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,XYZ)
        @assert precompile(Tuple{typeof(convert),Type{RGB{T}},C{F}})
    end
    ## to XYZ
    for T in feltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,XYZ,RGB)
        @assert precompile(Tuple{typeof(convert),Type{XYZ{T}},C{F}})
    end
    for T in feltypes, F in (N0f8, N0f16)
        @assert  precompile(Tuple{typeof(convert),Type{XYZ{T}},RGB{F}})
    end
    # parse
    @assert precompile(Tuple{typeof(parse),Type{ColorTypes.Colorant},String})
    @assert precompile(Tuple{typeof(parse),Type{RGB{N0f8}},String})
    @assert precompile(Tuple{typeof(parse),Type{RGBA{N0f8}},String})
    # colordiff
    for T in eltypes
        @assert precompile(Tuple{typeof(colordiff),RGB{T},RGB{T}})
    end
    @assert precompile(Tuple{typeof(colormap),String})
    @assert precompile(Tuple{typeof(distinguishable_colors),Int})
end
