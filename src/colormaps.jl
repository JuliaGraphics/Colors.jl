# Support Data for color maps
include("maps_data.jl")

# color scale generation
# ----------------------

@noinline function _generate_lab(l::Float32, c::Float32, h::Float32)
    lab = convert(Lab{Float32}, LCHab{Float32}(l, c, h))
    rgb = xyz_to_linear_rgb(convert(XYZ{Float32}, lab))
    convert(Lab{Float32}, linear_rgb_to_xyz(correct_gamut(rgb)))
end

"""
    colors = distinguishable_colors(n, seed=RGB{N0f8}[];
                                    dropseed=false,
                                    transform=identity,
                                    lchoices=range(0, stop=100, length=15),
                                    cchoices=range(0, stop=100, length=15),
                                    hchoices=range(0, stop=342, length=20))

Generate `n` maximally distinguishable colors.

This uses a greedy brute-force approach to choose `n` colors that are maximally
distinguishable. Given seed color(s), and a set of possible hue, chroma, and
lightness values (in LCHab space), it repeatedly chooses the next color as the
one that maximizes the minimum pairwise distance to any of the colors already
in the palette.

# Arguments

- `n`: Number of colors to generate.
- `seed`: Initial color(s) included in the palette.

# Keyword arguments

- `dropseed`: if true, the `seed` values will be dropped. This provides an easy
  mechanism to ensure that the chosen colors are distinguishable from the seed value(s).
  When true, `n` does not include the seed color(s).
- `transform`: Transform applied to colors before measuring distance. Default is `identity`;
  other choices include `deuteranopic` to simulate color-blindness.
- `lchoices`: Possible lightness values
- `cchoices`: Possible chroma values
- `hchoices`: Possible hue values

Returns a `Vector` of colors of length `n`, of the type specified in `seed`.
"""
function distinguishable_colors(n::Integer,
        @nospecialize(seed::AbstractVector{<:Color});
        dropseed::Bool = false,
        transform::Function = identity,
        lchoices::AbstractVector{<:Real} = range(0.0f0, stop=100.0f0, length=15),
        cchoices::AbstractVector{<:Real} = range(0.0f0, stop=100.0f0, length=15),
        hchoices::AbstractVector{<:Real} = range(0.0f0, stop=342.0f0, length=20))
    if n <= length(seed) && !dropseed
        return seed[1:n]
    end

    # Candidate colors
    N = length(lchoices) * length(cchoices) * length(hchoices)
    candidate = Vector{Lab{Float32}}(undef, N)
    j = 0
    for h in hchoices, c in cchoices, l in lchoices
        @inbounds candidate[j+=1] = _generate_lab(Float32(l), Float32(c), Float32(h))
    end

    _distinguishable_colors(Int(n), seed, dropseed, transform, candidate)
end

function _distinguishable_colors(n::Int,
        @nospecialize(seed::AbstractVector{<:Color}),
        dropseed::Bool,
        @nospecialize(transform::Function),
        candidate::Vector{Lab{Float32}})

    N = length(candidate)
    colors = Vector{eltype(seed)}(undef, n)

    # Transformed colors
    if transform === identity
        candidate_t = candidate
    else
        candidate_t = convert.(Lab{Float32}, transform.(candidate))::Vector{Lab{Float32}}
    end

    # Start with the seed colors, unless `dropseed`
    dropseed || copyto!(colors, seed)

    # Minimum distances of the current color to each previously selected color.
    ds = fill(Inf32, N)
    @inbounds for s in seed
        ts = convert(Lab{Float32}, transform(s))::Lab{Float32}
        for k = 1:N
            ds[k] = @fastmath min(ds[k], colordiff(ts, candidate_t[k]))
        end
    end

    n1 = dropseed ? 1 : length(seed) + 1
    @inbounds for i in n1:n
        j = argmax(ds)
        colors[i] = candidate[j]
        tc = candidate_t[j]
        ds[j] = 0.0f0
        for k = 1:N
            ds[k] == 0.0f0 && continue # already selected
            ds[k] = @fastmath min(ds[k], colordiff(tc, candidate_t[k]))
        end
    end

    return colors
end

distinguishable_colors(n::Integer, seed::Color; kwargs...) = distinguishable_colors(n, [seed]; kwargs...)
distinguishable_colors(n::Integer; kwargs...) = distinguishable_colors(n, Vector{RGB{N0f8}}(); kwargs...)

