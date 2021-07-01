pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
local hex = {
  "000000", "1d2b53", "7e2553", "008751", "ab5236", "5f574f", "c2c3c7", "fff1e8",
  "ff004d", "ffa300", "ffec27", "00e436", "29adff", "83769c", "ff77a8", "ffccaa",
  "291814", "111d35", "422136", "125359", "742f29", "49333b", "a28879", "f3ef7d",
  "be1250", "ff6c24", "a8e72e", "00b543", "065ab5", "754665", "ff6e59", "ff9d81"
}

local name = {
  "black", "storm", "wine", "moss", "tan", "slate", "silver", "white",
  "ember", "orange", "lemon", "lime", "sky", "dusk", "pink", "peach",
  "cocoa", "midnight", "port", "sea", "leather", "charcoal", "olive", "sand",
  "crimson", "amber", "tea", "jade", "denim", "aubergine", "salmon", "coral",
}

function col(i,j)
  return (j>=8 and 128 or 0) + i*8 + j%8
end

local speed = 4
local dy = 0

-- enable raster gradient for color 2
poke(0x5f2c,0x40)
poke(0x5f5f,0x30 + 2)

function _update()
  dy += (btn(2) and -speed or 0) + (btn(3) and speed or 0)
  dy = mid(0, dy, 128)
  pal(0,0,1)
  pal(1,col(1,dy\16+8),1)
  -- colors 3-9 for left column
  for i=0,8 do pal(3+i,col(0,i+dy\16),1) end
  -- raster colors for right column
  for i=0,15 do poke(0x5f60+i,col(1,(i+dy\8)\2)) end
  for i=0,15,2 do poke2(0x5f70+i,0x.ffff>><(dy%16)) end
end

function _draw()
  cls(0)
  camera(0,dy)
  for i=0,1 do
    for j=0,15 do
      local x = i*64
      local y = j*16
      rectfill(x,y,x+63,y+15,i+j==0 and 8 or 0)
      local c = i==0 and j-dy\16+3 or j>dy\16+7 and 1 or 2
      rectfill(x,y,x+15,y+15,c)
      local idx = (j>=8 and 17 or 1) + i*8 + j%8
      print(name[idx],x+19,y+2)
      print(hex[idx],x+19,y+8)
      local s=tostr(col(i,j))
      print(s,x+9-#s*2,y+6,i+j==0 and 8 or 0)
    end
  end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
