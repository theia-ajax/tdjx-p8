pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

pfx=class({
	x=0,y=0,					-- position
	dx=0,dy=0,			-- velocity
	ddx=0,ddy=0,	-- acceleration
	ptype="point",
	rad=0,
	w=0,h=0,
	t_life=0,
	color1=7,
	layer=0,
})

function pfx_init()
	pfx_list={}
end

function pfx_add(p)
	local vx1,vy1,vx2,vy2=viewport(16,16)
	if p.x>=vx1 and p.y>=vy1 and
		p.x<=vx2 and p.y<=vy2
	then
		return add(pfx_list,
			pfx:new(p))
	else
		return nil
	end
end

function pfx_update(dt)
	-- sort particles by layer
	-- using limited bubble sort
	-- won't be perfect but
	-- will be performant
	-- and good enough for most
	-- use-cases

	local n=#pfx_list
	local l=pfx_list
	for _=1,3 do
		for i=1,n-1 do
			if l[i].layer<l[i+1].layer
			then
				l[i],l[i+1]=l[i+1],l[i]
			end
		end
	end

	for p in all(pfx_list) do
		p.dx+=p.ddx*dt
		p.dy+=p.ddy*dt
		p.x+=p.dx*dt
		p.y+=p.dy*dt
		
		p.t_life-=dt
		if (p.t_life<=0) del(pfx_list,p)
	end
end

function pfx_draw()
	for p in all(pfx_list) do
		if p.ptype=="point" then
			pset(p.x,p.y,p.color1)
		elseif p.ptype=="circle" then
			circfill(p.x,p.y,p.rad,p.color1)
		elseif p.ptype=="rect" then
			local hw,hh=p.w/2,p.h/2
			rectfill(p.x-hw,p.y-hh,
				p.x+hw-1,p.y+hh-1,
				p.color1)
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
