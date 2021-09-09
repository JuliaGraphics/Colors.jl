module PNG16x16

using Colors
using Base64

export write_png_as_data, write_png

function write_png_as_data(io::IO, cs::AbstractMatrix{<:Color})
    write(io, "data:image/png;base64,")
    b64enc = Base64EncodePipe(io)
    write_png(b64enc, cs)
    close(b64enc)
end

function write_png(io::IO, cs::AbstractMatrix{<:Color})
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

end # module
