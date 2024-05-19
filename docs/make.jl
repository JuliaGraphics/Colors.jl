using Pkg
dependents = ["ImageCore"] # direct
idependents = ["WebP"] # indirect
devdir = get(ENV, "JULIA_PKG_DEVDIR", nothing) # backup
workdir = joinpath(@__DIR__, "work")
ENV["JULIA_PKG_DEVDIR"] = workdir
Pkg.activate(workdir)
Pkg.develop(dependents, preserve=PRESERVE_DIRECT)
ENV["JULIA_PKG_DEVDIR"] = devdir # restore
for dep in dependents
    Pkg.activate(joinpath(workdir, dep))
    Pkg.compat("Colors", "< 1")
end
Pkg.activate(@__DIR__) # this project
pkgspecs = [PackageSpec(path=joinpath(workdir, dep)) for dep in dependents]
Pkg.develop(pkgspecs, preserve=PRESERVE_DIRECT)
Pkg.add(idependents)

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


Pkg.rm([idependents; dependents], io=devnull)
