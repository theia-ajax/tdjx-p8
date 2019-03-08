pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	combo_levels={
		{
			needed=0,
			mult=1,
			xpmult=1,
		},
		{
			needed=16,
			mult=2,
			xpmult=1.5,
		},
		{
			needed=32,
			mult=4,
			xpmult=2,
		},
		{
			needed=64,
			mult=8,
			xpmult=4,
		},
		{
			needed=128,
			mult=16,
			xpmult=8,
		},
	}

	gm={
		score=0,
		combo_xp=0,
		combo_level=1,
		apple_score=5,
		combo_drain=1,
		combo_bar_f=0,
	}

	snek={
		x=63,y=63,
		r=0,
		speed=36,
		turn=1.2,
		rad=1,
		invul_f=10,
		last_x=63,
		last_y=63,
		col_idx=9,
		tail={},
		c1=7,c2=7
	}
	
	snek_add_chunk(snek,3,7)
	
	apples={}
	apple_ct=12
	for i=1,apple_ct do
		add_apple()
	end
end

function rnd_apple_pos()
	local valid=function(x,y)
		return not fget(mget(x,y),0)
	end
	
	local tx,ty=0,0
	repeat
		tx,ty=flr(rnd(16)),flr(rnd(16))
	until valid(tx,ty)

	return tx*8+4,ty*8+4
end

