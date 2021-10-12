pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- fillp visualizer
-- tdjx

k_btn_l = 0
k_btn_r = 1
k_btn_u = 2
k_btn_d = 3
k_btn_o = 4
k_btn_x = 5

btns = {}
prevbtns = {}

function _init()
	digits = { 0x0, 0x0, 0x0, 0x0 }
	digidx = 1
end

function _update()
	for i = 0, 5 do
		prevbtns[i] = btns[i]
		btns[i] = btn(i)
	end

	if (btnprs(k_btn_l)) digidx -= 1
	if (btnprs(k_btn_r)) digidx += 1
	if (digidx < 1) digidx = 4
	if (digidx > 4) digidx = 1

	if (btnprs(k_btn_u)) digits[digidx] += 1
	if (btnprs(k_btn_d)) digits[digidx] -= 1
	digits[digidx] %= 0x10
end

function _draw()
	cls()

	fillp()
	for i = 1, 4 do
		print(tohex(digits[i]), 52 + (i-1) * 6, 24)
	end

	print("⬇️", 52 + (digidx - 1) * 6 - 2, 16, 8)

	local pat = shl(digits[1], 12) +
		shl(digits[2], 8) +
		shl(digits[3], 4) +
		digits[4]

	fillp(pat)

	rectfill(0, 48, 63, 127, 7)

	for r = 0, 13 do
		line(64, 48 + r * 6, 127, 48 + r * 6)
	end

	for c = 0, 10 do
		line(64 + c * 6, 48, 64 + c * 6, 127)
	end
end

function btnprs(b)
	return btns[b] and not prevbtns[b]
end

function tohex(d)
	local ret = tostr(d, true)
	return sub(ret, 6, 6)
end
