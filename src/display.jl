function makeshow(CV, CVstr, fields)
    exs = [:(showcompact(io, $(fields[d]))) for d = 1:length(fields)]
    exc = [d < length(fields) ? (:(print(io, ','))) : (:(print(io, ')'))) for d = 1:length(fields)]
    exboth = hcat(exs, exc)'
    ex = Expr(:block, exboth...)
    eval(quote
        function show{T,f}(io::IO, c::$CV{FixedPointNumbers.UfixedBase{T,f}})
            print(io, "$($CVstr){Ufixed", f, "}(")
            $ex
        end
    end)
end

for (CV, CVstr, fields) in ((RGB,  "RGB",  (:(c.r),:(c.g),:(c.b))),
                            (XYZ,  "XYZ",  (:(c.x),:(c.y),:(c.z))),
                            (RGBA, "RGBA", (:(c.c.r),:(c.c.g),:(c.c.b),:(c.alpha))))
    makeshow(CV, CVstr, fields)
end

# Displaying color swatches
# -------------------------

function writemime(io::IO, ::MIME"image/svg+xml", c::ColorValue)
    write(io,
        """
        <?xml version"1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="25mm" height="25mm" viewBox="0 0 1 1">
             <rect width="1" height="1"
                   fill="#$(hex(c))" stroke="none"/>
        </svg>
        """)
end

function writemime{T <: ColorValue}(io::IO, ::MIME"image/svg+xml",
                                    cs::AbstractVecOrMat{T})
    m,n = ndims(cs) == 2 ? size(cs) : (1,length(cs))

    xsize,xpad = n > 50 ? (250/n,0) : n > 18 ? (5.,1) : n > 12 ? (10.,1) : n > 1 ? (15.,1) : (25.,0)
    ysize,ypad = m > 28 ? (150/m,0) : m > 14 ? (5.,1) : m > 9 ? (10.,1) : m > 1 ? (15.,1) : (25.,0)
    
    write(io,
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
             width="$(n*xsize)mm" height="$(m*ysize)mm"
             shape-rendering="crispEdges">
        """)

    for i in 1:m, j in 1:n
        c = ndims(cs) == 2 ? cs[i, j] : cs[j]
        write(io,
            """
            <rect x="$((j-1)*xsize)mm" y="$((i-1)*ysize)mm"
                  width="$(xsize - xpad)mm" height="$(ysize - ypad)mm"
                  fill="#$(hex(c))" stroke="none" />
            """)
    end

    write(io, "</svg>")
end

