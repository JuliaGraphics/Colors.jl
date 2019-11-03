using Test, Colors

@testset "Algorithms" begin
    # Test vector space operations
    @test LMS{Float64}(0.125,0.5,0.0)+LMS{Float64}(0.2,0.7,0.4) ≈ LMS{Float64}(0.325,1.2,0.4) atol=91eps()
    @test 3LMS{Float64}(0.125,0.5,0.03) ≈ LMS{Float64}(0.375,1.5,0.09) atol=91eps()

    @test XYZ{Float64}(0.125,0.5,0.0)+XYZ{Float64}(0.2,0.7,0.4) ≈ XYZ{Float64}(0.325,1.2,0.4) atol=91eps()
    @test 3XYZ{Float64}(0.125,0.5,0.03) ≈ XYZ{Float64}(0.375,1.5,0.09) atol=91eps()
    
    # issue #349
    msc_h_diff = 0
    for hsv_h in 0:0.1:360
        hsv = HSV(hsv_h, 1.0, 1.0) # most saturated
        lch = convert(LCHuv, hsv)
        msc = MSC(lch.h)
        msc_h_diff = max(msc_h_diff, colordiff(msc, lch))
    end
    @test msc_h_diff < 1

    @test MSC(123.45, 100) ≈ 0
    @test MSC(123.45, 0) ≈ 0

    msc_h_l_sat = 1
    for h = 0:0.1:359.9, l = 1:1:99
        c = MSC(h, l)
        hsv = convert(HSV, LCHuv(l, c, h))
        # When the color is saturated (except black/white), `s` or `v` is 1.
        msc_h_l_sat = min(msc_h_l_sat, max(hsv.s, hsv.v))
    end
    @test msc_h_l_sat > 1 - 1e-4

    # the linear interpolation introduces some approximation errors.(issue #349)
    @test MSC(0, 90, linear=true) > MSC(0, 90)
    @test MSC(280, 50, linear=true) < MSC(280, 50)

    @testset "find_maximum_chroma hsv_h=$hsv_h" for hsv_h in 0:60:300
        hsv = HSV(hsv_h, 1.0, 1.0) # corner
        lchab = convert(LCHab, hsv)
        lchuv = convert(LCHuv, hsv)
        lab = convert(Lab, hsv)
        luv = convert(Luv, hsv)
        @test Colors.find_maximum_chroma(lchab) ≈ lchab.c atol=0.01
        @test Colors.find_maximum_chroma(lchuv) ≈ lchuv.c atol=0.01
        @test Colors.find_maximum_chroma(lab) ≈ lchab.c atol=0.01
        @test Colors.find_maximum_chroma(luv) ≈ lchuv.c atol=0.01
    end

    # yellow in LCHab
    @test Colors.find_maximum_chroma(LCHab(94.2, 0, 100)) ≈ 93.749 atol=0.01
    @test Colors.find_maximum_chroma(LCHab(97.6, 0, 105)) ≈ 68.828 atol=0.01
end
