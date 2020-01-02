using Documenter, Colors

abstract type SVG end
function Base.show(io::IO, mime::MIME"image/svg+xml", svg::SVG)
    write(io, take!(svg.buf))
    flush(io)
end

include("colormaps.jl")
include("namedcolorcharts.jl")


makedocs(
    clean = false,
    modules = [Colors],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                             assets = ["assets/resize_svg.js", "assets/favicon.ico"]),
    sitename = "Colors",
    pages    = Any[
        "Introduction"             => "index.md",
        "Colorspaces"              => "colorspaces.md",
        "Colorscales"              => "colorscales.md",
        "Colormaps"                => "colormaps.md",
        "Named colors"             => "namedcolors.md",
        "References"               => "references.md",
        "Migrating from Color.jl"  => "migratingfromcolor.md",
        "Index"                    => "functionindex.md",
        ]
    )

deploydocs(
    repo = "github.com/JuliaGraphics/Colors.jl.git",
    target = "build")
