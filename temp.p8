pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
k_color_fg=7
k_color_bg=1

function _init()

end

function _update()
	for i=0,15 do
		pal(i,k_color_fg)
	end
end

function _draw()
	cls(k_color_bg)
	
	map(0,0,0,0,16,16)
	spr(1,60,60)
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700077700700777007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077770700777707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777777707777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777700007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077700770777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700707770707070007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700070777770707777707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777070777770007777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07077770077700000777707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000070777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707070077007770707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777000000000000000000000077777770777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
77000700777700070077777777777700077777770777700700000000000000000000000000000000000000000000000000000000000000000000000000000000
07707007777770700777777777777770070077770777770700000000000000000000000000000000000000000000000000000000000000000000000000000000
77707077777770700770700000000070077007770777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
77707777777770770777777777777070007707770077777700000000000000000000000000000000000000000000000000000000000000000000000000000000
77007777777770070777777777777070077777770777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777777770700777777777777070000707070007070700000000000000000000000000000000000000000000000000000000000000000000000000000000
77700777777707000777777777777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770077777000070777777777777770077777770777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
77777000000070770777777777777070077777770770777700000000000000000000000000000000000000000000000000000000000000000000000000000000
77777007770770770777777777777770077077770777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
77777077777000770777777777777770077007770777770700000000000000000000000000000000000000000000000000000000000000000000000000000000
77770077777000070077777777777770007777770077000700000000000000000000000000000000000000000000000000000000000000000000000000000000
77700077777077000777777777777770077777770777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
00007707770777700007070707070700000707070007070700000000000000000000000000000000000000000000000000000000000000000000000000000000
77077000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2223222322232223222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3233343335332433253300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000012121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0012121200000000000000121212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000