@deprecate distinguishable_colors(n::Integer,
                                transform::Function,
                                seed::Color,
                                ls::Vector{Float64},
                                cs::Vector{Float64},
                                hs::Vector{Float64})    distinguishable_colors(n, [seed], transform = transform, lchoices = ls, cchoices = cs, hchoices = hs)

"""
    sequential_palette(h, N::Int=100; <keyword arguments>)

Implements the color palette creation technique by
[Wijffelaars, M., et al. (2008)](https://dl.acm.org/doi/10.1111/j.1467-8659.2008.01203.x).

Colormaps are formed using Bézier curves in LCHuv colorspace
with some constant hue. In addition, start and end points can be given
that are then blended to the original hue smoothly.

# Arguments

- `N`        - number of colors
- `h`        - the main hue [0,360]
- `c`        - the overall lightness contrast [0,1]
- `s`        - saturation [0,1]
- `b`        - brightness [0,1]
- `w`        - cold/warm parameter, i.e. the strength of the starting color [0,1]
- `d`        - depth of the ending color [0,1]
- `wcolor`   - starting color (warmness)
- `dcolor`   - ending color (depth)
- `logscale` - `true`/`false` for toggling logspacing
"""
function sequential_palette(h,
                            N::Int=100;
                            w=0.15,
                            d=0.0,
                            c=0.88,
                            s=0.6,
                            b=0.75,
                            wcolor=RGB(1.0, 1.0, 0.0),
                            dcolor=RGB(0.0, 0.0, 1.0),
                            logscale::Bool=false)
    F = Float64
    return _sequential_palette(N, logscale, F(h), F(w), F(d), F(c), F(s), F(b),
                               RGB{F}(wcolor), RGB{F}(dcolor))
end

function _sequential_palette(N, logscale, h, w, d, c, s, b, wcolor, dcolor)
    function mix_hue(h0, h1, w)
        m = normalize_hue(180.0 + h1 - h0) - 180.0
        normalize_hue(h0 + w * m)
    end
    mix_linearly(a::Float64, b::Float64, w) = (1.0 - w) * a + w * b
    mix_linearly(a::LCHuv{Float64}, b::LCHuv{Float64}, w) = weighted_color_mean(w, b, a)

    pstart = convert(LCHuv{Float64}, wcolor)
    pend   = convert(LCHuv{Float64}, dcolor)
    p1 = MSC(h)
    #p0=LCHuv(0,0,h) #original end point

    #multi-hue start point
    p2l = mix_linearly(100.0, pstart.l, w)
    p2h = mix_hue(h, pstart.h, w)
    p2c = min(MSC(p2h, p2l), w * s * pstart.c)
    p2 = LCHuv{Float64}(p2l, p2c, p2h)

    #multi-hue ending point
    p0l = 20.0 * d
    p0h = mix_hue(h, pend.h, d)
    p0c = min(MSC(p0h, p0l), d * s * pend.c)
    p0 = LCHuv{Float64}(p0l, p0c, p0h)

    q0 = mix_linearly(p0, p1, s)
    q2 = mix_linearly(p2, p1, s)
    q1 = mix_linearly(q0, q2, 0.5)

    pal = Vector{LCHuv{Float64}}(undef, N)

    if logscale
        absc = exp10.(range(-2., stop=0., length=N))
    else
        absc = range(0., stop=1., length=N)
    end

    for (i, t) in enumerate(absc)
        u = 1.0 - t

        #Change grid to favor light colors and to be uniform along the curve
        lt = 125.0 - 125.0 * 0.2^mix_linearly(b, u, c)
        tt = inv_bezier(lt, p0.l, p2.l, q0.l, q1.l, q2.l)

        #Get color components from Bezier curves
        ll = bezier(tt, p0.l, p2.l, q0.l, q1.l, q2.l)
        cc = bezier(tt, p0.c, p2.c, q0.c, q1.c, q2.c)
        hh = bezier(tt, p0.h, p2.h, q0.h, q1.h, q2.h)

        @inbounds pal[i] = LCHuv{Float64}(ll, cc, hh)
    end
    # TODO: Decide whether or not to do this conversion in the loop above
    RGB{Float64}.(pal)::Vector{RGB{Float64}}
end

