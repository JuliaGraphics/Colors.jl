
module CrossSectionalCharts

using Colors
using Base64

struct CrossSectionalChartSVG <: Main.SVG
    buf::IOBuffer
end

struct Axis
    index::Int # compornent index
    label::String
    range::AbstractRange
end
Base.first(a::Axis) = first(a.range)
Base.last(a::Axis) = last(a.range)

function crosssection(::Type{C};
                      x::Tuple=(1, "X", 0:1),
                      y::Tuple=(2, "Y", 0:1),
                      z::Tuple=(3, "Z", 0:1)) where C <: Color
    crosssection(C, Axis(x...), Axis(y...), Axis(z...))
end
function crosssection(::Type{C}, x::Axis, y::Axis, z::Axis) where C <: Color
    io = IOBuffer()
    id = String(nameof(C))

    write(io,
        """
        <svg xmlns="http://www.w3.org/2000/svg"
             xmlns:xlink="http://www.w3.org/1999/xlink"
             id="svg_$id" version="1.1"
             viewBox="0 0 40 30" width="27.09mm" height="20.32mm"
             stroke="none" style="display:inline; margin-left:2em; margin-bottom:1em">
        <defs>
        <filter id="filter_g_$id" filterUnits="userSpaceOnUse" x="0" y="-0.5" width="15.5" height="16">
          <feGaussianBlur stdDeviation="0.1" result="blur"/>
          <feMerge>
            <feMergeNode in="SourceGraphic"/>
            <feMergeNode in="blur"/>
          </feMerge>
        </filter>
        <style type="text/css"><![CDATA[
          #svg_$id g, #svg_$id image {
            transition: all 400ms ease 200ms;
          }
          #svg_$id path.b {
            stroke: currentColor;
            stroke-width: 0.5;
            opacity: 0;
            transition: all 200ms ease 0ms;
          }
          #svg_$id image {
            opacity: 0;
            filter:url(#filter_g_$id);
          }
          #svg_$id rect:active ~ image {
            opacity: 1;
            transition: all 200ms ease 0ms;
          }
          #svg_$id rect:hover ~ image {
            opacity: 1;
            transition: all 200ms ease 0ms;
          }
          #svg_$id rect:active ~ path.b {
            opacity: 0.8;
          }
          #svg_$id rect:hover ~ path.b {
            opacity: 0.8;
          }
          #svg_$id text {
            fill: currentColor;
            fill-opacity: 0.8;
            stroke: #aaa;
            stroke-width: 0.2;
            stroke-opacity: 0.4;
            font-size: 3px;
          }
          #svg_$id text.n {
            opacity:0;
          }
          #svg_$id:hover text.n {
            opacity:1;
          }
          #svg_$id:active text.n {
            opacity:1;
          }
        ]]></style>
        </defs>
        """)

    xs = [xv for xv in range(first(x), stop=last(x), length=16)]
    ys = [yv for yv in range(last(y), stop=first(y), length=16)]
    zs = [zv for zv in range(first(z), stop=last(z), length=11)]
    xmidf = (first(x) + last(x)) * 0.5
    ymidf = (first(y) + last(y)) * 0.5
    xmid = isinteger(xmidf) ? Int(xmidf) : xmidf
    ymid = isinteger(ymidf) ? Int(ymidf) : ymidf

    vec = [0.0, 0.0, 0.0]
    function col(xv, yv, zv)
        vec[x.index] = xv
        vec[y.index] = yv
        vec[z.index] = zv
        # TODO: Add more appropriate out-of-gamut color handling
        xyz = convert(XYZ, C(vec...))
        rgb = convert(RGB, XYZ(max(xyz.x,0), max(xyz.y,0), max(xyz.z,0)))
    end

    # add swatches of color bar and planes by layer
    for i = 1:11
        zi = isodd(i) ? 6 - i÷2 : 6 + i÷2 # zigzag order
        plane = [col(xs[xi], ys[yi], zs[zi]) for yi = 1:16, xi = 1:16]
        ccolor = col(xmid, ymid, zs[zi]) # center color (for color bar)
        barh = i == 1 ? 30 : 16.5 - 3*(i÷2)
        op = i == 1 ? "style=\"opacity:1;\"" : ""
        write(io,
            """
            <g>
              <rect fill="#$(hex(ccolor))" width="4" height="$(barh)" x="36" y="$(isodd(i) ? 30 - barh : 0)" />
              <image width="16" height="16" transform="scale(2) translate(-.5,0)" $op xlink:href="data:image/png;base64,""")
        b64enc = Base64EncodePipe(io)
        write_png(b64enc, plane)
        close(b64enc)
        write(io, "\" />\n")
        write(io,
            """
              <path d="m35,$(33-3zi) h 5" class="b"/>
            </g>
            """)
    end
    # add labels
    if first(x.range) * last(x.range) < 0
        write(io,
            """
            <path d="M0,15 h30 M15,0 v30" style="stroke:currentColor;stroke-width:0.125"/>
            <text x="29.5" y="14" style="text-anchor:end;">$(x.label)</text>
            <text x="29.5" y="18" style="text-anchor:end;" class="n">$(last(x))</text>
            <text x="16" y="3" style="text-anchor:start;">$(y.label)</text>
            <text x="14" y="3" style="text-anchor:end;" class="n">$(last(y))</text>
            <text x="14" y="18" style="text-anchor:end;" class="n">0</text>
            """)
    else
        write(io,
            """
            <text x="29.5" y="26" style="text-anchor:end;">$(x.label)</text>
            <text x="29.5" y="29" style="text-anchor:end;" class="n">$(last(x))</text>
            <text x="15" y="29" style="text-anchor:middle;" class="n">$xmid</text>
            <text x="6" y="3" style="text-anchor:start;">$(y.label)</text>
            <text x="0.5" y="3" style="text-anchor:start;" class="n">$(last(y))</text>
            <text x="0.5" y="16" style="text-anchor:start;" class="n">$ymid</text>
            <text x="0.5" y="29" style="text-anchor:start;" class="n">0</text>
            """)
    end
    write(io,
        """
        <text style="text-anchor:middle;" transform="translate(35,15) rotate(-90)">$(z.label)</text>
        <text x="36" y="3" style="text-anchor:end;" class="n">$(last(z))</text>
        <text x="36" y="29" style="text-anchor:end;" class="n">$(first(z))</text>
        <text x="2" y="26" style="fill:#fff;fill-opacity:1;text-anchor:start;">$id</text>
        <path d="m0,0 h40 v30 h-40 z" style="fill:none;stroke:none;" />
        </svg>""")
    CrossSectionalChartSVG(io)
