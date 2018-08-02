pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
color1=3
color2=11

function _init()
	cam={}
	cam.kx=0
	cam.ky=0
	cam.kt=0
	cam.sx=0
	cam.sy=0
	cam.sm=0
	cam.st=0

	plr={}
	plr.x=64
	plr.y=64
	-- half width/height
	plr.w=8
	plr.h=4
	plr.health=100
	plr.fire_itvl=8
	plr.fire_t=0
	
	spawn_t=90
	
	bullets={}
	drones={}
	words={}
	notes={}
	sparks={}
	
	msg="in space there is only freedom"
	msgx=64
	msgt=30
end

function _update()
	if sleept>0 then
		sleept-=1
		return
	end

	update_camera()
	
	
	if (msgt>0) msgt-=1
	if msgt<=0 and msgx>-1000 then
		msgx-=1
	end

	-- spawn drones
	spawn_t-=1
	if spawn_t<=0 then
		spawn_t=irndr(20,70)
		local c=irnd(3)
		for i=0,c do
			make_drone(150,irndr(20,107))
		end
	end

	update_table(bullets,
		update_bullet)
	update_table(drones,
		update_drone)
	update_table(words,
		update_word)
	update_table(notes,
		update_note)
	update_table(sparks,
		update_spark)

	update_player()
end