"""
    diverging_palette(h1, h2, N::Int=100; <keyword arguments>)

Create diverging palettes by combining 2 sequential palettes.

# Arguments

- `N`        - number of colors
- `mid`      - the position of the midpoint (0,1)
- `h1`       - the main hue of the first part [0,360]
- `h2`       - the main hue of the latter part [0,360]
- `c`        - the overall lightness contrast [0,1]
- `s`        - saturation [0,1]
- `b`        - brightness [0,1]
- `w`        - cold/warm parameter, i.e. the strength of the starting color [0,1]
- `d1`       - depth of the ending color in the first part [0,1]
- `d2`       - depth of the ending color in the latter part [0,1]
- `wcolor`   - starting color, i.e. the middle color (warmness)
- `dcolor1`  - ending color of the first part (depth)
- `dcolor2`  - ending color of the latter part (depth)
- `logscale` - `true`/`false` for toggling logspacing
"""
function diverging_palette(h1,
                           h2,
                           N::Int=100;
                           mid=0.5,
                           w=0.15,
                           d1=0.0,
                           d2=0.0,
                           c=0.88,
                           s=0.6,
                           b=0.75,
                           wcolor =RGB(1.0, 1.0, 0.0),
                           dcolor1=RGB(1.0, 0.0, 0.0),
                           dcolor2=RGB(0.0, 0.0, 1.0),
                           logscale::Bool=false)
    F = Float64
    return _diverging_palette(N, F(mid), logscale,
                              F(h1), F(h2), F(w), F(d1), F(d2), F(c), F(s), F(b),
                              RGB{F}(wcolor), RGB{F}(dcolor1), RGB{F}(dcolor2))
end
function _diverging_palette(N, mid, logscale, h1, h2, w, d1, d2, c, s, b, wcolor, dcolor1, dcolor2)
    n = isodd(N) ? (N - 1) : N
    N1 = max(ceil(Int, mid * n), 1)
    N2 = Int(max(n - N1, 1))

    pal1 = _sequential_palette(N1 + 1, logscale, h1, w, d1, c, s, b, wcolor, dcolor1)
    pal2 = _sequential_palette(N2 + 1, logscale, h2, w, d2, c, s, b, wcolor, dcolor2)

    if isodd(N)
        midcol = weighted_color_mean(0.5, pal1[1], pal2[1])
        return @views vcat(pal1[end:-1:2], midcol, pal2[2:end])
    else
        return @views vcat(pal1[end:-1:2], pal2[2:end])
    end
end


# Colormap
# ----------------------
# Main function to handle different predefined colormaps
#
"""
    colormap(cname, N=100; logscale=false, <keyword arguments>)

Returns a predefined sequential or diverging colormap computed using
the algorithm by Wijffelaars, M., et al. (2008).

Sequential colormaps `cname` choices are:

- `"Blues"`
- `"Grays"`
- `"Greens"`
- `"Oranges"`
- `"Purples"`
- `"Reds"`

Diverging colormap choices are `"RdBu"`.

Optionally, you can specify the number of colors `N` (default 100).

Extra control is provided by keyword arguments.
- `mid` sets the position of the midpoint for diverging colormaps.
- `logscale=true` uses logarithmically-spaced steps in the colormap.
You can also use keyword argument names that match the argument names in
[`sequential_palette`](@ref) or [`diverging_palette`](@ref).
"""
function colormap(cname::AbstractString, N::Integer=100; kvs...)
    _colormap(String(cname), Int(N), kvs)
end
function _colormap(cname::String, N::Int, kvs)
    logscale = get(kvs, :logscale, false)::Bool
    lcname = lowercase(cname)
    if haskey(colormaps_sequential, lcname)
        pbs = colormaps_sequential[lcname]
        keys_s = (:h, :w, :d, :c, :s, :b, :wcolor, :dcolor)
        for k in keys(kvs)
            k === :logscale && continue
            k in keys_s || throw(ArgumentError("Unknown keyword argument: $k"))
        end
        ps(i) = oftype(pbs[i], get(kvs, keys_s[i], pbs[i]))
        return _sequential_palette(N, logscale, (ps(i) for i in eachindex(pbs))...)
    end
    if haskey(colormaps_diverging, lcname)
        pbd = colormaps_diverging[lcname]
        keys_d = (:h1, :h2, :w, :d1, :d2, :c, :s, :b, :wcolor, :dcolor1, :dcolor2)
        for k in keys(kvs)
            k === :logscale && continue
            k === :mid && continue
            k in keys_d || throw(ArgumentError("Unknown keyword argument: $k"))
        end
        mid = Float64(get(kvs, :mid, 0.5))
        pd(i) = oftype(pbd[i], get(kvs, keys_d[i], pbd[i]))
        params = Tuple(pd(i) for i in eachindex(pbd))::typeof(pbd)
        return _diverging_palette(N, mid, logscale, params...)
    end
    throw(ArgumentError(string("Unknown colormap: ", cname)))
end
