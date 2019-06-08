pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

actor=class({
	x=0,y=0,w=0,h=0,
})

function add_actor(p)
	return add(actors,actor:new(p))
end

function _init()
	poke(0x5f2d,1)

	dt=fps30_dt
	
	cam={x=0,y=0}

	actors={}
	
	player=add_actor({
		x=64,y=64,
		dx=0,dy=0,
		w=8,h=4,
		tf=0,
		grounded=false,
		draw=function(self)
			rect_draw(self,8)
			local x,y=topleft(self)
		--	print("😐",x,y,7)
--			print("웃",x,y+4,7)
			spr(16+(flr(self.tf*32)%2)*2,x,y,2,1)
		end,
	})
	
	ground={}
	ground_chunk_size=8
	ground_chunks=ceil(128/ground_chunk_size)+2
	
	for i=1,ground_chunks do
		local by=gen_height()
		add(ground,{
			x=(i-1)*ground_chunk_size,
			y=by,
			by=by,
			id=i-1,
		})
	end
	
	init_pfx()
end

function gen_height()
--	return 16+flr(rnd(48))
--	return 24+flr(rnd(32))
--	return 32
	return 30+flr(rnd(4))
end

function _update()


	
	local scroll=player.dx*dt
	
--	player.x+=scroll
	cam.x+=scroll
	cam.x=max(player.x-64,ground[1].x)

	local ix,iy=input_xy()
	
	movescl=1
	
	if player.grounded then	
		local gnx,gny=ground_norm(player.x)
		movescl=lerp(0.2,1,(dot(gnx,gny,ix,0)+1)/2)
	end
	
	-- gravity
	player.dy+=200*dt
	
	local accel=120
	player.dx+=ix*accel*movescl*dt
	
	if ix==0 then
		player.dx=moveto(player.dx,0,accel*dt)
	end
	
	player.dx=mid(player.dx,-120,120)

	player.x+=player.dx*dt
	player.y+=player.dy*dt
	
	
	
	if player.x<ground[1].x+8 then
		player.x=ground[1].x+8
		player.dx=max(player.dx,0)
	end
	
	local groundy=128-ground_height(player.x)-player.h
	if player.y+2>=groundy then
		
		local dely=player.y-groundy+2
--		player.y=groundy
		player.dy-=dely*2
		player.dy=min(player.dy,0)
		player.grounded=true
		
		
	else
		player.grounded=false
	end
	
	if ix>0 then
		if player.grounded then
			add_pfx({
				sp=32,
				x=player.x-7,y=player.y+2,
				dx=0,
				dy=-rnd(48)-16,
				ddy=200,
				t_life=2,
			})
		end
		player.tf+=dt
	end
	
	local maxx=10000
	if cam.x>maxx then
		cam.x-=maxx
		for g in all(ground) do
			g.x-=maxx
		end
		foreach(actors,function(a)
			a.x-=maxx
		end)
	end
	
	local n=#ground
	for i=1,n do
		local g=ground[i]
		local f=g.id/n
		g.y=g.by+sin(t()/8+f)*((6+sin(t()/16+f*2)*2)+(sin(t()/32+f)*4))
	end
	
	local bound=cam.x-ground_chunk_size
	
	if ground[1].x<bound then
		local t=ground[1]
		local n=#ground
		for i=1,n-1 do
			ground[i]=ground[i+1]
		end
		local delta=abs(t.x-bound)
		
		t.x+=n*ground_chunk_size
		t.by=gen_height()
		ground[n]=t
		
	end
	
	update_pfx(dt)
end

function ground_height(x)
	local i=ground_idx(x)
	if i>0 then
		local gt=(x-ground[i].x)/ground_chunk_size
		return lerp(ground[i].y,ground[i+1].y,gt)
	else
		return 0
	end
end

function ground_norm(x)
	local i=ground_idx(x)
	if i>0 then
		local a,b=ground[i],ground[i+1]
		local dx,dy=b.x-a.x,-(b.y-a.y)
		local ndx,ndy=norm(dx,dy)
		return ndy,-ndx
	else
		return 0,0
	end
end

function ground_idx(x)
	local n=#ground
	if x<ground[1].x or x>ground[n].x then
		return 0
	else
		for i=1,n do
			if x>=ground[i].x and x<ground[i+1].x then
				return i
			end
		end
		return 0
	end
end

function _draw()
	cls(13)
	
		
	camera(cam.x,cam.y)


	ground_col_bg=1
	ground_col_fg=12
	ground_top=3

	local n=#ground
	for i=1,n-1 do
		local a=ground[i]
		local b=ground[i+1]
--		pset(ground[i].x,128-ground[i].y,11)		
		local sy=a.y
		local m=(b.y-a.y)/ground_chunk_size

		for p=0,ground_chunk_size-1 do
			local y1=128-sy
			local y2=128-sy+ground_top
			line(a.x+p,y1,a.x+p,y2,ground_col_fg)
--			line(a.x+p,y2,a.x+p,127,ground_col_bg)
			sy+=m
		end
	end
	
	foreach(actors,function(a)
		if a.draw then
			a:draw()
		else
			local tlx,tly=topleft(a)
			local brx,bry=botright(a)
			rectfill(tlx,tly,brx,bry,8)
		end
	end)
	
	
	local n=#ground
	for i=1,n-1 do
		local a=ground[i]
		local b=ground[i+1]
--		pset(ground[i].x,128-ground[i].y,11)		
		local sy=a.y
		local m=(b.y-a.y)/ground_chunk_size

		for p=0,ground_chunk_size-1 do
			local y1=128-sy
			local y2=128-sy+ground_top
--			line(a.x+p,y1,a.x+p,y2,ground_col_fg)
			line(a.x+p,y2,a.x+p,127,ground_col_bg)
			sy+=m
		end
	end
	
	local mx,my=stat(32),stat(33)
	
	
	local cx=cam.x+mx
	local cy=128-ground_height(cx)-2
	circfill(cx,cy,2,10)

	draw_pfx()

	camera()
	
	print(player.x..","..player.y,0,0,7)
	print(player.dx..","..player.dy,0,6,7)
	pset(mx,my,7)
end

particle=class({
	sp=0,
	sw=1,sh=1,
	x=0,y=0,
	w=4,h=4,
	dx=0,dy=0,
	ddx=0,ddy=0,
	t_life=0,
})

function init_pfx()
	pfx={}
end

function add_pfx(p)
	return add(pfx,particle:new(p))
end

function update_pfx(dt)
	for p in all(pfx) do
		local dead=false
		p.t_life-=dt
		if p.t_life<=0 then
			dead=true
		end
		
		p.dx+=p.ddx*dt
		p.dy+=p.ddy*dt
		p.x+=p.dx*dt
		p.y+=p.dy*dt
		
		if (dead) del(pfx,p)
	end
end

function draw_pfx()
	for p in all(pfx) do
		local tlx,tly=topleft(p)
		spr(p.sp,tlx,tly,p.sw,p.sh)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000557777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000577777790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700577779990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000079999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00550000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00557777777777700055777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00577777777777000057777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05577779999990000057777999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00079999999900000507999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c07c700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07c0c700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