end


function write_png(io::IO, cs::AbstractArray{T}) where T <: Color
    buf = IOBuffer() # to calculate chunk CRCs
    n = 16 # 16 x 16
    u8(x) = write(buf, UInt8(x & 0xFF))
    u16(x) = (u8((x & 0xFFFF)>>8); u8(x))
    u32(x) = (u16((x & 0xFFFFFFFF)>>16); u16(x))
    b(bstr) = write(buf, bstr)
    function palette(c::Color)
        rgb24 = convert(RGB24,c)
        u8(rgb24.color>>16); u8(rgb24.color>>8); u8(rgb24.color)
    end
    crct(x) = (for i = 1:8; x = x & 1==1 ? 0xEDB88320 ⊻ (x>>1) : x>>1 end; x)
    table = UInt32[crct(i) for i = 0x00:0xFF]
    function crc32()
        seekstart(buf)
        crc = 0xFFFFFFFF
        while !eof(buf)
            crc = (crc>>8) ⊻ table[(crc&0xFF) ⊻ read(buf, UInt8) + 1]
        end
        u32(crc ⊻ 0xFFFFFFFF)
    end
    flush() = write(io, take!(seekstart(buf)))

    # The following is a pre-encoded 256-indexed-color PNG with size of 16x16.
    # We only rewrite "pallets".
    b(b"\x89PNG\x0D\x0A\x1A\x0A")
    # Image header
    u32(13); flush(); b(b"IHDR"); u32(n); u32(n); u8(8); u8(3); u8(0); u8(0); u8(0); crc32()
    # Palette
    u32(n * n * 3); flush();
    b(b"PLTE")
    for y = 1:n, x = 1:n
        palette(cs[y,x])
    end
    crc32()
    # Image data
    u32(58); flush(); b(b"IDAT")
    b(b"\x78\xDA\x63\x64\x60\x44\x03\x02\xE8\x02\x0A\xE8\x02\x06\xE8\x02")
    b(b"\x0E\xE8\x02\x01\xE8\x02\x09\xE8\x02\x05\xE8\x02\x0D\xE8\x02\x13")
    b(b"\xD0\x05\x16\xA0\x0B\x6C\x40\x17\x38\x80\x2E\x70\x01\x5D\xE0\x01")
    b(b"\xBA\xC0\x07\x34\x3E\x00\x54\x4D\x08\x81"); crc32()
    # Image trailer
    u32(0); flush(); b(b"IEND"); crc32()
    flush()
end

"""
# Image data
using CodecZlib
raw = IOBuffer()
for y = 0:15
    write(raw, UInt8(1)) # filter: SUB
    write(raw, UInt8(y*16)) # line head
    write(raw, UInt8[1 for i=1:15]) # left + 1
end
flush(raw)
cd = ZlibCompressorStream(raw,level=9)
flush(cd)
seekstart(cd)
@show read(cd) # UInt8[0x78, 0xda, 0x63, 0x64, ...
"""

crosssection(::Type{HSV}) = crosssection(HSV, x=(2, "S", 0:1),
                                              y=(3, "V", 0:1),
                                              z=(1, "H", 0:360))
crosssection(::Type{HSL}) = crosssection(HSL, x=(2, "S", 0:1),
                                              y=(3, "L", 0:1),
                                              z=(1, "H", 0:360))
crosssection(::Type{HSI}) = crosssection(HSI, x=(2, "S", 0:1),
                                              y=(3, "I", 0:1),
                                              z=(1, "H", 0:360))

crosssection(::Type{Lab}) = crosssection(Lab, x=(2, "a*", -100:100),
                                              y=(3, "b*", -100:100),
                                              z=(1, "L*", 0:100))
crosssection(::Type{Luv}) = crosssection(Luv, x=(2, "u*", -100:100),
                                              y=(3, "v*", -100:100),
                                              z=(1, "L*", 0:100))
crosssection(::Type{LCHab}) = crosssection(LCHab, x=(2, "C*", 0:100),
                                                  y=(1, "L*", 0:100),
                                                  z=(3, "H", 0:360))
crosssection(::Type{LCHuv}) = crosssection(LCHuv, x=(2, "C*", 0:100),
                                                  y=(1, "L*", 0:100),
                                                  z=(3, "H", 0:360))

crosssection(::Type{YIQ}) = crosssection(YIQ, x=(2, "I", -1:1),
                                              y=(3, "Q", -1:1),
                                              z=(1, "Y", 0:1))
crosssection(::Type{YCbCr}) = crosssection(YCbCr, x=(2, "Cb", 0:256),
                                                  y=(3, "Cr", 0:256),
                                                  z=(1, "Y", 0:256))
end
