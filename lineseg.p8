pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

function aa_line_rect_x
	(x1,y1, -- segment point a
		x2,y2, -- segment point b
		r)					-- rectangle
	--
	local l,t,r,b=bounds(r)
	local code=function(x,y)
		local c=0
		if x<l then c+=1
		elseif x>r then c+=2 end
		if y<t then c+=4
		elseif y>b then c+=8 end
		return c
	end
	
	local c1,c2=code(x1,y1),code(x2,y2)
	local mask=0xf
	if x1==x2 then
		mask=0x3
	elseif y1==y2 then
		mask=0xc
	end
	
	return band(c1,mask)==0 and
		band(c1,c2)==0
end

function _init()
	x0,y0=64,56
	x1,y1=64,71
	
	r={x=72,y=49,w=8,h=8}
	
	d=1
	travel=0
	needed=30
	
	--run_cr=cocreate(move)
end

function dv(d)
	return cardinal(d,
		{1,0,0,1,-1,0,0,-1})
end

function move()
	while true do
		dx,dy=dv(d)
		r.x+=dx
		r.y+=dy
		travel+=1
		if travel>=needed then
			travel=0
			needed=15*((d+1)%2+1)
			d=(d+1)%4
			yield()
		end
		yield()
	end
end

function _update()
	if run_cr and costatus(run_cr)~="dead"
	then
		coresume(run_cr)
	end
	
	local ix,iy=input_xy()
	r.x+=ix
	r.y+=iy
end

function _draw()
	cls()
	
	local c=12
	
	if aa_line_rect_x(x0,y0,x1,y1,r)
	then
		c=8
	end
	
	rect_draw(r,c)
	
	line(x0,y0,x1,y1,10)
	draw_watches()
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
