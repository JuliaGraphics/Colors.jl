using SnoopPrecompile

@precompile_setup begin
    eltypes = (N0f8, N0f16, Float32, Float64)        # eltypes of parametric colors
    feltypes = (Float32, Float64)                    # floating-point eltypes
    pctypes = (Gray, RGB, AGray, GrayA, ARGB, RGBA)  # parametric colors
    cctypes = (Gray24, AGray32, RGB24, ARGB32)       # non-parametric colors
    @precompile_all_calls begin
        # conversions
        ## from/to XYZ
        for T in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv)
            convert(C{T}, zero(XYZ{T}))
            convert(XYZ{T}, zero(C{T}))
        end
        for T in feltypes, F in eltypes
            convert(RGB{F}, zero(XYZ{T}))
            convert(XYZ{T}, zero(RGB{F}))
        end
        ## to RGB
        for T in eltypes, F in feltypes, C in (HSV,LCHab,LCHuv,Lab,Luv)
            convert(RGB{T}, zero(C{F}))
        end
        # parse
        for str in ("red", "#D0FF58")
            parse(ColorTypes.Colorant, str)
            parse(RGB{N0f8}, str)
            parse(RGBA{N0f8}, str)
        end
        # colordiff
        for T in eltypes
            # Currently, there is a problem with `Float64` related to `cos`/`sin`.
            T === Float64 && continue
            colordiff(zero(RGB{T}), zero(RGB{T}))
        end
        colormap("Blues")
        colormap("Blues", 10; logscale=true)
        distinguishable_colors(5)
    end
end
