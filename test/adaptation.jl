using Test, Colors
import Colors: adaptation_xyz

@testset "Adaptation" begin
    E = Colors.WP_E
    D50 = Colors.WP_D50
    D65 = Colors.WP_D65
    F2 = Colors.WP_F2

    # colors from Julia logo (sRGB D65)
    rgbF32k = convert(RGB{Float32}, colorant"#1a1a1a")
    rgbF32b = convert(RGB{Float32}, colorant"#4d64ae")
    rgbF32r = convert(RGB{Float32}, colorant"#ca3c32")
    rgbF32g = convert(RGB{Float32}, colorant"#399746")
    rgbF32p = convert(RGB{Float32}, colorant"#9259a3")

    xyzF32k = convert(XYZ{Float32}, rgbF32k, D65)
    xyzF32b = convert(XYZ{Float32}, rgbF32b, D65)
    xyzF32r = convert(XYZ{Float32}, rgbF32r, D65)
    xyzF32g = convert(XYZ{Float32}, rgbF32g, D65)
    xyzF32p = convert(XYZ{Float32}, rgbF32p, D65)

    # colors converted into CIELAB D50 by Adobe Photoshop 16-bit LAB mode
    labF32k = Lab{Float32}( 9.262,  0.000,  0.000)
    labF32b = Lab{Float32}(43.290,  8.473,-42.961)
    labF32r = Lab{Float32}(47.718, 56.254, 39.848)
    labF32g = Lab{Float32}(55.550,-42.039, 33.699)
    labF32p = Lab{Float32}(46.680, 33.582,-30.641)

    @testset "whitebalance" begin
        # round trip test
        for wp1 in (D50, E), wp2 in (D65, F2)
            # green cause a clipping
            for c in (rgbF32k, rgbF32b, rgbF32r, rgbF32p)
                @test isa(whitebalance(c, wp1, wp2), typeof(c))
                @test whitebalance(c, wp1, wp2) != c
                ca = whitebalance(c, wp1, wp2)
                # if max(red(ca), green(ca), blue(ca)) == 1.0 ||
                #    min(red(ca), green(ca), blue(ca)) == 0.0
                #    @info "$wp1<->$wp2 #$(hex(c))"
                # end
                @test whitebalance(ca, wp2, wp1) ≈ c atol = 100eps(Float32)
            end
        end
    end

    for cat in (CAT_XYZ(), CAT_HPE(), CAT_BFD(), CAT_97s(), CAT_02(), CAT_BFD_NL())
        # eltype depends on `src_white`.
        @test isa(adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=cat), XYZ{Float64})
        d65F32 = convert(XYZ{Float32}, D65)
        @test isa(adaptation_xyz(xyzF32r, src_white=d65F32, ref_white=D50, cat=cat), XYZ{Float32})

        # return type is always the same as input color type
        @test isa(adaptation(labF32r, src_white=D50, ref_white=D65, cat=cat), Lab{Float32})

        # src_white==ref_white
        @test adaptation(labF32r, src_white=D50, ref_white=D50, cat=cat) ≈ labF32r atol=0.001

        # round-trip
        ca = adaptation(labF32r, src_white=D50, ref_white=D65, cat=cat)
        @test adaptation(ca, src_white=D65, ref_white=D50, cat=cat) ≈ labF32r atol=0.001
    end

    @testset "CAT_XYZ" begin
        # XYZ-space (not *so-called* LMS space)
        xyzF32r_D50_xyz = XYZ{Float32}(xyzF32r.x * D50.x/D65.x,
                                       xyzF32r.y * D50.y/D65.y,
                                       xyzF32r.z * D50.z/D65.z)
        @test adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=CAT_XYZ()) ≈ xyzF32r_D50_xyz atol=0.0001
        @test adaptation(xyzF32r_D50_xyz, src_white=D50, ref_white=D65, cat=CAT_XYZ()) ≈ xyzF32r atol=0.0001
    end

    @testset "CAT_HPE" begin
        # FIXME: replace the values in the expected results with ones from
        #        credible sources and indicate the sources.
        xyzF32r_D50_hpe = XYZ{Float32}(0.276182, 0.161068, 0.035709)
        @test adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=CAT_HPE()) ≈ xyzF32r_D50_hpe atol=0.0001
        @test adaptation(xyzF32r_D50_hpe, src_white=D50, ref_white=D65, cat=CAT_HPE()) ≈ xyzF32r atol=0.0001
    end

    @testset "CAT_BFD" begin
        # FIXME: replace the values in the expected results with ones from
        #        credible sources and indicate the sources.
        xyzF32r_D50_bfd = XYZ{Float32}(0.279519, 0.165742, 0.035396)
        @test adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=CAT_BFD()) ≈ xyzF32r_D50_bfd atol=0.0001
        @test adaptation(xyzF32r_D50_bfd, src_white=D50, ref_white=D65, cat=CAT_BFD()) ≈ xyzF32r atol=0.0001


        # from sRGB D65 to CIELAB D50
        srgb_to_lab(c::RGB) = convert(Lab, adaptation_xyz(c, D65, D50, CAT_BFD()), D50)
        # from CIELAB D50 to sRGB D65
        lab_to_srgb(c::Lab) = convert(RGB, adaptation_xyz(c, D50, D65, CAT_BFD()), D65)

        # default RGB<->Lab conversion does not agree with ICC recommendation.
        @test colordiff(srgb_to_lab(rgbF32r), convert(Lab, rgbF32r)) >= 0.5
        @test colordiff(lab_to_srgb(labF32r), convert(RGB, labF32r)) >= 0.5

        @test srgb_to_lab(rgbF32k) ≈ labF32k atol=0.01
        @test srgb_to_lab(rgbF32b) ≈ labF32b atol=0.01
        @test srgb_to_lab(rgbF32r) ≈ labF32r atol=0.01
        @test srgb_to_lab(rgbF32g) ≈ labF32g atol=0.01
        @test srgb_to_lab(rgbF32p) ≈ labF32p atol=0.01
        @test lab_to_srgb(labF32k) ≈ rgbF32k atol=0.01
        @test lab_to_srgb(labF32b) ≈ rgbF32b atol=0.01
        @test lab_to_srgb(labF32r) ≈ rgbF32r atol=0.01
        @test lab_to_srgb(labF32g) ≈ rgbF32g atol=0.01
        @test lab_to_srgb(labF32p) ≈ rgbF32p atol=0.01

    end

    @testset "CAT_97s" begin
        # FIXME: replace the values in the expected results with ones from
        #        credible sources and indicate the sources.
        xyzF32r_D50_97s = XYZ{Float32}(0.281309, 0.166986, 0.034875)
        @test adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=CAT_97s()) ≈ xyzF32r_D50_97s atol=0.0001
        @test adaptation(xyzF32r_D50_97s, src_white=D50, ref_white=D65, cat=CAT_97s()) ≈ xyzF32r atol=0.0001
    end

    @testset "CAT_02" begin
        # FIXME: replace the values in the expected results with ones from
        #        credible sources and indicate the sources.
        xyzF32r_D50_02 = XYZ{Float32}(0.279247, 0.165412, 0.035048)
        @test adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=CAT_02()) ≈ xyzF32r_D50_02 atol=0.0001
        @test adaptation(xyzF32r_D50_02, src_white=D50, ref_white=D65, cat=CAT_02()) ≈ xyzF32r atol=0.0001
    end

    @testset "CAT_BFD_NL" begin
        # FIXME: replace the values in the expected results with ones from
        #        credible sources and indicate the sources.
        xyzF32r_D50_bfd_nl = XYZ{Float32}(0.279099, 0.165613, 0.032866)
        @test adaptation_xyz(rgbF32r, src_white=D65, ref_white=D50, cat=CAT_BFD_NL()) ≈ xyzF32r_D50_bfd_nl atol=0.0001
        @test adaptation(xyzF32r_D50_bfd_nl, src_white=D50, ref_white=D65, cat=CAT_BFD_NL()) ≈ xyzF32r atol=0.0001
    end
end
