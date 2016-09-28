using Colors, FixedPointNumbers, Base.Test

# test utility function hex
for T in (UFixed8, UFixed10, UFixed12, UFixed14, UFixed16, Float16, Float32, Float64,BigFloat)
    @test hex(RGB{T}(1,0.5,0)) == "FF8000"
    @test hex(RGBA{T}(1,0.5,0,0.25)) == "40FF8000"
end

# test utility function hex
parametric2 = [GrayA,AGray32,AGray]
parametric3 = ColorTypes.parametric3
parametric4A = setdiff(subtypes(ColorAlpha),[GrayA])
parametricA4 = setdiff(subtypes(AlphaColor),[AGray32,AGray])
colortypes = vcat(parametric3,parametric4A,parametricA4)
colorElementTypes = [Float16,Float32,Float64,BigFloat,UFixed8,UFixed10,UFixed12,UFixed14,UFixed16]

for T in colorElementTypes #Bool not working at the moment add to types later
    c = Gray{T}(1)
    @test hex(c) == "FFFFFF"
end

for C in parametric2
    for T in [Float16,Float32,Float64,BigFloat,UFixed8,UFixed10,UFixed12,UFixed14,UFixed16]
        c = convert(C,AGray{T}(1,0.5))
	@test hex(c) == "80FFFFFF"
    end
end

for C in setdiff(colortypes,[DIN99d,DIN99dA,ADIN99d]) # [DIN99d,DIN99dA,ADIN99d] not working
    for T in (Float16,Float32,Float64,BigFloat)
	if issubtype(C,Color)
            c = convert(C, RGB{T}(1,0.5,0))
	    @test hex(c) == "FF8000" || hex(c) == "FF7F00"
	else
            c = convert(C, ARGB{T}(1,0.5,0,0.5))
            @test hex(c) == "80FF8000" || hex(c) == "80FF7F00"
	end
    end
end

for C in (RGB,BGR,RGB1,RGB4,ARGB,ABGR,RGBA,BGRA)
    for T in (UFixed8, UFixed10, UFixed12, UFixed14, UFixed16)
	if issubtype(C,Color)
            c = convert(C, RGB{T}(1,0.5,0))
	    @test hex(c) == "FF8000"
	else
            c = convert(C, ARGB{T}(1,0.5,0,0.5))
            @test hex(c) == "80FF8000"
	end
    end
end

# test utility function weighted_color_mean
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

for C in setdiff(colortypes,[DIN99A,DIN99dA,DIN99oA,HSIA,HSLA,HSVA,LCHabA,LCHuvA,LMSA,LabA,LuvA,XYZA,YCbCrA,YIQA,xyYA,ADIN99d,ADIN99o,ADIN99,AHSI,AHSL,AHSV,ALCHab,ALCHuv,ALMS,ALab,ALuv,AXYZ,AYCbCr,AYIQ,AxyY]) # do not work with mapc
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


#=
for i=1:100000
for C in setdiff(ColorTypes.parametric3,[DIN99d])
    for T in (Float16,Float32,Float64)
	a,b,c = rand(T,3)
	#println("$a $b $c")
        c1 = RGB(a,b,c)
	c2 = convert(RGB, convert(C,c1))
	@test_approx_eq_eps(comp1(c1),comp1(c2),7e-2)
	@test_approx_eq_eps(comp2(c1),comp2(c2),7e-2)
	@test_approx_eq_eps(comp3(c1),comp3(c2),7e-2)
    end
end
end
=#
