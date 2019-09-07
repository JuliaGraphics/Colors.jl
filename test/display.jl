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

    function count_colored_stroke(svg::AbstractString)
        n = 0
        i = firstindex(svg)
        while true
            r = findnext(r"<path[^>]*\sstroke=\"#[0-9A-F]{6}\"[^>]+>", svg, i)
            r === nothing && return n
            n += 1
            i = last(r)
        end
    end

    # test ability to add to previously shown array of colors - issue #328
    a = [colorant"white", colorant"red"]
    buf = IOBuffer()
    show(buf, "image/svg+xml", a)
    take!(buf)
    push!(a, colorant"blue")
    @test length(a) == 3


    # the following tests depend on the constants in "src/display.jl"

    # single color
    # ------------
    show(buf, "image/svg+xml", colorant"hsl(120, 100%, 50%)")
    single = String(take!(buf))
    @test occursin(r"<svg[^>]+\swidth=\"25mm\"", single)
    @test occursin(r"<svg[^>]+\sheight=\"25mm\"", single)
    @test occursin(r"\sfill=\"#00FF00\"", single)
    @test occursin(r"</svg>$", single)


    # vectors
    # -------
    # square swatches
    v3 = [colorant"red", colorant"green", colorant"blue"]
    show(buf, "image/svg+xml", v3)
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
    show(buf, "image/svg+xml", colormap("RdBu", 100))
    vec100 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", vec100) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"25mm\"", vec100)
    @test occursin(r"<rect[^>]*\swidth=\"1\"", vec100) # no padding
    @test occursin(r"<rect[^>]*\sheight=\".96\"", vec100) # 0.96 = 24mm/25mm
    @test count_filled_rect(vec100) == 100

    # issue #317
    # limits max swatches
    # the size warning should be suppressed
    show(buf, MIME"image/svg+xml"(), v3, max_swatches=2) # not string but MIME
    lim_vector3 = String(take!(buf))
    # since `max_swatches`(=2) is less practical,
    # the width/height is greater than `max_swatch_size`
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", lim_vector3) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"60mm\"", lim_vector3) # 180mm/3 * 1
    # decimation factor `d` should be 2
    # viewBox is based on the original size (=3x1)
    @test occursin(r"<svg[^>]*\sviewBox=\"0 -1 3 1\"", lim_vector3)
    # therefore, each swatch is contrarily enlarged due to the swatch reduction.
    # stroke width is equivalent to swatch height which is equal to `d`(=2)
    @test occursin(r"<svg[^>]*\sstroke-width=\"2\"", lim_vector3)
    # swatch width is equal to `d`(=2)
    @test occursin(r"<path[^>]*\sd=\"[^\"]+h2\"", lim_vector3) # no padding
    # the mean RGB of first 2 elements (red and green)
    @test occursin(r"stroke=\"#804000\"[^/]*/>\s*<path\s", lim_vector3)
    # the RGB of last element (blue)
    @test occursin(r"stroke=\"#0000FF\"[^/]*/>\s*</svg>", lim_vector3)
    @test count_colored_stroke(lim_vector3) == 2 # <= max_swatches


    # m * n matrices
    # --------------
    # n * max_swatch_size <= max_width &&
    # m * max_swatch_size <= max_height
    # square swatches
    m2x2 = [colorant"white" colorant"blue"
            colorant"black" colorant"cyan"]
    show(buf, "image/svg+xml", m2x2)
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
    show(buf, "image/svg+xml", rand(RGB, 2, 9))
    mat2x9 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", mat2x9) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"40mm\"", mat2x9) # 40mm = 180mm/9 * 2
    @test occursin(r"<rect[^>]*\swidth=\".95\"", mat2x9) # 0.95 = 19mm/20mm
    @test occursin(r"<rect[^>]*\sheight=\".95\"", mat2x9) # height = width
    @test count_filled_rect(mat2x9) == 18

    # n * max_swatch_size <= max_width &&
    # m * max_swatch_size > max_height
    # square swatches
    show(buf, "image/svg+xml", rand(RGB, 10, 2))
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
    # square swatches (strokes)
    show(buf, "image/svg+xml", rand(RGB, 28, 181))
    mat28x181 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", mat28x181) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"27.85mm\"", mat28x181) # 180mm/181 * 28
    @test occursin(r"<path[^>]*\sd=\"[^\"]+h1\"", mat28x181) # no padding
    @test count_colored_stroke(mat28x181) == 28*181

    # issue #341
    # n * max_swatch_size > max_width &&
    # m * max_swatch_size > max_height &&
    # max_height / m * n < max_swatch_size
    # square swatches (strokes)
    show(buf, "image/svg+xml", rand(RGB, 200, 28))
    mat200x28 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"21mm\"", mat200x28) # 150mm/200*28
    @test occursin(r"<svg[^>]*\sheight=\"150mm\"", mat200x28) # max_height
    @test occursin(r"<path[^>]*\sd=\"[^\"]+h1\"", mat200x28) # no padding
    @test count_colored_stroke(mat200x28) == 200*28

    # issue #317
    # implicitly limits max swatches (but explicitly warns)
    # m * n > default_max_swatches
    # square swatches (strokes) with reduction
    m184x360 = [HSV(h, s / 183, 0.8) for s = 0:183, h = 0:359]
    # warning of size
    warning = r"the large size \(184×360\)"
    @test_logs (:warn, warning) show(buf, "image/svg+xml", m184x360)
    mat184x360 = String(take!(buf))
    @test occursin(r"<svg[^>]*\swidth=\"180mm\"", mat184x360) # max_width
    @test occursin(r"<svg[^>]*\sheight=\"92mm\"", mat184x360) # 180mm/360 * 184
    # decimation factor should be 3
    @test occursin(r"<svg[^>]*\sviewBox=\"0 -1.5[0]* 360 184\"", mat184x360)
    @test occursin(r"<svg[^>]*\sstroke-width=\"3\"", mat184x360) # `d`(=3)
    @test occursin(r"<path[^>]*\sd=\"[^\"]+h3\"", mat184x360) # `d`(=3)
    # the mean RGB of 3 (not 9) elements in the bottom-right corner
    # "CC0007" == hex(RGB(0.8, 0.0, (0.12/3 + 0.08/3 + 0.04/3)/3))
    @test occursin(r"stroke=\"#CC0007\"[^/]*/>\s*</svg>", mat184x360)
    @test count_colored_stroke(mat184x360) == ceil(184/3)*ceil(360/3)

    # issue #317
    # limits max swatches
    # the size warning should be suppressed
    show(buf, MIME"image/svg+xml"(), m2x2, max_swatches=3) # not string but MIME
    lim_mat2x2= String(take!(buf))
    # since `max_swatches`(=3) is less practical,
    # the width/height is greater than `max_swatch_size`
    @test occursin(r"<svg[^>]*\swidth=\"150mm\"", lim_mat2x2) # 180mm/2 * 2
    @test occursin(r"<svg[^>]*\sheight=\"150mm\"", lim_mat2x2) # max_height
    # decimation factor `d` should be 2
    @test occursin(r"<svg[^>]*\sviewBox=\"0 -1 2 2\"", lim_mat2x2)
    @test occursin(r"<svg[^>]*\sstroke-width=\"2\"", lim_mat2x2) # `d`(=2)
    @test occursin(r"<path[^>]*\sd=\"[^\"]+h2\"", lim_mat2x2) # `d`(=2)
    # the mean RGB of 2x2 elements
    @test occursin(r"stroke=\"#4080BF\"[^/]*/>\s*</svg>", lim_mat2x2)
    @test count_colored_stroke(lim_mat2x2) == 1 # <= max_swatches
end
