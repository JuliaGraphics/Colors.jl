var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Introduction-1",
    "page": "Introduction",
    "title": "Introduction",
    "category": "section",
    "text": "This library provides a wide array of functions for dealing with color.Supported colorspaces include:RGB, BGR, RGB1, RGB4, RGB24, plus transparent versions ARGB, RGBA, ABGR, BGRA, and ARGB32\nHSV, HSL, HSI, plus all 6 transparent variants (AHSV, HSVA, AHSL, HSLA, AHSI, HSIA)\nXYZ, xyY, LMS and all 6 transparent variants\nLab, Luv, LCHab, LCHuv and all 8 transparent variants\nDIN99, DIN99d, DIN99o and all 6 transparent variants\nStorage formats YIQ, YCbCr and their transparent variants\nGray, Gray24, and the transparent variants AGray, GrayA, and AGray32.You can supply colors using names (eg \"red\") or hex triplets (eg #7aa457)Support is also provided for:color differences\nwhite balance\ncolor deficiency (\"color blindness\")\ncolormaps and colorscales"
},

{
    "location": "colorspaces.html#",
    "page": "Colorspaces",
    "title": "Colorspaces",
    "category": "page",
    "text": ""
},

{
    "location": "colorspaces.html#Colorspaces-1",
    "page": "Colorspaces",
    "title": "Colorspaces",
    "category": "section",
    "text": ""
},

{
    "location": "colorspaces.html#Available-colorspaces-1",
    "page": "Colorspaces",
    "title": "Available colorspaces",
    "category": "section",
    "text": "The colorspaces used by Colors are defined in ColorTypes. Briefly, the defined spaces are:Red-Green-Blue spaces: RGB, BGR, RGB1, RGB4, RGB24, plus transparent versions ARGB, RGBA, ABGR, BGRA, and ARGB32.\nHSV, HSL, HSI, plus all 6 transparent variants (AHSV, HSVA, AHSL, HSLA, AHSI, HSIA)\nXYZ, xyY, LMS and all 6 transparent variants\nLab, Luv, LCHab, LCHuv and all 8 transparent variants\nDIN99, DIN99d, DIN99o and all 6 transparent variants\nStorage formats YIQ, YCbCr and their transparent variants\nGray, Gray24, and the transparent variants AGray, GrayA, and AGray32."
},

{
    "location": "colorspaces.html#Converting-colors-1",
    "page": "Colorspaces",
    "title": "Converting colors",
    "category": "section",
    "text": "Colors.jl allows you to convert from one colorspace to another using the convert function.For example:convert(RGB, HSL(270, 0.5, 0.5))Depending on the source and destination colorspace, this may not be perfectly lossless."
},

{
    "location": "colorspaces.html#Color-Parsing-1",
    "page": "Colorspaces",
    "title": "Color Parsing",
    "category": "section",
    "text": "julia> c = colorant\"red\"\nRGB{N0f8}(1.0, 0.0, 0.0)\n\njulia> parse(Colorant, \"red\")\nRGB{N0f8}(1.0, 0.0, 0.0)\n\njulia> parse(Colorant, HSL(1, 1, 1))\nHSL{Float32}(1.0f0, 1.0f0, 1.0f0)\n\njulia> colorant\"#FF0000\"\nRGB{N0f8}(1.0, 0.0, 0.0)\n\njulia> parse(Colorant, RGBA(1, 0.5, 1, 0.5))\nRGBA{Float64}(1.0, 0.5, 1.0, 0.5)You can parse any CSS color specification with the exception of currentColor.All CSS/SVG named colors are supported, in addition to X11 named colors, when their definitions do not clash with SVG.Returns a RGB{U8} color, unless:\"hsl(h, s, l)\" was used, in which case an HSL color is returned\n\"rgba(r, g, b, a)\" was used, in which case an RGBA color is returned\n\"hsla(h, s, l, a)\" was used, in which case an HSLA color is returned\na specific Colorant type was specified in the first argumentWhen writing functions the colorant\"red\" version is preferred, because the slow step runs when the code is parsed (i.e., during compilation rather than run-time).[need docstrings too?]@colorant_str\nhex\nparse"
},

