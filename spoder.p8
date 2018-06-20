pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	spider={}
	spider.x=16
	spider.y=64
	spider.r=0
	spider.dx=0
	spider.dy=0
	spider.rad=4
	spider.legs={}
	local roff=1/8
	local legct=4
	for i=1,legct do
		local leg={
			r=roff+(i-1)/legct,
			uplen=10,
			lowlen=15,
		}
		local x,y=spider.x,spider.y
		local ln=spider.rad+leg.uplen
		local ln2=ln+leg.lowlen/2
		leg.upx=x+cos(leg.r)*ln
		leg.upy=y+sin(leg.r)*ln
		leg.lowx=x+cos(leg.r)*ln2
		leg.lowy=y+sin(leg.r)*ln2
		leg.tgx=leg.lowx
		leg.tgy=leg.lowy
		add(spider.legs,leg)
	end
end

function _update()
	spider.dx=cos(r)/4
	spider.dy=sin(r)/4
	spider.x+=spider.dx
	spider.y+=spider.dy
	
	for i=1,#spider.legs do
		local leg=spider.legs[i]
		local ln=spider.rad+leg.uplen
		leg.upx=spider.x+
			cos(leg.r)*ln
		leg.upy=spider.y+
			sin(leg.r)*ln
		local lx=leg.upx-leg.lowx
		local ly=leg.upy-leg.lowy
		local d=sqrt(lx*lx+ly*ly)
		if d>leg.lowlen then
			leg.tgx=leg.upx+
				cos(leg.r)*leg.lowlen/2
			leg.tgy=leg.upy+
				sin(leg.r)*leg.lowlen/2
		end
		leg.lowx=lerp(leg.lowx,
			leg.tgx,0.2)
		leg.lowy=lerp(leg.lowy,
			leg.tgy,0.2)
	end
end

function _draw()
	cls()
	
	circfill(spider.x,spider.y,
		spider.rad,7)
	
	for i=1,#spider.legs do
		local leg=spider.legs[i]
		line(spider.x,spider.y,
			leg.upx,leg.upy,7)
		circ(leg.upx,leg.upy,3,7)
		line(leg.upx,leg.upy,
			leg.lowx,leg.lowy,7)
	end
end

function lerp(a,b,t)
	return a+(b-a)*t
end
