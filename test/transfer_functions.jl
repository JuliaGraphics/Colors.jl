using Colors, FixedPointNumbers
using Test

using Colors: to_linear, from_linear

const SRGBTF = Colors.TransferFunction{:sRGB}()
const G2_4 = Colors.TransferFunction{:Gamma2_4}()

struct IdentityTF3 <: Colors.AbstractTransferFunction{3} end
function Colors.to_linear(T::Type, vs::NTuple{3, <:Real}, ::IdentityTF3)
    return T.(vs)
end
function Colors.from_linear(T::Type, vs::NTuple{3, <:Real}, ::IdentityTF3)
    return T.(vs)
end

@testset "Transfer Func" begin
    @testset "sRGB transfer function" begin
        @testset "to_linear_rgb" begin
            @test to_linear_rgb(RGB(1, 0.5, 0)) ≈ RGB(1, 0.21404114048223244, 0)
            @test to_linear_rgb(RGB{Float32}, RGB24(0, 0.6, 1)) ≈ RGB{Float32}(0, 0.31854677, 1)
            rgb = rand(RGB)
            @test to_linear_rgb(rgb) ===
                to_linear_rgb(rgb, SRGBTF) === to_linear_rgb(rgb, builtin=:sRGB)
            @test_throws ArgumentError to_linear_rgb(rgb, builtin=:SRGB)
        end

        @testset "from_linear_rgb" begin
            @test from_linear_rgb(RGB(1, 0.5, 0)) ≈ RGB(1, 0.7353569830524495, 0)
            @test from_linear_rgb(RGB{Float32}, RGB24(0, 0.6, 1)) ≈ RGB{Float32}(0, 0.7977377, 1)
            rgb = rand(RGB)
            @test from_linear_rgb(rgb) ===
                from_linear_rgb(rgb, SRGBTF) === from_linear_rgb(rgb, builtin=:sRGB)
            @test_throws ArgumentError from_linear_rgb(rgb, builtin=:SRGB)
        end

        @testset "broadcast" begin
            rgbs = rand(RGB{Float32}, 100, 100)

            to_lrgb(img) = to_linear_rgb.(RGB, img, SRGBTF)
            lrgbs = @inferred(to_lrgb(rgbs))
            @test lrgbs isa Matrix{RGB{Float32}}

            from_lrgb(img) = from_linear_rgb.(RGB, img, SRGBTF)
            rgbs2 = @inferred(from_lrgb(lrgbs))
            @test rgbs2 isa Matrix{RGB{Float32}}

            @test all(rgbs2 .≈ rgbs)
        end

        @testset "to_linear(v::$T)" for T in (Float64, Float32, Float16, N0f8, N0f16)
            @test to_linear(T(0.0), SRGBTF) === T(0.0)
            @test to_linear(T(10 / 255), SRGBTF) ≈ T(0.0030352698354883753)
            @test to_linear(T(1.0), SRGBTF) === T(1.0)
            if T === N0f8 || T === N0f16
                @test to_linear(T(0.50196), SRGBTF) ≈ T(0.21585)
                @test to_linear(Float32, T(0.73725), SRGBTF) ≈ 0.5028865f0
                @test to_linear(Float64, T(11 / 255), SRGBTF) ≈ 0.003346535763899159
            else
                @test to_linear(T(0.5), SRGBTF) ≈ T(0.21404114048223244)
                @test to_linear(Float32, T(0.7353569830524495), SRGBTF) ≈ 0.5f0
                @test to_linear(Float64, T(12 / 256), SRGBTF) ≈ 0.0036606346738816443
            end
            v = rand(T)
            @test (to_linear(v, SRGBTF),) ===
                to_linear((v,), SRGBTF) === to_linear(T, (v,), SRGBTF)
        end
        @testset "to_linear accuracy" begin
            # Ensure a 0-ULP error for all Float32 values converted from N0f8.
            for v in 0N0f8:eps(N0f8):1N0f8
                if Float32(v) !== Float32(reinterpret(v) / 255)
                    @warn "Float32($v) is numerically inaccurate."
                    break
                end
                expected = Float32.(to_linear(Float32, BigFloat(Float32(v)), SRGBTF))
                actual = to_linear(Float32(v), SRGBTF)
                if actual !== expected
                    @warn "to_linear(Float32($v), SRGBTransferFunction) = $actual, expected = $expected"
                end
            end
        end

        @testset "from_linear(v::$T)" for T in (Float64, Float32, Float16, N0f8, N0f16)
            @test from_linear(T(0.0), SRGBTF) === T(0.0)
            @test from_linear(T(1.0), SRGBTF) === T(1.0)
            if T === N0f8 || T === N0f16
                @test from_linear(T(0.50196), SRGBTF) ≈ T(0.73664)
                @test from_linear(T(0.00392), SRGBTF) ≈ T(0.04984)
                @test from_linear(Float32, T(0.21569), SRGBTF) ≈ 0.5017734f0
            else
                @test from_linear(T(0.5), SRGBTF) ≈ T(0.7353569830524495)
                @test from_linear(T(0.75 / 255), SRGBTF) ≈ T(0.038)
                @test from_linear(Float32, T(0.21404114048223244), SRGBTF) ≈ 0.5f0
            end
            v = rand(T)
            @test (from_linear(v, SRGBTF),) ===
                from_linear((v,), SRGBTF) === from_linear(T, (v,), SRGBTF)
        end
    end

    @testset "Gamma 2.4 transfer function" begin
        @testset "to_linear_rgb" begin
            @test to_linear_rgb(RGB(1, 0.5, 0), builtin=:Gamma2_4) ≈ RGB(1, 0.18946457081379975, 0)
            @test to_linear_rgb(RGB{Float32}, RGB24(0, 0.6, 1), builtin=:Gamma2_4) ≈ RGB{Float32}(0, 0.29346952, 1)
            rgb = rand(RGB)
            @test to_linear_rgb(rgb, G2_4) === to_linear_rgb(rgb, builtin=:Gamma2_4)
        end

        @testset "from_linear_rgb" begin
            @test from_linear_rgb(RGB(1, 0.5, 0), builtin=:Gamma2_4) ≈ RGB(1, 0.7491535384383408, 0)
            @test from_linear_rgb(RGB{Float32}, RGB24(0, 0.6, 1), builtin=:Gamma2_4) ≈ RGB{Float32}(0, 0.8082822, 1)
            rgb = rand(RGB)
            @test from_linear_rgb(rgb, G2_4) === from_linear_rgb(rgb, builtin=:Gamma2_4)
        end

        @testset "to_linear(v::$T)" for T in (Float64, Float32, Float16, N0f8, N0f16)
            @test to_linear(T(0.0), G2_4) === T(0.0)
            @test to_linear(T(1.0), G2_4) === T(1.0)
            if T === N0f8 || T === Float16
                @test to_linear(T(0.50196), G2_4) ≈ T(0.19126)
                @test to_linear(Float32, T(0.74902), G2_4) ≈ 0.49978548f0
            else
                @test to_linear(T(0.5), G2_4) ≈ T(0.18946457081379975)
                @test to_linear(Float32, T(0.7491535384383408), G2_4) ≈ 0.5f0
            end
        end

        @testset "from_linear(v::$T)" for T in (Float64, Float32, Float16, N0f8, N0f16)
            @test from_linear(T(0.0), G2_4) === T(0.0)
            @test from_linear(T(1.0), G2_4) === T(1.0)
            if T === N0f8 || T === N0f16
                @test from_linear(T(0.50196), G2_4) ≈ T(0.75038)
                @test from_linear(Float32, T(0.19216), G2_4) ≈ 0.5029482f0
            else
                @test from_linear(T(0.5), G2_4) ≈ T(0.7491535384383408)
                @test from_linear(Float32, T(0.18946457081379975), G2_4) ≈ 0.5f0
            end
        end
    end

    @testset "Identity transfer function" begin
        @test to_linear_rgb(RGB{Float32}, RGB(1, 0.5, 0), IdentityTF3()) === RGB(1, 0.5f0, 0)
        @test from_linear_rgb(RGB(1, 0.5, 0), IdentityTF3()) === RGB(1, 0.5, 0)
    end
end