{
    "location": "colorspaces.html#Colors.colormatch",
    "page": "Colorspaces",
    "title": "Colors.colormatch",
    "category": "function",
    "text": "colormatch(wavelength)\ncolormatch(matchingfunction, wavelength)\n\nEvaluate the CIE standard observer color match function.\n\nArgs:\n\nmatchingfunction (optional): a type used to specify the matching function. Choices include CIE1931_CMF (the default, the CIE 1931 2° matching function), CIE1964_CMF (the CIE 1964 10° color matching function), CIE1931J_CMF (Judd adjustment to CIE1931_CMF), CIE1931JV_CMF (Judd-Vos adjustment to CIE1931_CMF).\nwavelen: Wavelength of stimulus in nanometers.\n\nReturns:   XYZ value of perceived color.\n\n\n\n\n\n"
},

{
    "location": "colorspaces.html#Color-match-for-CIE-Standard-Observer-1",
    "page": "Colorspaces",
    "title": "Color match for CIE Standard Observer",
    "category": "section",
    "text": "The colormatch() function returns an XYZ color corresponding to a wavelength specified in nanometers.colormatch(wavelen::Real)The CIE defines a standard observer, defining a typical frequency response curve for each of the three human eye cones.colormatch"
},

{
    "location": "colorspaces.html#Colors.whitebalance",
    "page": "Colorspaces",
    "title": "Colors.whitebalance",
    "category": "function",
    "text": "whitebalance(c, src_white, ref_white)\n\nWhitebalance a color.\n\nInput a source (adopted) and destination (reference) white. E.g., if you have a photo taken under florencent lighting that you then want to appear correct under regular sunlight, you might do something like whitebalance(c, WP_F2, WP_D65).\n\nArgs:\n\nc: An observed color.\nsrc_white: Adopted or source white corresponding to c\nref_white: Reference or destination white.\n\nReturns:   A whitebalanced color.\n\n\n\n\n\n"
},

{
    "location": "colorspaces.html#Chromatic-Adaptation-(white-balance)-1",
    "page": "Colorspaces",
    "title": "Chromatic Adaptation (white balance)",
    "category": "section",
    "text": "The whitebalance() function converts a color according to a reference white point.whitebalance{T <: Color}(c::T, src_white::Color, ref_white::Color)Convert a color c viewed under conditions with a given source whitepoint src_whitepoint to appear the same under different conditions specified by a reference whitepoint ref_white.whitebalance"
},

{
    "location": "colorspaces.html#Color-Difference-1",
    "page": "Colorspaces",
    "title": "Color Difference",
    "category": "section",
    "text": "The colordiff() function gives an approximate value for the difference between two colors.julia> colordiff(colorant\"red\", parse(Colorant, HSB(360, 0.75, 1)))\n8.178248292426845colordiff(a::Color, b::Color)Evaluate the CIEDE2000 color difference formula. This gives an approximate measure of the perceptual difference between two colors to a typical viewer. A larger number is returned for increasingly distinguishable colors.colordiff(a::Color, b::Color, m::DifferenceMetric)Evaluate the color difference formula specified by the supplied DifferenceMetric.Options are as follows:Option Action\nDE_2000(kl::Float64, kc::Float64, kh::Float64) Specify the color difference using the recommended CIEDE2000 equation, with weighting parameters kl, kc, and kh as provided for in the recommendation.\nDE_2000() - when not provided, these parameters default to 1.\nDE_94(kl::Float64, kc::Float64, kh::Float64) Specify the color difference using the recommended CIEDE94 equation, with weighting parameters kl, kc, and kh as provided for in the recommendation.\nDE_94() - hen not provided, these parameters default to 1.\nDE_JPC79() Specify McDonald\'s \"JP Coates Thread Company\" color difference formula.\nDE_CMC(kl::Float64, kc::Float64) Specify the color difference using the CMC equation, with weighting parameters kl and kc.\nDE_CMC() - when not provided, these parameters default to 1.\nDE_BFD(wp::XYZ, kl::Float64, kc::Float64) Specify the color difference using the BFD equation, with weighting parameters kl and kc. Additionally, a white point can be specified, because the BFD equation must convert between XYZ and LAB during the computation.\nDE_BFD(kl::Float64, kc::Float64) \nDE_BFD() - when not specified, the constants default to 1, and the white point defaults to CIED65.\nDE_AB() Specify the original, Euclidean color difference equation.\nDE_DIN99() Specify the Euclidean color difference equation applied in the DIN99 uniform colorspace.\nDE_DIN99d() Specify the Euclidean color difference equation applied in the DIN99d uniform colorspace.\nDE_DIN99o() Specify the Euclidean color difference equation applied in the DIN99o uniform colorspace.[need docstrings?]colordiff\nDE_2000\nDE_94\nDE_JPC79\nDE_CMC\nDE_BFD\nDE_AB\nDE_DIN99\nDE_DIN99d\nDE_DIN99o\nMSC\nCIE1931_CMF\nCIE1964_CMF\nCIE1931J_CMF\nCIE1931JV_CMF"
},

