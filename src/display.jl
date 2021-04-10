# Displaying color swatches
# -------------------------

const max_width = 180
const max_height = 150
const max_swatch_size = 25
const default_max_swatches = 128 * 128

_isfinite(c::Colorant) = mapreducec(isfinite, &, true, c)

Base.showable(::MIME"image/svg+xml", c::Colorant) = _isfinite(c)
# Note that ImageShow.jl overloads `showable` for `AbstractMatrix{<:Color}`
function Base.showable(::MIME"image/svg+xml", cs::Union{AbstractVector{<:Colorant},
                                                        AbstractMatrix{<:Color}})
    all(_isfinite, cs)
end

function Base.show(io::IO, mime::MIME"image/svg+xml", c::Color)
    write_declaration(io, mime)
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="25mm" height="25mm" viewBox="0 0 1 1">
            <rect width="1" height="1" fill="#$(hex(c))" stroke="none"/>
        </svg>
        """)
    flush(io) # return nothing
end

function Base.show(io::IO, mime::MIME"image/svg+xml", c::TransparentColor)
    show(io, mime, [c], max_swatches=default_max_swatches)
end


function Base.show(io::IO, mime::MIME"image/svg+xml", cs::AbstractVector{T};
                   max_swatches::Integer=0) where T <: Color
    mat = Base.ReshapedArray(cs, (1, length(cs)), ())
    show(io, mime, mat, max_swatches=max_swatches)
end

function Base.show(io::IO, mime::MIME"image/svg+xml",cs::AbstractVector{T};
                   max_swatches::Integer=0) where T <: TransparentColor

    # use random id to avoid id collision when the SVG is embedded inline
    id = "pat_" * string(rand(UInt32), base=62)
    n = length(cs)
    actual_max_swatches = max_swatches > 0 ? max_swatches : default_max_swatches
    # When `max_swatches` is specified, the following warning is suppressed.
    if max_swatches == 0 && n > actual_max_swatches
        trunc = n - actual_max_swatches
        @warn """Last $trunc swatches (of $n-element Array) are truncated."""
        yield()
    end
    w = min(n * max_swatch_size, max_width)

    scale = n * max_swatch_size / w # 1 for square, >1 for portrait
    rscale = round(scale, digits=3)
    pat_scale = rscale == 1 ? "" : """patternTransform="scale($rscale,1)" """

    # the following are with the assumption that scale >= 1 (i.e. not landscape)
    if rscale == 1
        shape = "0v1h-1z" # triangle
    else # rscale > 1
        simplify(x) = replace(string(round(x, digits=2)), r"^0"=>"")
        d1 = simplify((1 - 1 / scale) / 2)
        d2 = simplify((1 + 1 / scale) / 2)
        shape = """$(d1)V1h-1V$(d2)z""" # trapezoid
    end
    write_declaration(io, mime)
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(w)mm" height="25mm" viewBox="0 0 $n 1" stroke="none"
             preserveAspectRatio="none" shape-rendering="crispEdges">
        <defs>
            <pattern id="$id" width=".2" height=".2"
                     patternUnits="userSpaceOnUse" $pat_scale>
                <path d="M.1,0h.1v.1h-.2v.1h.1z" fill="#999" opacity=".5" />
            </pattern>
        </defs>
        <rect width="$n" height="1" fill="url(#$id)" />
        """)
    for (i, c) in enumerate(cs)
        i > actual_max_swatches && break
        hexc = hex(color(c))
        opacity = string(round(float(alpha(c)), digits=4))
        op = replace(opacity, r"(^0(?!\.0$))|(\.0$)"=>"")
        write(io,
            """
            <path d="M$i,$shape" fill="#$hexc" />
            <path d="M$(i-1),0h1v1h-1z" fill="#$hexc" fill-opacity="$op" />
            """)
    end
    write(io, "</svg>")
    flush(io) # return nothing
end


