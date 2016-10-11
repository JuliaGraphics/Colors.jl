using Colors, FixedPointNumbers, Base.Test

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
	if issubtype(C,Color)
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

# test utility function linspace
# linspace uses weighted_color_mean which is extensively tested.
# Therefore it suffices to test the function using gray colors.
for T in colorElementTypes
    c1 = Gray(T(1))
    c2 = Gray(T(0))
    linc1c2 = linspace(c1,c2,43)
    @test length(linc1c2) == 43
    @test linc1c2[1] == c1
    @test linc1c2[end] == c2
    @test linc1c2[22] == Gray(T(0.5))
    @test typeof(linc1c2) == Array{Gray{T},1}
end