{
    "location": "colorspaces.html#Colors.protanopic",
    "page": "Colorspaces",
    "title": "Colors.protanopic",
    "category": "function",
    "text": "protanopic(c)\nprotanopic(c, p)\n\nConvert a color to simulate protanopic color deficiency (lack of the long-wavelength photopigment).  c is the input color; the optional argument p is the fraction of photopigment loss, in the range 0 (no loss) to 1 (complete loss).\n\n\n\n\n\n"
},

{
    "location": "colorspaces.html#Colors.deuteranopic",
    "page": "Colorspaces",
    "title": "Colors.deuteranopic",
    "category": "function",
    "text": "deuteranopic(c)\ndeuteranopic(c, p)\n\nConvert a color to simulate deuteranopic color deficiency (lack of the middle-wavelength photopigment).  See the description of protanopic for detail about the arguments.\n\n\n\n\n\n"
},

{
    "location": "colorspaces.html#Colors.tritanopic",
    "page": "Colorspaces",
    "title": "Colors.tritanopic",
    "category": "function",
    "text": "tritanopic(c)\ntritanopic(c, p)\n\nConvert a color to simulate tritanopic color deficiency (lack of the short-wavelength photogiment).  See protanopic for more detail about the arguments.\n\n\n\n\n\n"
},

{
    "location": "colorspaces.html#Simulation-of-color-deficiency-(\"color-blindness\")-1",
    "page": "Colorspaces",
    "title": "Simulation of color deficiency (\"color blindness\")",
    "category": "section",
    "text": "Three functions are provided that map colors to a reduced gamut to simulate different types of dichromacy, the loss of one of the three types of human photopigments.Protanopia, deuteranopia, and tritanopia are the loss of long, middle, and short wavelength photopigment, respectively.These functions take a color and return a new, altered color in the same colorspace.protanopic(c::Color, p::Float64)\ndeuteranopic(c::Color, p::Float64)\ntritanopic(c::Color, p::Float64)Also provided are versions of these functions with an extra parameter p in [0, 1], giving the degree of photopigment loss, where 1.0 is a complete loss, and 0.0 is no loss at all.protanopic\ndeuteranopic\ntritanopic"
},

{
    "location": "colorscales.html#",
    "page": "Colorscales",
    "title": "Colorscales",
    "category": "page",
    "text": ""
},

{
    "location": "colorscales.html#Color-Scales-1",
    "page": "Colorscales",
    "title": "Color Scales",
    "category": "section",
    "text": ""
},

