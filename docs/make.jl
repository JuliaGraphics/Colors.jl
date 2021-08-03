using Documenter, Colors

abstract type SVG end
function Base.show(io::IO, ::MIME"text/html", svg::SVG)
    write(io, "<html><body>")
    write(io, take!(svg.buf))
    write(io, "</body></html>")
    flush(io)
end
include("png16x16.jl")
include("crosssectionalcharts.jl")
include("colordiffcharts.jl")
include("colormaps.jl")
include("colormapparams.jl")
include("namedcolorcharts.jl")
include("sampleimages.jl")


makedocs(
    clean = false,
    modules = [Colors],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                             assets = ["assets/resize_svg.js", "assets/favicon.ico"]),
    checkdocs = :exports,
    sitename = "Colors",
    pages    = Any[
        "Introduction"                => "index.md",
        "Construction and Conversion" => "constructionandconversion.md",
        "Color Differences"           => "colordifferences.md",
        "Colormaps and Colorscales"   => "colormapsandcolorscales.md",
        "Named Colors"                => "namedcolors.md",
        "Advanced Functions"          => "advancedfunctions.md",
        "References"                  => "references.md",
        "Index"                       => "functionindex.md",
        ]
    )

deploydocs(
    repo = "github.com/JuliaGraphics/Colors.jl.git",
    target = "build")