function Base.show(io::IO, mime::MIME"image/svg+xml", cs::AbstractMatrix{T};
                   max_swatches::Integer=0) where T <: Color
    m, n = size(cs)
    actual_max_swatches = max_swatches > 0 ? max_swatches : default_max_swatches
    if m * n > actual_max_swatches
        return show_strokes(io, mime, cs, max_swatches=max_swatches)
    end
    w = min(n * max_swatch_size, max_width)
    h = min(m * max_swatch_size, max_height)
    if max_width * m > max_height * n
        w = max(h * n / m, max_swatch_size)
    else
        h = max(w * m / n, max_swatch_size)
    end

    simplify(x) = replace(string(round(x, digits=2)), r"(^0(?=\.))|(.0+$)"=>"")
    sw = simplify(1 - (w / n < 3.6 ? 0 : n / w))
    sh = simplify(1 - (h / m < 3.6 ? 0 : m / h))
    if sw == "1" && sh == "1"
        return show_strokes(io, mime, cs, max_swatches=max_swatches)
    end

    comp(x) = round(x)==round(x, digits=2) ? Int(round(x)) : round(x, digits=2)
    write_declaration(io, mime)
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(comp(w))mm" height="$(comp(h))mm"
             viewBox="0 0 $n $m" preserveAspectRatio="none"
             shape-rendering="crispEdges" stroke="none">
        """)

    i1, j1 = firstindex(cs, 1), firstindex(cs, 2)
    for i in 0:m-1, j in 0:n-1
        c = hex(cs[i1 + i, j1 + j])
        write(io,
            """
            <rect width="$sw" height="$sh" x="$j" y="$i" fill="#$c" />
            """)
    end

    write(io, "</svg>")
    flush(io) # return nothing
end

# TODO: add `show` method for `AbstractMatrix{T} where T<:TransparentColor`
# Unlike the case of opaque `Color`, hasty generalization has some problems:
#  - Large matrices (i.e. images) may cause performance (size or speed) issue
#  - User may expect a raster image to be displayed instead of swatches
#  - ImageShow.jl(v0.2.0) suppresses only the SVG matrices of opaque `Color`
#  - Checker pattern is less useful when each swatch is smaller than the checker
#  - Area-average as reduction method is perceptually meaningless for alpha


function show_strokes(io::IO, mime::MIME"image/svg+xml", cs::AbstractMatrix{T};
                      max_swatches::Integer=0) where T <: Color
    m, n = size(cs)
    actual_max_swatches = max_swatches > 0 ? max_swatches : default_max_swatches
    # When `max_swatches` is specified, the following warning is suppressed.
    if max_swatches == 0 && m * n > actual_max_swatches
        @warn """
            Output swatches are reduced due to the large size ($m×$n).
            Load the ImageShow package for large images."""
        yield()
    end
    w = max_width
    h = max_height
    if max_width * m > max_height * n
        w = n / m * h
    else
        h = m / n * w
    end

    # decimation factor `d` is rounded to integer to simplify the SVG document
    d = Int(ceil(sqrt(m * n / actual_max_swatches)))

    comp(x) = round(x)==round(x, digits=2) ? Int(round(x)) : round(x, digits=2)
    write_declaration(io, mime)
    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(comp(w))mm" height="$(comp(h))mm"
             viewBox="0 -$(comp(d/2)) $n $m" stroke-width="$d"
             stroke-linecap="butt" shape-rendering="crispEdges">
        """)

    i1, j1 = firstindex(cs, 1), firstindex(cs, 2)
    for i in 0:d:m-1, j in 0:d:n-1
        # since there is no universal way,
        # calculate the mean color in "RGB space"
        csum = RGB{Float32}(0, 0, 0)
        u = min(n - j, d) # cell width
        v = min(m - i, d) # cell height
        for x in j:j+u-1, y in i:i+v-1
            rgb = convert(RGB, cs[i1 + y, j1 + x])
            csum = mapc((s, a) -> s + Float32(a), csum, rgb)
        end
        c = hex(mapc(s -> s / (u * v), csum))
        write(io,
            """
            <path d="M$j,$(i)h$d" stroke="#$c" />
            """)
    end

    write(io, "</svg>")
    flush(io) # return nothing
end

function write_declaration(io::IO, ::MIME"image/svg+xml")
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        """)
    flush(io) # return nothing
end