{
    "location": "colorscales.html#Colors.distinguishable_colors",
    "page": "Colorscales",
    "title": "Colors.distinguishable_colors",
    "category": "function",
    "text": "distinguishable_colors(n, [seed]; [transform, lchoices, cchoices, hchoices])\n\nGenerate n maximally distinguishable colors.\n\nThis uses a greedy brute-force approach to choose n colors that are maximally distinguishable. Given seed color(s), and a set of possible hue, chroma, and lightness values (in LCHab space), it repeatedly chooses the next color as the one that maximizes the minimum pairwise distance to any of the colors already in the palette.\n\nArgs:\n\nn: Number of colors to generate.\nseed: Initial color(s) included in the palette.  Default is Vector{RGB{N0f8}}(0).\n\nKeyword arguments:\n\ntransform: Transform applied to colors before measuring distance. Default is the identity; other choices include deuteranopic to simulate color-blindness.\nlchoices: Possible lightness values (default range(0,stop=100,start=15))\ncchoices: Possible chroma values (default range(0,stop=100,start=15))\nhchoices: Possible hue values (default range(0,stop=340,start=20))\n\nReturns:   A Vector of colors of length n, of the type specified in seed.\n\n\n\n\n\n"
},

{
    "location": "colorscales.html#Generating-distinguishable-colors-1",
    "page": "Colorscales",
    "title": "Generating distinguishable colors",
    "category": "section",
    "text": "distinguishable_colors(n::Integer,seed::Color)\ndistinguishable_colors{T<:Color}(n::Integer,seed::AbstractVector{T})Generate n maximally distinguishable colors in LCHab space.A seed color or array of seed colors may be provided to distinguishable_colors, and the remaining colors will be chosen to be maximally distinguishable from the seed colors and each other.distinguishable_colors{T<:Color}(n::Integer, seed::AbstractVector{T};\n    transform::Function = identity,\n    lchoices::AbstractVector = range(0, stop=100, length=15),\n    cchoices::AbstractVector = range(0, stop=100, length=15),\n    hchoices::AbstractVector = range(0, stop=340, length=20)\n)By default, distinguishable_colors chooses maximally distinguishable colors from the outer product of lightness, chroma, and hue values specified by lchoices = range(0, stop=100, length=15), cchoices = range(0, stop=100, length=15), and hchoices = range(0, stop=340, length=20). The set of colors that distinguishable_colors chooses from may be specified by passing different choices as keyword arguments.Distinguishability is maximized with respect to the CIEDE2000 color difference formula (see colordiff in Colorspaces). If a transform function is specified, color difference is instead maximized between colors a and b according to colordiff(transform(a), transform(b)).Color arrays generated by distinguishable_colors are particularly useful for improving the readability of multiple trace plots. Here\'s an example using PyPlot:using PyPlot, Colors\nvars = 1:10\ncols = distinguishable_colors(length(vars)+1, [RGB(1,1,1)])[2:end]\npcols = map(col -> (red(col), green(col), blue(col)), cols)\nfor i = 1:length(vars)\n    plot(1:10, rand(10), c = pcols[i])\nend\nlegend(vars, loc=\"upper right\", bbox_to_anchor=[1.1, 1.])(Image: pyplot seed ex)To ensure that the generated colors stand out against the default white background, white (RGB(1,1,1)) was used as a seed to distinguishable_colors(), then dropped from the resulting array with [2:end].distinguishable_colors"
},

{
    "location": "colorscales.html#Generating-a-range-of-colors-1",
    "page": "Colorscales",
    "title": "Generating a range of colors",
    "category": "section",
    "text": "The range() function has a method that accepts colors:range(start::Color; stop::Color, length=100)Generates n colors in a linearly interpolated ramp from start to stop, inclusive, returning an Array of colors.julia> c1 = colorant\"red\"\nRGB{N0f8}(1.0,0.0,0.0)\n\njulia> c2 = colorant\"green\"\nRGB{N0f8}(0.0,0.502,0.0)\n\njulia> range(c1, stop=c2, length=43)\n43-element Array{RGB{N0f8},1} with eltype RGB{FixedPointNumbers.Normed{UInt8,8}}:\n RGB{N0f8}(1.0,0.0,0.0)    \n RGB{N0f8}(0.976,0.012,0.0)\n RGB{N0f8}(0.953,0.024,0.0)\n RGB{N0f8}(0.929,0.035,0.0)\n RGB{N0f8}(0.906,0.047,0.0)\n ⋮                         \n RGB{N0f8}(0.094,0.455,0.0)\n RGB{N0f8}(0.071,0.467,0.0)\n RGB{N0f8}(0.047,0.478,0.0)\n RGB{N0f8}(0.024,0.49,0.0)\n RGB{N0f8}(0.0,0.502,0.0)  "
},

