using Colors, FixedPointNumbers, Base.Test

# test utility function weighted_color_mean
parametric2 = [GrayA,AGray32,AGray]
parametric3 = ColorTypes.parametric3
parametric4A = setdiff(subtypes(ColorAlpha),[GrayA])
parametricA4 = setdiff(subtypes(AlphaColor),[AGray32,AGray])
colortypes = vcat(parametric3,parametric4A,parametricA4)
colorElementTypes = [Float16,Float32,Float64,BigFloat,UFixed8,UFixed10,UFixed12,UFixed14,UFixed16]

for c1 in (Gray{Bool}(1),Gray{Bool}(0))
    for c2 in (Gray{Bool}(1),Gray{Bool}(0))
        @test weighted_color_mean(true,c1,c2) == c1
        @test weighted_color_mean(false,c1,c2) == c2
    end
end

for T in colorElementTypes
    c1 = Gray{Bool}(1)
    c2 = Gray{Bool}(0)
    @test weighted_color_mean(T(0.5),c1,c2) == Gray{T}(0.5)
    c1 = Gray{T}(1)
    c2 = Gray{T}(0)
    @test weighted_color_mean(0.5,c1,c2) == Gray{T}(0.5)
end

for C in parametric2
    for T in colorElementTypes
        C == AGray32 && (T=U8)
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
            C == ARGB32 && (T=U8)
            c1 = C(T(1),T(1),T(0),T(1))
            c2 = C(T(0),T(1),T(1),T(0))
	    @test weighted_color_mean(0.5,c1,c2) == C(T(0.5),T(0.5)+T(1)-T(0.5),T(1)-T(0.5),T(0.5))
	end
    end
end
