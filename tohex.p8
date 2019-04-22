pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
num=81.3542

hex_table={
	"0","1","2","3",
	"4","5","6","7",
	"8","9","a","b",
	"c","d","e","f"
}

local str="0x"
for i=1,8 do
	local v=(i-4)*4
	local shf=shl
	if v<0 then
		shf=shr
		v=abs(v)
	end
	local h=band(shf(num,v),0xf)
	local hs=hex_table[h+1]
	str=str..hs
	if (i==4) str=str.."."
end

cls()
print(str)


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