{
    "location": "colorscales.html#Colors.weighted_color_mean",
    "page": "Colorscales",
    "title": "Colors.weighted_color_mean",
    "category": "function",
    "text": "weighted_color_mean(w1, c1, c2)\n\nReturns the color w1*c1 + (1-w1)*c2 that is the weighted mean of c1 and c2, where c1 has a weight 0 ≤ w1 ≤ 1.\n\n\n\n\n\n"
},

{
    "location": "colorscales.html#Weighted-color-means-1",
    "page": "Colorscales",
    "title": "Weighted color means",
    "category": "section",
    "text": "weighted_color_mean(w1::Real, c1::Color, c2::Color)Returns a color that is the weighted mean of c1 and c2, where c1 has a weight 0 ≤ w1 ≤ 1.julia> weighted_color_mean(0.5, colorant\"red\", colorant\"green\")\nRGB{N0f8}(0.502,0.251,0.0)weighted_color_mean"
},

{
    "location": "colorscales.html#Most-saturated-color-1",
    "page": "Colorscales",
    "title": "Most saturated color",
    "category": "section",
    "text": "MSC(h)Returns the most saturated color for a given hue h (defined in LCHuv space, i.e. in range [0, 360]). Optionally the lightness l can also be given, as MSC(h, l). The function calculates the color by finding the edge of the LCHuv space for a given angle (hue)."
},

{
    "location": "colormaps.html#",
    "page": "Colormaps",
    "title": "Colormaps",
    "category": "page",
    "text": ""
},

{
    "location": "colormaps.html#Colormaps-1",
    "page": "Colormaps",
    "title": "Colormaps",
    "category": "section",
    "text": "This package provides some pre-defined colormaps (described below). There are also several other packages which provide colormaps:PerceptualColourMaps\nColorBrewer\nColorSchemes.jl\nNoveltyColors"
},

{
    "location": "colormaps.html#Predefined-sequential-and-diverging-colormaps-1",
    "page": "Colormaps",
    "title": "Predefined sequential and diverging colormaps",
    "category": "section",
    "text": "colormap(cname::String [, N::Int=100; mid=0.5, logscale=false, kvs...])Returns a predefined sequential or diverging colormap computed using the algorithm by Wijffelaars, M., et al. (2008).The optional arguments are:the number of colors N\nposition of the middle point mid\nthe use of logarithmic scaling with the logscale keywordColormaps computed by this algorithm are guaranteed to have an increasing perceived depth or saturation making them ideal for data visualization. This also means that they are (in most cases) color-blind friendly and suitable for black-and-white printing.The currently supported colormap names are:"
},

{
    "location": "colormaps.html#Sequential-1",
    "page": "Colormaps",
    "title": "Sequential",
    "category": "section",
    "text": "Name Example\nBlues (Image: Blues)\nGreens (Image: Greens)\nGrays \nOranges (Image: Oranges)\nPurples (Image: Purples)\nReds (Image: Reds)"
},

{
    "location": "colormaps.html#Colors.colormap",
    "page": "Colormaps",
    "title": "Colors.colormap",
    "category": "function",
    "text": "colormap(cname, [N; mid, logscale, kvs...])\n\nReturns a predefined sequential or diverging colormap computed using the algorithm by Wijffelaars, M., et al. (2008).  Sequential colormaps cname choices are Blues, Greens, Grays, Oranges, Purples, and Reds.  Diverging colormap choices are RdBu.  Optionally, you can specify the number of colors N (default 100). Keyword arguments include the position of the middle point mid (default 0.5) and the possibility to switch to log scaling with logscale (default false).\n\n\n\n\n\n"
},

