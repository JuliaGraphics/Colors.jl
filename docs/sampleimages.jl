
module SampleImages

using Colors
using Base64

struct BeadsImageSVG <: Main.SVG
    buf::IOBuffer
end


# The following code is ad-hoc and highly depends on "beads.svg".
# Be careful when modifying the svg file or its code.
function BeadsImageSVG(caption::String; filter=nothing, width="64mm", height="36mm")
    io = IOBuffer()
    id = string(hash(caption), base=16)

    open(joinpath("assets", "figures", "beads.svg"), "r") do file
        for line in eachline(file, keep=true)
            occursin("<?xml", line) && continue
            if occursin("<svg", line)
                line = replace(line, ">"=>
                    """ width="$width" height="$height" style="display:inline; margin-left:1em; margin-bottom:1em">""")
            elseif occursin("filter_beads_g", line)
                line = replace(line, "filter_beads_g"=>"filter_"*id)
            elseif occursin("</svg>", line)
                text = """
                       <text x="16" y="1000" style="fill:black;opacity:0.9;font-size:80px;">$caption</text>
                       </svg>"""
                line = replace(line, "</svg>"=>text)
            end

            m = match(r"data:image/png;base64,([^\"]+)", line)
            if filter === nothing || m === nothing
                write(io, line)
                continue
            end

            head = m.offsets[1]
            write(io, SubString(line, 1, head - 1))
            src = IOBuffer(m.captures[1])
            b64dec = Base64DecodePipe(src) # decode all for simplicity
            b64enc = Base64EncodePipe(io)
            write(b64enc, read(b64dec, 33)) # before the length of "PLTE"
            replace_palette(b64enc, b64dec, filter)
            n = write(b64enc, read(b64dec))
            close(b64enc)
            close(b64dec)
            write(io, SubString(line, head + length(m.captures[1]), length(line)))
        end
    end
    BeadsImageSVG(io)
end


function replace_palette(dest::IO, src::IO, filter)
    buf = IOBuffer() # to calculate chunk CRCs

    u8(x) = write(buf, UInt8(x & 0xFF))
    u16(x) = (u8((x & 0xFFFF)>>8); u8(x))
    u32(x) = (u16((x & 0xFFFFFFFF)>>16); u16(x))
    function read_palette()
        uint32 = (UInt32(read(src, UInt8)) << 16) |
                 (UInt32(read(src, UInt8)) <<  8) | read(src, UInt8)
        reinterpret(RGB24, uint32)
    end
    function write_palette(c::Color)
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
    lenbytes = read(src, 4)
    len = (UInt32(lenbytes[3]) << 8) | lenbytes[4]
    write(dest, lenbytes)
    write(buf, read(src, 4)) # "PLTE"
    for i = 1:(len÷3)
        write_palette(filter(read_palette()))
    end
    read(src, 4) # CRC
    crc32()
    write(dest, take!(seekstart(buf)))
end

end
