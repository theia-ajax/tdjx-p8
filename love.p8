pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
_xp_per_lvl={
	2,2,2,4,4,6,6,8,8
}

_xp_needed={}
local sum=0
for i=1,#_xp_per_lvl do
	sum+=_xp_per_lvl[i]
	add(_xp_needed,sum)
end

_lvl_shotivl={
	32,22,16,12,10,8,6,5,4
}

function _init()
	plr={}
	plr.x=64
	plr.y=64
	plr.shotf=0
	plr.lvl=1
	plr.xp=0
	
	stars={}
	hearts={}
	robots={}
end

function _update60()
	if rnd(100)<3 then
		add(robots,{
			x=130,
			y=flr(rnd(127)),
			saved=false
		})
	end
	
	for r in all(robots) do
		if not r.saved then
			r.x-=1
			for s in all(stars) do
				local dx=s.x-r.x
				local dy=s.y-r.y
				if dx<10 and dy<10 then
 				local d=sqrt(dx*dx+dy*dy)
 				if d<5 then
 					r.saved=true
 					add(hearts,{
 						x=s.x,y=s.y,
 						dx=0,dy=0
 					})
 					del(stars,s)
 				end
 			end
			end
			if (r.x<-10)	del(robots,r)
		else
			r.y-=.5
			if (r.y<-10) del(robots,r)
		end
	end
	
	for s in all(stars) do
		s.dy+=0.2
		s.x+=1
		s.y+=s.dy
		if (s.x>150) del(stars,s)
	end

	local dx,dy=0,0
	if (btn(0)) dx-=1
	if (btn(1)) dx+=1
	if (btn(2)) dy-=1
	if (btn(3)) dy+=1
	dx*=1.5
	dy*=1.5
	plr.x+=dx
	plr.y+=dy
	
	if (plr.x<3) plr.x=3
	if (plr.x>80) plr.x=80
	if (plr.y<3) plr.y=3
	if (plr.y>124) plr.y=124
	
	if btn(4) then
		plr.shotf-=1
		if plr.shotf<=0 then
			plr.shotf=plr_shotivl(plr)
			add(stars,{
				x=plr.x,y=plr.y,
				dx=0,dy=-(rnd(4)+1),
			})
		end
	else
		plr.shotf=0
	end
	
	for h in all(hearts) do
		local dx=plr.x-h.x
		local dy=plr.y-h.y
		local d=9999
		if dx<50 and dy<50 then
			d=sqrt(dx*dx+dy*dy)
			d=max(d,0.1)
		end
		if d<50 then
			if d<5 then
				del(hearts,h)
				plr_gainxp(plr,1)
			end
			local nx,ny=dx/d,dy/d
			h.x+=nx*(1-min(d/50,.9))
			h.y+=ny*(1-min(d/50,.9))
		else
			h.x-=.25
		end
	end
end

function _draw()
	cls()
	print("웃",plr.x-3,plr.y-2,6)
	for r in all(robots) do
		local s="🐱"
		if (r.saved) s="ˇ"
		print(s,r.x-3,r.y-3,6)
	end
	
	for s in all(stars) do
		print("★",s.x-3,s.y-3,8+flr(rnd(7)))
	end
	
	for h in all(hearts) do
		print("♥",h.x-3,h.y-3,8)
	end
	
	rect(0,0,102,8,7)
	local need=plr_xpneed(plr)
	local f=1
	if need>0 then
		local pneed=xpneed(plr.lvl-1)
		local xp=plr.xp
		if pneed then
		 xp-=pneed
		 need-=pneed
		end
		f=xp/need
	end
	if f>0 then
		rectfill(1,1,1+100*f,7,6)
	end

	print(plr.xp.."/"..plr_xpneed(plr),0,10,7)
	console_draw()	
end

function plr_shotivl(plr)
	local idx=
		min(plr.lvl,#_lvl_shotivl)
	return _lvl_shotivl[idx]
end

function plr_xpneed(plr)
	return xpneed(plr.lvl)
end

function xpneed(lvl)
	local need=_xp_needed[lvl]
	if need then
		return need
	else
		return 0
	end
end

function plr_gainxp(plr,amt)
	local need=plr_xpneed(plr)
	if need>0 then
		plr.xp+=1
		-- todo make it work with amt
		if plr.xp>=need then
			plr.lvl+=1
		end
	end
end

console={}
console.mx=20
function console_draw()
	for i=1,#console do
		print(console[i],
			0,(i-1)*6)
	end
end

function log(msg)
	add(console,msg)
	if #console>console.mx then
		for i=2,#console+1 do
			console[i-1]=console[i]
		end
	end
end
