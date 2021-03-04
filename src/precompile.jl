macro warnpcfail(ex::Expr)
    modl = __module__
    file = __source__.file === nothing ? "?" : String(__source__.file)
    line = __source__.line
    quote
        $(esc(ex)) || @warn """precompile directive
     $($(Expr(:quote, ex)))
 failed. Please report an issue in $($modl) (after checking for duplicates) or remove this directive.""" _file=$file _line=$line
    end
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    eltypes = (N0f8, N0f16, Float32, Float64)        # eltypes of parametric colors
    feltypes = (Float32, Float64)                    # floating-point eltypes
    pctypes = (Gray, RGB, AGray, GrayA, ARGB, RGBA)  # parametric colors
    cctypes = (Gray24, AGray32, RGB24, ARGB32)       # non-parametric colors
    # conversions
    ## to RGB
    for T in eltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,XYZ)
        @warnpcfail precompile(Tuple{typeof(convert),Type{RGB{T}},C{F}})
    end
    ## to XYZ
    for T in feltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv,XYZ,RGB)
        @warnpcfail precompile(Tuple{typeof(convert),Type{XYZ{T}},C{F}})
    end
    for T in feltypes, F in (N0f8, N0f16)
        @warnpcfail  precompile(Tuple{typeof(convert),Type{XYZ{T}},RGB{F}})
    end
    # parse
    @warnpcfail precompile(Tuple{typeof(parse),Type{ColorTypes.Colorant},String})
    @warnpcfail precompile(Tuple{typeof(parse),Type{RGB{N0f8}},String})
    @warnpcfail precompile(Tuple{typeof(parse),Type{RGBA{N0f8}},String})
    # colordiff
    for T in eltypes
        @warnpcfail precompile(Tuple{typeof(colordiff),RGB{T},RGB{T}})
    end
    @warnpcfail precompile(Tuple{typeof(colormap),String})
    @warnpcfail precompile(Tuple{typeof(distinguishable_colors),Int})
end
