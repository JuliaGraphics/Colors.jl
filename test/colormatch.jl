using Colors, Test

@testset "Colormatch" begin
    @test colormatch(500) === colormatch(CIE1931_CMF, 500)

    cmfs = (CIE1931_CMF, CIE1964_CMF, CIE1931J_CMF, CIE1931JV_CMF, CIE2006_2_CMF, CIE2006_10_CMF)
    @testset "$cmf" for cmf in cmfs
        @test colormatch(cmf, 350.0) === XYZ(0.0, 0.0, 0.0)
        @test colormatch(cmf, 850.0) === XYZ(0.0, 0.0, 0.0)
        xyz450 = colormatch(cmf, 450.0)
        @test xyz450.y < xyz450.x < xyz450.z
        xyz550 = colormatch(cmf, 550.0)
        @test xyz550.z < xyz550.x < xyz550.y
        xyz600 = colormatch(cmf, 600.0)
        @test xyz600.z < xyz600.y < xyz600.x
        xyz551 = colormatch(cmf, 551.0)
        @test colormatch(cmf, 550.5) ≈ (xyz550 + colormatch(cmf, 551)) / 2
    end
end
