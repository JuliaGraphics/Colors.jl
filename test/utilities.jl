using Colors, FixedPointNumbers, Test, InteractiveUtils

const test_matf = Float64[1 -2 1;-1 3 -2;-3 4 3]
const test_matb = inv(test_matf)

@testset "Utilities" begin
    # test macros

    vecxyz = XYZ{Float64}(0.125, 0.25, 0.5)
    veclms = LMS{Float64}(0.125, -0.375, 2.125)
    @test (Colors.@mul3x3 LMS{Float64} test_matf vecxyz.x vecxyz.y vecxyz.z) ≈ veclms
    @test (Colors.@mul3x3xyz LMS{Float64} test_matf vecxyz) ≈ veclms
    @test (Colors.@mul3x3lms XYZ{Float64} test_matb veclms) ≈ vecxyz

    if false # benchmark
        getmatf() = test_matf
        getmatb() = test_matb
        function with_macro(::Type{T}, n) where{T}
            x = XYZ{T}(vecxyz)
            xyz2lms(c::XYZ{T}) where{T} = (Colors.@mul3x3xyz LMS{T} getmatf() c)
            lms2xyz(c::LMS{T}) where{T} = (Colors.@mul3x3lms XYZ{T} getmatb() c)
            for i = 1:n; l = xyz2lms(x); x = lms2xyz(l) end
            @show x
        end
        function without_macro(::Type{T}, n) where{T}
            x = XYZ{T}(vecxyz)
            xyz2lms(c::XYZ{T}) where{T} = (v=getmatf()*[c.x,c.y,c.z];LMS{T}(v[1],v[2],v[3]))
            lms2xyz(c::LMS{T}) where{T} = (v=getmatb()*[c.l,c.m,c.s];XYZ{T}(v[1],v[2],v[3]))
            for i = 1:n; l = xyz2lms(x); x = lms2xyz(l) end
            @show x
        end
        @time with_macro(Float64, 1)
        @time without_macro(Float64, 1)
        @time with_macro(Float64, 100000)
        @time without_macro(Float64, 100000)
    end

    # test utility function weighted_color_mean
    parametric2 = [GrayA,AGray32,AGray]
    parametric3 = ColorTypes.parametric3
    parametric4A = setdiff(subtypes(ColorAlpha),[GrayA])
    parametricA4 = setdiff(subtypes(AlphaColor),[AGray32,AGray])
    colortypes = vcat(parametric3,parametric4A,parametricA4)
    colorElementTypes = [Float16,Float32,Float64,BigFloat,N0f8,N6f10,N4f12,N2f14,N0f16]

    for T in colorElementTypes
        c1 = Gray{T}(1)
        c2 = Gray{T}(0)
        @test weighted_color_mean(0.5,c1,c2) == Gray{T}(0.5)
    end

    for C in parametric2
        for T in colorElementTypes
            C == AGray32 && (T=N0f8)
        c1 = C(T(0),T(1))
            c2 = C(T(1),T(0))
        @test weighted_color_mean(0.5,c1,c2) == C(T(1)-T(0.5),T(0.5))
        end
    end

    for C in colortypes
        for T in (Float16,Float32,Float64,BigFloat)
        if C<:Color
                c1 = C(T(1),T(1),T(0))
                c2 = C(T(0),T(1),T(1))
            @test weighted_color_mean(0.5,c1,c2) == C(T(0.5),T(0.5)+T(1)-T(0.5),T(1)-T(0.5))
        else
                C == ARGB32 && (T=N0f8)
                c1 = C(T(1),T(1),T(0),T(1))
                c2 = C(T(0),T(1),T(1),T(0))
            @test weighted_color_mean(0.5,c1,c2) == C(T(0.5),T(0.5)+T(1)-T(0.5),T(1)-T(0.5),T(0.5))
        end
        end
    end

    # test utility function range
    # range uses weighted_color_mean which is extensively tested.
    # Therefore it suffices to test the function using gray colors.
    for T in colorElementTypes
        c1 = Gray(T(1))
        c2 = Gray(T(0))
        linc1c2 = range(c1,stop=c2,length=43)
        @test length(linc1c2) == 43
        @test linc1c2[1] == c1
        @test linc1c2[end] == c2
        @test linc1c2[22] == Gray(T(0.5))
        @test typeof(linc1c2) == Array{Gray{T},1}
        if VERSION >= v"1.1"
            @test range(c1,c2,length=43) == range(c1,stop=c2,length=43)
        end
    end
end