function add_apple()
	local x,y=rnd_apple_pos()
	add(apples,{id=#apples,x=x,y=y,rad=3,col=7})
end

function snek_add_chunk(s,ct,col)
	local n=#s.tail
	local t=s.tail[n]
	col=col or 7
	
	local tx,ty=s.x,s.y
	if t then
		tx,ty=t.x,t.y
	end
	
	ct=ct or 1
	
	for i=1,ct do
		add(s.tail,{x=tx,y=ty,rad=1,col=col})
	end
end
vel=0
mx,my=0,0
function _update60()
	dt=1/60
	
	if (snek.invul_f>0) snek.invul_f-=1
	
	if dist(snek.x,snek.y,snek.last_x,snek.last_y)>=3 then
		snek.last_x=snek.x
		snek.last_y=snek.y
 	local n=#snek.tail
 	if n>0 then
  	for i=n,2,-1 do
  		snek.tail[i].x=
  			snek.tail[i-1].x
  		snek.tail[i].y=
  			snek.tail[i-1].y
  	end
  	snek.tail[1].x=snek.x
  	snek.tail[1].y=snek.y
  end
	end
	
	
	local ix,iy=0,0

	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	
	
	input_mode="tank"
	
	if input_mode=="tank" then
		local scl=1
		if (btn(4)) scl=0.5
		snek.r+=snek.turn*dt*scl*-ix
	elseif input_mode=="dir" then
		local isen=3
		local igrav=3
		rx=isen*dt
		if (ix==0) rx=igrav*dt
		ry=isen*dt
		if (iy==0) ry=igrav*dt
		mx=moveto(mx,sgn(ix),rx)
		my=moveto(my,sgn(iy),ry)
	
		if mx~=0 or my~=0 then
			dx,dy=norm(mx,my)
			local t=atan2(dx,dy)
			snek.r=moveto_angle(snek.r,t,1*dt)
--			snek.r,vel=damp_angle(
--				snek.r,t,vel,0.1)
--			snek.r=t
		end
	end
	
	local vx,vy=cos(snek.r)*snek.speed,
		sin(snek.r)*snek.speed
		
	if snek.dead then
		vx,vy=0,0
	end
		
	snek.x+=vx*dt
	snek.y+=vy*dt
	
	local combo=combo_levels[gm.combo_level]
	
	for a in all(apples) do
		a.y+=50*dt
		if a.y>128+16 then
			a.y-=128+16*2
		end
		if circhit(snek,a) then
			snek_add_chunk(snek,3,a.col)
			a.x,a.y=rnd_apple_pos()
--			a.col=8+flr(rnd(7))
			gm.combo_xp+=gm.apple_score*combo.xpmult
			local score=gm.apple_score*combo.mult
			gm.score+=score
		end
	end
	
	gm.combo_xp-=gm.combo_drain*dt
	gm.combo_xp=mid(gm.combo_xp,
		0,256)
		
	if gm.combo_xp<combo.needed then
		gm.combo_level-=1
	end

	local next=combo_levels[gm.combo_level+1];
	if next then
		if gm.combo_xp>=next.needed then
			gm.combo_level+=1
		end
	end
	
	local xpneed=256
	local next=combo_levels[gm.combo_level+1]
	if (next) xpneed=next.needed
	local base=combo_levels[gm.combo_level].needed
	local f=(gm.combo_xp-base)/(xpneed-base)
	gm.combo_bar_f=(f-gm.combo_bar_f)*10*dt+gm.combo_bar_f
	
	if snek.invul_f<=0 then
		for i=snek.col_idx,#snek.tail do
			if circhit(snek,snek.tail[i]) then
				snek.dead=true
			end
		end
	end
	
	if level_solid(snek.x,snek.y)
	or snek.x<0 or snek.x>127 or
	snek.y<0 or snek.y>127
	then
		snek.dead=true
	end
end

function _draw()
	cls(1)

	map(0,0,0,0,16,16)
	
	for a in all(apples) do
		spr(2,a.x-2,a.y-2)
//		circ(a.x,a.y,a.rad-1,a.col)
	end
	
	local n=#snek.tail
	for i=n,2,-1 do
		line(snek.tail[i].x,
			snek.tail[i].y,
			snek.tail[i-1].x,
			snek.tail[i-1].y,
			snek.tail[i].col)
	end
	if #snek.tail>0 then
 	line(snek.tail[1].x,
 		snek.tail[1].y,
 		snek.x,
 		snek.y,
 		snek.c1)
 end
--[[	pset(snek.tail[1].x,
		snek.tail[1].y,
		9)]]
	
	local sx,sy=snek.x,snek.y
--	circfill(sx,sy,snek.rad,11)
	pset(sx,sy,snek.c2)
		
--[[	circfill(sx+cos(snek.r)*2,
		sy+sin(snek.r)*2,
		1,
		10)]]
		
	local f=gm.combo_bar_f
	print(f,0,18,7)
	if (f*127>0.5) rectfill(0,126,127*f,127,11)
	local m="x"..tostr(combo_levels[gm.combo_level].mult)
	print(m,127-#m*4,127-8,7)
		
	print(gm.score,0,0,7)
	print(gm.combo_xp,0,6,7)
	print(gm.combo_level,0,12,7)
	--print(tostr(band(stat(1)*100).."%",0xffff),0,0,7)
	
	if snek.dead then
		print("dead",56,62,8)
	end
end



-->8
-- util

function circhit(c1,c2)
	return dist(c1.x,c1.y,c2.x,c2.y)<=c1.rad+c2.rad
end

function level_solid(x,y)
	return fget(mget(x/8,y/8),0)
end

function mod(a,b)
 local r=a%b
 if r>=0 then
  return r
 else
  return r+b
 end
end

function dist2(x1,y1,x2,y2)
 local dx,dy=x2-x1,y2-y1
 return dx*dx+dy*dy
end

function dist(x1,y1,x2,y2)
 return sqrt(dist2(x1,y1,x2,y2))
end

function sqr(n)
 return n*n
end

function angle_to(ox,oy,tx,ty)
 return atan2(tx-ox,ty-oy)
end

function wrap(a,l)
 return mid(a-flr(a/l)*l,0,l)
end

function angle_diff(a,b)
 local d=wrap(b-a,1)
 if (d>0.5) d-=1
 return d
end

-- a: current value
-- b: target value
-- vel: current velocity
-- tm: approx time in seconds to take
-- mx: max speed (defaults inf)
-- ts: timestep (defaults dt)
-- returns result,velocity
-- feed velocity back in
-- to subsequent calls
-- e.g.
-- a,v=damp(a,1,v,0.5,2)
function damp(a,b,vel,tm,mx,ts)
 mx=mx or 32767
 ts=ts or dt
 tm=max(.0001,tm or 0)
 local omega=2/tm
 
 local x=omega*ts
 local exp=1/(1+x+.48*x*x+.235*x*x*x)
 local c=b-a
 local orig=b
 
 local mxc=mx*tm
 c=mid(c,-mxc,mxc)
 b=a-c
 
 local tmp=(vel+omega*c)*ts
 vel=(vel+omega*tmp)*exp
 local ret=b+(c+tmp)*exp
 
 if (orig-a>0)==(ret>orig) then
  ret=orig
  vel=(ret-orig)/ts
 end
 
 return ret,vel
end

function damp_angle(a,b,vel,tm,mx,ts)
 b=a+angle_diff(a,b)
 return damp(a,b,vel,tm,mx,ts)
end

function _sgn(a)
 if a<0 then return -1
 elseif a>0 then return 1
 else return 0 end
end
sgn=_sgn

function moveto(a,b,d)
 if abs(b-a)<=d then
  return b
 else
  return a+sgn(b-a)*d
 end
end

function moveto_angle(a,b,d)
 local dl=angle_diff(a,b)
 if -d<dl and dl<d then
  return b
 else
  return moveto(a,a+dl,d)
 end
end

function m01(v)
 return mid(v,0,1)
end

function lerp(a,b,t)
 return a+(b-a)*t
end

function lerp_angle(a,b,t)
 local d=wrap((b-a),1)
 if (d>0.5) d-=1
 return a+d*m01(t)
end

function len(x,y)
	return dist(x,y,0,0)
end

function norm(x,y)
	local l=len(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end
__gfx__
000000005555555500bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000005555555588b8800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555558888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555558888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555555550888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