{
    "location": "colormaps.html#Diverging-1",
    "page": "Colormaps",
    "title": "Diverging",
    "category": "section",
    "text": "Name Example\nRdBu (from red to blue) (Image: RdBu)colormap"
},

{
    "location": "colormaps.html#Sequential-and-diverging-color-palettes-1",
    "page": "Colormaps",
    "title": "Sequential and diverging color palettes",
    "category": "section",
    "text": "You can create your own color palettes by using sequential_palette():sequential_palette(h, [N::Int=100; c=0.88, s=0.6, b=0.75, w=0.15, d=0.0, wcolor=RGB(1,1,0), dcolor=RGB(0,0,1), logscale=false])which creates a sequential map for a hue h (defined in LCHuv space).Other possible parameters that you can fine tune are:N - number of colors\nc - the overall lightness contrast [0,1]\ns - saturation [0,1]\nb - brightness [0,1]\nw - cold/warm parameter, i.e. the strength of the starting color [0,1]\nd - depth of the ending color [0,1]\nwcolor - starting color (usually defined to be yellow)\ndcolor - ending color (depth)\nlogscale - true/false for toggling logspacingTwo sequential maps can also be combined into a diverging colormap by using:diverging_palette(h1, h2 [, N::Int=100; mid=0.5,c=0.88, s=0.6, b=0.75, w=0.15, d1=0.0, d2=0.0, wcolor=RGB(1,1,0), dcolor1=RGB(1,0,0), dcolor2=RGB(0,0,1), logscale=false])where the arguments are:h1 - the main hue of the left side [0,360]\nh2 - the main hue of the right side [0,360]and the optional arguments are:N - number of colors\nc - the overall lightness contrast [0,1]\ns - saturation [0,1]\nb - brightness [0,1]\nw - cold/warm parameter, i.e. the strength of the middle color [0,1]\nd1 - depth of the end color in the left side [0,1]\nd2 - depth of the end color in the right side [0,1]\nwcolor - starting color i.e. the middle color (warmness, usually defined to be yellow)\ndcolor1 - end color of the left side (depth)\ndcolor2 - end color of the right side (depth)\nlogscale - true/false for toggling logspacingsequential_palette\ndiverging_palette"
},

{
    "location": "namedcolors.html#",
    "page": "Named colors",
    "title": "Named colors",
    "category": "page",
    "text": ""
},

{
    "location": "namedcolors.html#Named-colors-1",
    "page": "Named colors",
    "title": "Named colors",
    "category": "section",
    "text": "The names of available colors are stored in alphabetical order in the dictionary Colors.color_names:color_names = Dict(\n    \"aliceblue\"            => (240, 248, 255),\n    \"antiquewhite\"         => (250, 235, 215),\n    \"antiquewhite1\"        => (255, 239, 219),\n    ...(Image: Reds)(Image: Oranges)(Image: Yellows)(Image: Greens)(Image: Greens)(Image: Blues)(Image: Purples)(Image: Browns)(Image: Pinks)(Image: Whites)(Image: Grays)"
},

{
    "location": "references.html#",
    "page": "References",
    "title": "References",
    "category": "page",
    "text": ""
},

