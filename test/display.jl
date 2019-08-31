@testset "Display" begin
    function count_filled_rect(svg::AbstractString)
        n = 0
        i = firstindex(svg)
        while true
            r = findnext(r"<rect[^>]*\sfill=\"#[0-9A-F]{6}\"[^>]+>", svg, i)
            r === nothing && return n
            n += 1
            i = last(r)
        end
    end

    # test ability to add to previously shown array of colors - issue #328
    a = [colorant"white", colorant"red"]
    buf = IOBuffer()
    show(buf, MIME"image/svg+xml"(), a)
    take!(buf)
    push!(a, colorant"blue")
    @test length(a) == 3


    # the following tests depend on the constants in "src/display.jl"

    # single color

    show(buf, MIME"image/svg+xml"(), colorant"hsl(120, 100%, 50%)")
    single = String(take!(buf))
    @test occursin(r"<svg[^>]+\swidth=\"25mm\"", single)
    @test occursin(r"<svg[^>]+\sheight=\"25mm\"", single)
    @test occursin(r"\sfill=\"#00FF00\"", single)
    @test occursin(r"</svg>$", single)


    # vectors

    # square swatches
    v3 = [colorant"red", colorant"green", colorant"blue"]
    show(buf, MIME"image/svg+xml"(), v3)
    vector3 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"75mm\"", vector3)
    @test occursin(r"<svg[^>]*\sheight=\"25mm\"", vector3)
    @test occursin(r"<rect[^>]*\swidth=\".96\"", vector3) # 0.96 = 24mm/25mm
    @test occursin(r"<rect[^>]*\sheight=\".96\"", vector3) # height = width
    @test occursin(r"<rect[^>]*\sfill=\"#FF0000\"", vector3)
    @test occursin(r"<rect[^>]*\sfill=\"#008000\"", vector3)
    @test occursin(r"<rect[^>]*\sfill=\"#0000FF\"", vector3)
    @test occursin(r"</svg>$", vector3)

    # rectangle swatches
    show(buf, MIME"image/svg+xml"(), colormap("RdBu", 100))
    vec100 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", vec100) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"25mm\"", vec100)
    @test occursin(r"<rect[^>]*\swidth=\"1\"", vec100) # no padding
    @test occursin(r"<rect[^>]*\sheight=\".96\"", vec100) # 0.96 = 24mm/25mm
    @test count_filled_rect(vec100) == 100


    # m * n matrices

    # n * max_swatch_size <= max_width &&
    # m * max_swatch_size <= max_height
    # square swatches
    m2x2 = [colorant"white" colorant"blue"
            colorant"black" colorant"cyan"]
            show(buf, MIME"image/svg+xml"(), m2x2)
    mat2x2 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"50mm\"", mat2x2)
    @test occursin(r"<svg[^>]*\sheight=\"50mm\"", mat2x2)
    @test occursin(r"<rect[^>]*\swidth=\".96\"", mat2x2) # 0.96 = 24mm/25mm
    @test occursin(r"<rect[^>]*\sheight=\".96\"", mat2x2) # height = width
    @test occursin(r"<rect[^>]*\sfill=\"#FFFFFF\"", mat2x2)
    @test occursin(r"<rect[^>]*\sfill=\"#0000FF\"", mat2x2)
    @test occursin(r"<rect[^>]*\sfill=\"#000000\"", mat2x2)
    @test occursin(r"<rect[^>]*\sfill=\"#00FFFF\"", mat2x2)
    @test occursin(r"</svg>$", vector3)

    # n * max_swatch_size > max_width &&
    # m * max_swatch_size <= max_height
    # square swatches
    show(buf, MIME"image/svg+xml"(), rand(RGB, 2, 9))
    mat2x9 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", mat2x9) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"40mm\"", mat2x9) # 40mm = 180mm/9 * 2
    @test occursin(r"<rect[^>]*\swidth=\".95\"", mat2x9) # 0.95 = 19mm/20mm
    @test occursin(r"<rect[^>]*\sheight=\".95\"", mat2x9) # height = width
    @test count_filled_rect(mat2x9) == 18

    # n * max_swatch_size <= max_width &&
    # m * max_swatch_size > max_height
    # square swatches
    show(buf, MIME"image/svg+xml"(), rand(RGB, 10, 2))
    mat10x2 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"30mm\"", mat10x2) # 30mm = 150mm/10 * 2
    @test occursin(r"<svg[^>]*\sheight=\"150mm\"", mat10x2) # max_height
    @test occursin(r"<rect[^>]*\swidth=\".93\"", mat10x2) # 0.93 = 14mm/15mm
    @test occursin(r"<rect[^>]*\sheight=\".93\"", mat10x2) # height = width
    @test count_filled_rect(mat10x2) == 20

    # issue #341
    # n * max_swatch_size > max_width &&
    # m * max_swatch_size > max_height &&
    # max_width / n * m >= max_swatch_size
    # square swatches
    show(buf, MIME"image/svg+xml"(), rand(RGB, 28, 181))
    mat28x181 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", mat28x181) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"27.85mm\"", mat28x181) # 180mm/181 * 28
    @test occursin(r"<rect[^>]*\swidth=\"1\"", mat28x181) # no padding
    @test occursin(r"<rect[^>]*\sheight=\"1\"", mat28x181) # no padding
    @test count_filled_rect(mat28x181) == 28*181

    # issue #341
    # n * max_swatch_size > max_width &&
    # m * max_swatch_size > max_height &&
    # max_height / m * n < max_swatch_size
    # rectangle swatches
    # Keeping the aspect ratio 1:1 (i.e. square) seems to be more important
    # than keeping the width/height >= 25mm, for large matrices.
    show(buf, MIME"image/svg+xml"(), rand(RGB, 200, 28))
    mat200x28 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"25mm\"", mat200x28) # max_swatch_size
    @test occursin(r"<svg[^>]*\sheight=\"150mm\"", mat200x28) # max_height
    @test occursin(r"<rect[^>]*\swidth=\"1\"", mat200x28) # no padding
    @test occursin(r"<rect[^>]*\sheight=\"1\"", mat200x28) # no padding
    @test count_filled_rect(mat200x28) == 200*28
end
