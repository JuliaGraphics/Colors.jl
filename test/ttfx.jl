function report_de2000(io::IO, colors)
    d_max = 0.0f0
    p_max = (first(colors), first(colors))

    for c1 in colors, c2 in colors
        d = colordiff(c1, c2)
        if d > d_max
            d_max = d
            p_max = (c1, c2)
        end
    end

    println(io, "The pair with the largest color difference:")
    println(io, collect(p_max))
    println(io, "ΔE₀₀: $d_max")
    return
end

strs = ["royalblue" "rgb(22%, 59.6%, 14.9%)"
        "rgb(149, 88, 178)" "#CB3C33"]

iob = IOBuffer()
report_de2000(iob, parse.(RGB, strs))