function _draw()
	cls(color1)
	pal(7,color2)
	color(color2)
	
	local cx,cy=cam_pos()
	camera(-cx,-cy)
	
	
	spr(1,
		plr.x-plr.w,
		plr.y-plr.h,
		2,1)
		
	foreach(drones,draw_drone)
	foreach(bullets,draw_bullet)
	foreach(words,draw_word)
	foreach(notes,draw_note)
	foreach(sparks,draw_spark)
	
	msg="in space there is only freedom"
	print(msg,msgx-#msg*2,24)

	camera()
	local hf=plr.health/100
	rectfill(2,2,2+hf*30,8)
end

function make_bullet(x,y)
	local blt={}
	blt.x=x
	blt.y=y
	blt.w=2
	blt.h=2
	blt.dx=4
	blt.dead=false
	return add(bullets,blt)
end

function update_bullet(blt)
	blt.x+=blt.dx
	if blt.x>130 then
		blt.dead=true
	end
end

function draw_bullet(blt)
	spr(3,blt.x-blt.w,blt.y-blt.h)
end

function update_player()
	local ix,iy=0,0
	
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	plr.x+=ix*2
	plr.y+=iy*2
	
	plr.x=mid(9,plr.x,120)
	plr.y=mid(14,plr.y,124)
	
	if btn(4) then
		plr.fire_t-=1
		if plr.fire_t<=0 then
			plr.fire_t=plr.fire_itvl
			make_bullet(plr.x+9,plr.y-2)
			cam_knock(-3,0,1)
		end
	else
		plr.fire_t=0
	end
	
	for nt in all(notes) do
		if not nt.dead then
			local d=dist(plr.x,plr.y,nt.x,nt.y)
			if d<=4 then
				on_note_hit_player(nt)
			end
		end
	end
end

function make_drone(x,y)
	local drn={}
	drn.x=x
	drn.y=y
	drn.w=8
	drn.h=8
	drn.dx=-1
	drn.dy=0
	drn.ddy=0.6
	drn.state=0
	drn.dead=false
	drn.singt=30
	return add(drones,drn)
end

function next_sing()
	return irndr(10,30)
end

function sing_type()
	local r=rnd()
	if r<.25 then
		return 0
	else
		return 1
	end
end

function update_drone(drn)
	if drn.state==0 then
 	drn.x+=drn.dx
 	
 	drn.singt-=1
 	if drn.singt<=0 then
 		drn.singt=next_sing()
 		make_note(drn.x,drn.y,sing_type())
 	end
 	
 	for blt in all(bullets) do
 		if not blt.dead 
 			and ent_overlap(drn,blt)
 		then
			
 			on_bullet_hit_drone(blt,drn)
 		end
 	end
 	
 	if drn.x<-20 then
 		drn.dead=true
 	end
 elseif drn.state==1 then
 	drn.dy+=drn.ddy
 	drn.y+=drn.dy
 	if drn.y>140 then
 		drn.dead=true
 	end
 end
end

function on_bullet_hit_drone(blt,drn)
	blt.dead=true
	drn.state=1
	drn.dy=-4
	make_word(drn.x,drn.y)
	make_spark(blt.x,blt.y)
	cam_shake(3,2)
	sleep(2)
end

function on_note_hit_player(nt)
	plr.health-=10
	plr.health=clamp(plr.health,0,100)
	cam_shake(4,3)
	nt.dead=true
	sfx(4)
	make_spark(nt.x,nt.y)
	sleep(1)
end

function draw_drone(drn)
	local sp=4
	if (drn.state==1) sp=6
	spr(sp,
		drn.x-drn.w,
		drn.y-drn.h,
		2,2)
end

function make_spark(x,y)
	local spk={}
	spk.x=x or 0
	spk.y=y or 0
	spk.w=4
	spk.h=4
	spk.t=3
	return add(sparks,spk)
end

function update_spark(spk)
	spk.t-=1
	if spk.t<=0 then
		spk.dead=true
	end
end

function draw_spark(spk)
	spr(16,spk.x-spk.w,spk.y-spk.h)	
end

function update_table(tbl,fn)
	local rq={}
	for i=1,#tbl do
		local v=tbl[i]
		fn(v)
		if v.dead then
			add(rq,i)
		end
	end
	idelfa(tbl,rq)
end

function ent_overlap(e1,e2)
	return e1.x-e1.w<=e2.x+e2.w
		and e1.x+e1.w>=e2.x-e2.w
		and e1.y-e1.h<=e2.y+e2.h
		and e1.y+e1.h>=e2.y-e2.h
end

freedom_words={
	"liberated",
	"freedom'd",
	"defended",
	"justiced",
}

function make_word(x,y)
	local wrd={}
	wrd.msg=freedom_words[
		flr(rnd(#freedom_words))+1]
	wrd.x=x
	wrd.y=y
	wrd.dy=0
	wrd.ddy=-0.2
	wrd.w=#wrd.msg*2
	return add(words,wrd)
end

function update_word(wrd)
	wrd.dy+=wrd.ddy
	wrd.y+=wrd.dy
	if wrd.y<-10 then
		wrd.dead=true
	end
end

function draw_word(wrd)
	print(wrd.msg,wrd.x-wrd.w,wrd.y)
end

function make_note(x,y,kind)
	local nt={}
	nt.kind=kind or 0
	nt.x=x or 0
	nt.y=y or 0
	nt.w=4
	nt.h=4
	nt.dx=0
	nt.dy=0
	nt.rot=0
	nt.t=0
	nt.spd=0
	
	if nt.kind==0 then
		nt.dx=-.5
	elseif nt.kind==1 then
		nt.spd=1
		nt.rot=atan2(plr.x-nt.x,
			plr.y-nt.y)
	end
	
	return add(notes,nt)
end

function update_note(nt)
	if nt.kind==0 then
		nt.t+=1
	elseif nt.kind==1 then
		nt.spd+=0.05
		nt.dx=cos(nt.rot)*nt.spd
		nt.dy=sin(nt.rot)*nt.spd
	end
	
	nt.x+=nt.dx
	nt.y+=nt.dy
	
	if nt.y<-10 or nt.x<-10 or
		nt.x>256 or nt.y>137 
	then
		nt.dead=true
	end
end

function draw_note(nt)
	spr(8+nt.kind,
		nt.x-nt.w,
		nt.y+sin(nt.t/30)*3-nt.h)
end

function update_camera()
	if cam.kt>0 then
		cam.kt-=1
	else
		cam.kx*=.4
		cam.ky*=.4
	end
	
	if cam.st>0 then
		cam.st-=1
		local r=rnd()
		cam.sx=cos(r)*cam.sm
		cam.sy=sin(r)*cam.sm
	else
		cam.sx=0
		cam.sy=0
	end
end

function cam_pos()
	return cam.kx+cam.sx,
		cam.ky+cam.sy
end

function cam_shake(mag,frames)
	cam.sm=mag or 0
	cam.st=frames or 0
end

function cam_knock(x,y,frames)
	cam.kx=x or 0
	cam.ky=y or 0
	cam.kt=frames or 1
end

sleept=0
function sleep(t)
	sleept=t
end
-->8
-- util

-- math
function mag(x,y)
	return sqrt(x*x+y*y)
end

function mag2(x,y)
	return x*x+y*y
end

function norm(x,y)
	local l=mag(x,y)
	if (l>0) return x/l,y/l
	return 0,0
end

function dist(x1,y1,x2,y2)
	return mag(x2-x1,y2-y1)
end

function clamp(v,mn,mx)
	mn=mn or 0
	mx=mx or 1
	if (mn>mx) mn,mx=mx,mn
	return max(min(v,mx),mn)
end

-- random

function rndr(mn,mx)
	if (mn>mx) mn,mx=mx,mn
	return mn+rnd(mx-min)
end

function irnd(mx)
	return flr(rnd(flr(mx)))
end

function irndr(mn,mx)
	if (mn>mx) mn,mx=mx,mn
	return mn+irnd(mx-mn)
end

-- clear array
function clra(arr)
	local n=#arr
	for i=1,n do
		arr[i]=nil
	end
end

-- fast deletion of an array of
-- indices
function idelfa(arr, idx)
	local l = #arr

	for i in all(idx) do
		arr[i] = nil
	end
	if (#idx == l) return
	for i = 1, l do
		if arr[i] == nil then
			while not arr[l]
				and l > i
			do
				l -= 1
			end
			if i ~= l then
				arr[i] = arr[l]
				arr[l] = nil
			else return end
		end
	end
end

__gfx__
00000000077700000000007077770000000000777700000000000077770000000000000000770770000000000000000000000000000000000000000000000000
00000000777777777777777077770000000000777700000000000077770000000007777707777777000000000000000000000000000000000000000000000000
00700700777777777777777077770000007777777777770000777777777777000007000707777777000000000000000000000000000000000000000000000000
00077000777777007770000077770000007777777777770000777777777777000007000700777770000000000000000000000000000000000000000000000000
00077000777770000000000000000000007700777700770000707707707707000007000700077700000000000000000000000000000000000000000000000000
00700700777000000000000000000000007000077000070000770077770077000777077700077700000000000000000000000000000000000000000000000000
00000000770000000000000000000000777700777700777777707707707707770777077700007000000000000000000000000000000000000000000000000000
00000000000000000000000000000000777777777777777777777777777777770777077700000000000000000000000000000000000000000000000000000000
70000007000000000000000000000000777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000000000000777700000000777777777777777777770000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000007700000000777700777777777777770000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007770000007770000777770077777000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007777000077770000777700007777000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000007777777777770000777777777777000000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000000000000000000777700000000000077770000000000000000000000000000000000000000000000000000000000000000000000
70000007000000000000000000000000000000777700000000000077770000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001c6501d6501c6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
