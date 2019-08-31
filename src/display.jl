# Displaying color swatches
# -------------------------

const max_width = 180
const max_height = 150
const max_swatch_size = 25

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

function Base.show(io::IO, mime::MIME"image/svg+xml",
                   cs::AbstractVector{T}) where T <: Color
    show(io, mime, Base.ReshapedArray(cs, (1, length(cs)), ()))
end

function Base.show(io::IO, mime::MIME"image/svg+xml",
                           cs::AbstractMatrix{T}) where T <: Color
    m, n = size(cs)
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

function write_declaration(io::IO, ::MIME"image/svg+xml")
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        """)
    flush(io) # return nothing
end
