using Documenter, Colors

abstract type SVG end
function Base.show(io::IO, mime::MIME"image/svg+xml", svg::SVG)
    write(io, take!(svg.buf))
    flush(io)
end

include("crosssectionalcharts.jl")
include("colordiffcharts.jl")
include("colormaps.jl")
include("namedcolorcharts.jl")
include("sampleimages.jl")


makedocs(
    clean = false,
    modules = [Colors],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
                             size_threshold = nothing,
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
