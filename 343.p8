pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
end

function _update()
end

function _draw()
	cls()
	
	for i=0,4 do
		c=6
		if (i>2) c=12
		circ(64,64,64-i,c)
	end
	
	srand()
	for i=0,8 do
		local a=-t()/(8+rnd(8))+i/6
		line(64,64,
			64+cos(a)*128,64+sin(a)*128,0)
	end

	draw_letters(function(u) return cos(u)<0 end)
	
	line(5,64,123,64,12)
	circfill(64,64,4,12)
	
	for i=0,10 do
		x=5+54*((t()*rnd()+i/12+rnd())%1)
		pset(x,64,2)
		x=123-54*((t()*rnd()+i/12+rnd())%1)
		pset(x,64,2)
	end

	draw_letters(function(u) return cos(u)>=0 end)
end

function draw_letters(condfn)
	for i=0,2 do
		u=t()/4+i/6
		
		w=10+cos(u)*6
		h=w
		x=64-((i-1)*34)
		y=64+sin(u)*18
		
		if condfn(u) then
			sspr(8+16*(i%2),0,16,16,
				x-w,y-w,w*2,h*2)
		end
	end
end
__gfx__
00000000777777777777770000000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777000000000077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000777777700000000770777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000007777700000007700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000777700000077000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000777000000770000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007777000007700000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777770000077000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777777777770000770000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007777007700000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777077000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000777777700000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777770000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000