# Displaying color swatches
# -------------------------

const max_width = 180
const max_height = 150
const max_swatch_size = 25
const default_max_swatches = 128 * 128

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

function Base.show(io::IO, mime::MIME"image/svg+xml", cs::AbstractVector{T};
                   max_swatches::Integer=0) where T <: Color
    mat = Base.ReshapedArray(cs, (1, length(cs)), ())
    show(io, mime, mat, max_swatches=max_swatches)
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

    for i in 1:m, j in 1:n
        c = hex(cs[i, j])
        write(io,
            """
            <rect width="$sw" height="$sh" x="$(j-1)" y="$(i-1)" fill="#$c" />
            """)
    end

    write(io, "</svg>")
    flush(io) # return nothing
end

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

    for i in 1:d:m, j in 1:d:n
        # since there is no universal way,
        # calculate the mean color in "RGB space"
        csum = Float32[0, 0, 0]
        u = min(n-j+1, d) # cell width
        v = min(m-i+1, d) # cell height
        for y in i:i+v-1, x in j:j+u-1
            rgb = convert(RGB{Float32}, cs[y, x])
            csum += [red(rgb), green(rgb), blue(rgb)]
        end
        csum /= (u * v)
        c = hex(RGB{Float32}(csum[1], csum[2], csum[3]))
        write(io,
            """
            <path d="M$(j-1),$(i-1)h$d" stroke="#$c" />
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