{
    "location": "references.html#References-1",
    "page": "References",
    "title": "References",
    "category": "section",
    "text": "What perceptually uniform colorspaces are and why you should be using them:Ihaka, R. (2003). Colour for Presentation Graphics. In K Hornik, F Leisch, A Zeileis (eds.),  Proceedings of the 3rd International Workshop on Distributed Statistical Computing, Vienna, Austria. ISSN 1609-395X\nZeileis, A., Hornik, K., and Murrell, P. (2009). Escaping RGBland: Selecting colors for statistical graphics. Computational Statistics and Data Analysis, 53(9), 3259–3270. doi:10.1016/j.csda.2008.11.033Functions in this library were mostly implemented according to:Schanda, J., ed. Colorimetry: Understanding the CIE system. Wiley-Interscience, 2007.\nSharma, G., Wu, W., and Dalal, E. N. (2005). The CIEDE2000 color‐difference formula: Implementation notes, supplementary test data, and mathematical observations. Color Research & Application, 30(1), 21–30. doi:10.1002/col\nIhaka, R., Murrel, P., Hornik, K., Fisher, J. C., and Zeileis, A. (2013). colorspace: Color Space Manipulation. R package version 1.2-1.\nLindbloom, B. (2013). Useful Color Equations\nWijffelaars, M., Vliegen, R., van Wijk, J., van der Linden, E-J. (2008). Generating Color Palettes using Intuitive Parameters\nGeorg A. Klein Industrial Color Physics. Springer Series in Optical Sciences, 2010. ISSN 0342-4111, ISBN 978-1-4419-1197-1."
},

{
    "location": "migratingfromcolor.html#",
    "page": "Migrating from Color.jl",
    "title": "Migrating from Color.jl",
    "category": "page",
    "text": ""
},

{
    "location": "migratingfromcolor.html#Migrating-from-Color.jl-1",
    "page": "Migrating from Color.jl",
    "title": "Migrating from Color.jl",
    "category": "section",
    "text": "Colors.jl was forked from an original repository called Color.jl created by Daniel Jones.The following script can be helpful if you intending to migrate from Color.jl to Colors.jl.# Intended to be run from the top directory in a package\n# Do not run this twice on the same source tree without discarding\n# the first set of changes.\nsed -i \'s/\\bColor\\b/Colors/g\' REQUIRE\n\nfls=$(find . -name \"*.jl\")\nsed -i \'s/\\bColor\\b/Colors/g\' $fls               # Color -> Colors\nsed -i -r \'s/\\bcolor\\(\"(.*?)\"\\)/colorant\\\"\\1\\\"/g\' $fls   # color(\"red\") -> colorant\"red\"\nsed -i \'s/AbstractAlphaColorValue/TransparentColor/g\' $fls\nsed -i \'s/AlphaColorValue/TransparentColor/g\' $fls   # might mean ColorAlpha\nsed -i \'s/ColorValue/Color/g\' $fls\nsed -i \'s/ColourValue/Color/g\' $fls\nsed -i -r \'s/\\bLAB\\b/Lab/g\' $fls\nsed -i -r \'s/\\bLUV\\b/Luv/g\' $fls\nsed -i -r \'s/\\b([a-zA-Z0-9_\\.]+)\\.c\\.(\\w)\\b/\\1\\.\\2/g\' $fls      # colval.c.r -> colval.c\n# This next one is quite dangerous, esp. for LCHab types...\n# ...on the other hand, git diff is nice about showing the things we should fix\nsed -i -r \'s/\\b([a-zA-Z0-9_\\.]+)\\.c\\b/color(\\1)/g\' $fls\n\n# These are not essential, but they generalize to RGB24 better\n# However, they are too error-prone to use by default since other color\n# types like Lab have fields with the same names\n#sed -i -r \'s/\\b([a-zA-Z0-9_\\.]+)\\.r\\b/red(\\1)/g\' $fls          # c.r -> red(c)\n#sed -i -r \'s/\\b([a-zA-Z0-9_\\.]+)\\.g\\b/green(\\1)/g\' $fls\n#sed -i -r \'s/\\b([a-zA-Z0-9_\\.]+)\\.b\\b/blue(\\1)/g\' $fls\n#sed -i -r \'s/\\b([a-zA-Z0-9_\\.]+)\\.alpha\\b/alpha(\\1)/g\' $fls     # c.alpha -> alpha(c)You are strongly advised to check the results carefully; for example, any object obj with a field named c will get converted from obj.c to color(obj), and if obj is not a Colorant this is surely not what you want.  You can use git add -p to review/edit each change individually."
},

{
    "location": "functionindex.html#",
    "page": "Index",
    "title": "Index",
    "category": "page",
    "text": ""
},

{
    "location": "functionindex.html#Index-1",
    "page": "Index",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
