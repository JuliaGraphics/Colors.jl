using Documenter, Colors

makedocs(
    modules = [Colors],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
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
