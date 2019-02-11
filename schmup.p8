pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	plr=player:new()
	bullets={}
	stars={}
	
	star_col={11,12,10,9,8}
	star_col={5,6,7,5,6,7}
	star_col={8,12,10,10,10,10}
	star_cl_ct=18
	star_cl_min=3
	star_cl_max=5
	star_cluster_size=3
	star_seed=200
	star_r=rgen(star_seed)
	for i=1,star_cl_ct do
		st=flr(star_r:next(#star_col))+1
		local cx,cy,cz=star_r:next(-40,40),
			star_r:next(-30,30),
			star_r:next(25,40)
			
		local seed=star_seed+i*100+st*10
		add(stars,{
			cx=cx,cy=cy,cz=cz,
			r=rgen(seed),
			seed=seed,
			st=st,
			spd=star_r:next()+0.5
		})
	end

	gm={
		lbox={
			f=0,height=16,targ=0,
			bg=0x1.a5a5,fg=9
		},
		star_speed=10,
		player=plr,
	}

	
	
	
	poke(0x5f2d,1)
	
	sequences={}
	sequence(seq_player_intro)
end

function is_dev() return peek(0x5f2d)~=0 end

function keypressed(key)
	if key=="f" then
		gm.focus_target=toggle(
			gm.focus_target,1,0)
	elseif key=="=" then
		gm.player.gun_level+=1
	elseif key=="-" then
		gm.player.gun_level-=1
	end
end

--[[function _update()
	update(1/30)
end]]

function _update60()
	update(1/60)
end

function update(dt)
	gm.dt=dt
	_watches={}

	if is_dev() then
		-- pump the keypress queue
		while stat(30) do
			keypressed(stat(31))
		end
	end

	for seq in all(sequences) do
		if costatus(seq)=="suspended"
		then
			assert(coresume(seq))
		else
			del(sequences,seq)
		end
	end

	foreach(stars,
		function(s)
			s.cx-=gm.star_speed*gm.dt
			if s.cx<-40 then
				s.cx+=80
				s.cy=s.r:next(-30,30)
				s.cz=s.r:next(25,40)
				s.seed=flr(s.r:next(1000))
				s.r:reset(0,s.seed)
			end
		end
	)
	
	gm.lbox.f=lerp(gm.lbox.f,
		gm.lbox.targ,dt*5)

	plr:update(dt)
	
	foreach(bullets,
		function(b) b:update(dt) end)
end

function sequence(seq)
	assert(type(seq)=="function")
	add(sequences,cocreate(seq))
end

function _draw()
	cls()
	
	-- stars
	sr=rgen()
	
	for cl in all(stars) do
		sr:reset(0,cl.seed)
		for j=1,flr(sr:next(3,8)) do
			local sx,sy,sz=cl.cx,cl.cy,cl.cz

			local vx,vy,vz=sr:next(-1,1),
				sr:next(-1,1),
				sr:next(-1,1)

			vx,vy,vz=norm3(vx,vy,vz)
			local rad=sr:next(1,4)
			sx+=vx*rad
			sy+=vy*rad
			sz+=vz*rad
			
			local px0,py0=64+64*sx/sz,
				64+64*sy/sz
			
			local px1,py1=px0+gm.star_speed/100,py0
			
			line(px0,py0,px1,py1,6)
		end
	end
	
	plr:draw()	
	foreach(bullets,function(b) b:draw() end)
	
	--spr(20,60,60)
	
	letterbox(
		gm.lbox.f*gm.lbox.height,
		gm.lbox.bg,gm.lbox.fg)
	
	draw_watch()
	
	if is_dev() then
		circ(stat(32),stat(33),1,11)
	end
end

function letterbox(h,bg,fg)
	h=h or 16
	bg=bg or 0
	fg=fg or bg
	
	if h>0.5 then
		-- top

		rectfill(0,-1,127,h-1,bg)
		line(0,h,127,h,fg)
		local m="hyperdrive active"
		print(m,centerx(m),h-14,7)
	
		-- bottom
		rectfill(0,129-h,127,128,bg)
		line(0,128-h,127,128-h,fg)
		local m="please relax"
		print(m,centerx(m),130-h+8,7)
		spr(6,92,132-h,2,2)
	end
end

function centerx(msg)
	return 64-#msg*2
end

player={
	id=0,
	x=24,y=64,
	w=4,h=4,
	dx=0,dy=0,
	move_speed=48,
	burst_ct=3,
	burst_ivl=5,
	guns={
		{
			shot_sp=8,
			ship_sp=17,
			burst_ct=1,
			burst_ivl=0,
		},
		{
			shot_sp=12,
			ship_sp=18,
			burst_ct=3,
			burst_ivl=14,
		},
		{
			shot_sp=24,
			ship_sp=19,
			burst_ct=3,
			burst_ivl=7,
		},
	},
	gun_level=1,
	t_shot=0,
	n_shot=0,
	lock_input=false,
}

function player:new(p)
	self.__index=self
	return setmetatable(p or {},
		self)
end

function player:update(dt)
	local lock=self.lock_input

	local mx,my=input_xy(self.id)
	
	if (lock) mx,my=0,0
	
	local spd=32
	self.x+=mx*self.move_speed*dt
	self.y+=my*self.move_speed*dt
	
	self.x+=self.dx*dt
	self.y+=self.dy*dt
	
	if (self.t_shot>0) self.t_shot-=1
	
	local gun=self.guns[mid(self.gun_level,1,#self.guns)]
	local burst_ct=gun.burst_ct
	local burst_ivl=gun.burst_ivl
	
	if not lock and btn(4,self.id)
	then
		if self.n_shot<burst_ct and
			self.t_shot<=0
		then
			make_bullet(plr.x+3,plr.y+1,gun.shot_sp)
			self.n_shot+=1
			self.t_shot=burst_ivl
		end
	else
		self.n_shot=0
		self.t_shot=0
	end
end

function player:draw()

	if gm.star_speed/100>0.2 then
		fillp(0xf0f0)
 	local trail_col={8,9,10,1}
 	local th=flr(gm.star_speed/100)
 	local tx,ty=self.x-5,64-th*#trail_col/2
 	for i=1,#trail_col do
 		local y=ty+(i-1)*th
 		rectfill(0,y,127,y+th-1,trail_col[i])
 	end
 	fillp()
 end

	local gun=self.guns[mid(self.gun_level,1,#self.guns)]
	spr(gun.ship_sp,self.x-self.w,self.y-self.h)
	spr(48+(t()*16)%4,self.x-self.w-6,self.y-self.h) 	
end

function seq_player_intro()
	gm.star_speed=0
	gm.lbox.targ=0

	p=gm.player

	p.lock_input=true
	p.x=24
	p.y=64
	p.dx=0
	
	wait_sec(1)
	
	local warp_star_speed=750
	gm.lbox.targ=1.5
	p.dx=100
	local targ=24
	
	yield()
	
	do_until(
 	function()
 		p.dx-=ceil(p.dx*0.5*gm.dt)
 		p.dx=max(p.dx,0)
 		--gm.star_speed-=100*gm.dt
 		gm.star_speed=move_to(
 			gm.star_speed,
 			warp_star_speed,
 			5000*gm.dt)
 	end,
 	function()
 		return p.dx==0
 	end
 )
	
	wait_sec(1)
	local mark=p.x
	
	do_until(
 	function()
 		p.x=move_to(p.x,targ,40*gm.dt)
 		gm.star_speed=lerp(warp_star_speed,20,ilerp(mark,targ,p.x))
 		gm.lbox.targ=move_to(gm.lbox.targ,0,2*gm.dt)
 	end,
 	function()
 		return p.x==targ
 	end
 )

	gm.lbox.targ=0
	p.dx=0
	
	p.lock_input=false
end

bullet={
	x=0,y=0,
	dx=0,dy=0,
	t0=0
}

function bullet:new(b)
	self.__index=self
	return setmetatable(b or {},
		self)
end

function bullet:update(dt)
	self.x+=self.dx*dt
	self.t0+=dt
end

function bullet:draw()
	spr(self.sp+(self.t0*15)%4,self.x-4,self.y-4)
end

function make_bullet(x,y,sp)
	sfx(gm.player.gun_level-1)
	return add(bullets,bullet:new(
		{x=x,y=y,dx=144,sp=sp}))
end


-->8
function input_xy(p)
	p=p or 0
	local x,y=0,0
	if (btn(0,p)) x-=1
	if (btn(1,p)) x+=1
	if (btn(2,p)) y-=1
	if (btn(3,p)) y+=1
	return x,y
end

function input_dir(p)
	local ix,iy=input_xy(p)
	return norm(ix,iy)
end

function len(x,y,z)
	z=z or 0
	return sqrt(x*x+y*y+z*z)
end

function norm(x,y)
	if (x==0 and y==0) return 0,0
	local l=len(x,y)
	return x/l,y/l
end

function norm3(x,y,z)
	if (x==0 and y==0 and z==0) return 0,0,0
	local l=len(x,y,z)
	return x/l,y/l,z/l
end

function blink(ivl,gt)
	gt=gt or t()
	return gt%(ivl*2)<ivl
end

function lerp(a,b,t)
	return a+(b-a)*t
end

function ilerp(a,b,v)
	if (b==a) return 1
	return (v-a)/(b-a)
end

function toggle(v,on,off)
	on=on or true
	off=off or false
	if v==on then
		return off
	else
		return on
	end
end

function unpack(t,from,to)
	if (not t) return {}
	from=from or 1
	to=to or #t
	if (from>to) return
	return t[from],unpack(t,from+1,to)
end

function pow(x,a)
	if (a==0) return 1
	if (a<0) x,a=1/x,-a
	local ret,a0,xn=1,flr(a),x
	a-=a0
	while a0>=1 do
		if (a0%2>=1) ret*=xn
		xn,a0=xn*xn,shr(a0,1)
	end
	while a>0 do
		while a<1 do x,a=sqrt(x),a+a end
		ret,a=ret*x,a-1
	end
	return ret
end

_watches={}

function watch(msg)
	add(_watches,msg)
end

function draw_watch(col)
	col=col or 11
	local n=#_watches
	for i=0,n-1 do
		print(_watches[i+1],
			0,i*6,col)
	end
end

function move_to(from,to,delta)
	if from==to then
		return from
	elseif from<to then
		return min(to,from+delta)
	else
		return max(to,from-delta)
	end
end

function accel_to(from,to,vel,accel,maxdelta)
	vel=vel or 0
	maxdelta=maxdelta or 32767
	if from<to then
		local a=accel
		if (vel<0) a*=2
		vel+=a
	elseif from>to then
		local a=accel
		if (vel>0) a*=2
		vel-=a
	end
	vel=mid(-maxdelta,vel,maxdelta)
	return from+vel,vel
end
-->8
function wait_pred(pred)
	while not pred() do
		yield()
	end
end

function wait_frames(n)
	while n>0 do
		n-=1
		yield()
	end
end

function wait_sec(s)
	while s>0 do
		s-=gm.dt
		yield()
	end
end

function do_for_frames(fn,n)
	local n,f=n or 1,0
	while f<n do
		fn(f)
		f+=1
		yield()
	end
end

function do_for_sec(fn,s)
	s=s or 0
	while s>0 do
		fn()
		s-=gm.dt
		yield()
	end
end

function do_until(fn,pred)
	while not pred() do
		fn()
		yield()
	end
end
-->8
-- xorshift16 sort of
function rgen(seed,ct)
	seed=seed or 1
	ct=ct or 0
	local ret={
		seed=seed,
		sx=seed,
		count=0,
		_next=function(self)
			self.count+=1
			self.sx=bxor(self.sx,shl(self.sx,7))
			self.sx=bxor(self.sx,shr(self.sx,9))
			self.sx=bxor(self.sx,shl(self.sx,8))
			return self.sx
		end,
		next=function(self,mn,mx)
			if not mn then
			 mn,mx=0,1
			elseif not mx then
				mx,mn=mn,0
			elseif mx<mn then
				mn,mx=mx,mn
			end
			
			local f=(self:_next()/32767+1)/2
			return f*(mx-mn)+mn
		end,
		reset=function(self,ct,seed)
			ct=ct or 0
			self.seed=seed or self.seed
			self.state=self.seed
			self.count=0
			for i=1,ct do
				self:next()
			end
		end,
		clone=function(self)
			return rgen(self.seed,self.count)
		end
	}
	for i=1,ct do ret:next() end
	return ret
end
__gfx__
0000000020000000c000000010000000100000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
0000000044211000ccc770001117700011111000000000000000000007000000000000000000000000000000000000000ccc9900000cc9900ccc9900cccc9900
0070070094429a00cccc770011117700111177000000000007777777777777000000cc900000cc900000cc900000cc9000ccc999000ccc9900ccc9990cccc999
00077000a94219a09cccccc0911111109111111000000000070000007000070000ccc99700ccc99700ccc99700ccc997000cc9970000cc97000cc99700cc9997
00077000a942111177777777777777771111111100000000007000070000700000ccc99700ccc99700ccc99700ccc997000cc9970000cc97000cc99700cc9997
00700700944211aa77ccc79777111797777777970000000000077777777700000000cc900000cc900000cc900000cc9000ccc999000ccc9900ccc9990cccc999
0000000044209a9accc009991110099977107999000000000000777777700000000000000000000000000000000000000ccc9900000cc9900ccc9900cccc9900
0000000020000000cc00000011000000110000000000000000000777770000000000000000000000000000000000000000000000000000000000000000000000
c0000000c0000000c0000000c0000000008e000000a9000000000077700000000077790000097700009777009007770000000000000000000000000000007700
cd000000ccccc000ccccc000ccccc00000788e00007aa9000000000700000000700c97700007c770007c7770070c7790000cc77000000000000cc7700000c770
cdcccc00cccc7700cccc7700cccc77007787778077a777a0000000070000000007c7c7779c7cc77907ccc7997cccc97700cccc7700000c7000cccc77000ccc77
cdddccc09cccccc09cccccc09cccccc00e88887e09aaaa79000000070000000007c777797c7c779907cc79777ccc9777000ccc790000cc79000ccc7900ccc779
cccddddd7777777777777777777777770e88887e09aaaa7900000007000000000c9c777907cc77999ccc79770ccc9777000ccc790000cc79000ccc7900ccc779
cddcd5d577ccccc777c7c997779797977787778077a777a000000007000000007ccc77770cc7c7790c7cc79907ccc97700cccc7700000c7000cccc77000ccc77
cddc5555ccc000007cc0000079c0099900788e00007aa9000000007770000000000c97700007c770007c7770070c7790000cc77000000000000cc7700000c770
ccc00000cc000000cc000000cc000000008e000000a9000000007777777000000007790000977700900777000077770000000000000000000000000000007700
000000000000000000000000000000000000aaaaaaa000000000eeeeeee000000000000000000000000000000000000000099900000000000009990009999900
000000000000000000000000000000000000aaaa000a00000000eeee000e000000000000000000000000000000000000000c9990000cc990000c999000099990
000000000000000000cccc00000000000aaaa77aaa0000000eeee77eee0000000000000000000000000000000000000000ccc999000ccc9900ccc99900cc9999
00000d00000ddd000ccddd00000222000a999777aaa000000e888777eee0000000000000000000000000000000000000000cc9970000cc97000cc9970cc99997
00000d00000ddd000ccddd0000022200aa9979777aa00000ee8878777ee0000000000000000000000000000000000000000cc9970000cc97000cc9970cc99997
000000000000000000cccc0000000000a999999777aaa000e888888777eee0000000000000000000000000000000000000ccc999000ccc9900ccc99900cc9999
00000000000000000000000000000000a99999777777aaa0e88888777777eee000000000000000000000000000000000000c9990000cc990000c999000099990
00000000000000000000000000000000a9779797777777aae8778787777777ee0000000000000000000000000000000000099900000000000009990009999900
00000000000000000000000000000000a9779797777777aae8778787777777ee0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000a99999777777aaa0e88888777777eee00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000770000000000a999999777aaa000e888888777eee0000000000000000000000000000000000000000000000000000000000000000000
00000c00000077000007cc0000007700aa9979777aa00000ee8878777ee000000000000000000000000000000000000000000000000000000000000000000000
00000c00000077000007cc00000077000a999777aaa000000e888777eee000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000007700000000000aaaa77aaa0000000eeee77eee0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000aaaa000a00000000eeee000e00000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000aaaaaaa000000000eeeeeee000000000000000000000000000000000000000000000000000000000000000000000
00cccc00000ccc00c00ccc0000cccc00000ccc0000cccc00c00ccc00000000000000000000000000000000000000000000000000000000000000000000000000
c001ccc0000c1cc00c01ccc0c001ccc0000c1cc000c1ccc00c01ccc0000000000000000000000000000000000000000000000000000000000000000000000000
0c1c1cccc1c11cccc1111cc70c1c1cccc1c11ccc0c111cc7c1111cc7000000000000000000000000000000000000000000000000000000000000000000000000
0c1cccc7c1c1ccc7c111cc770c1cccc7c1c1ccc70c11cc77c111cc77000000000000000000000000000000000000000000000000000000000000000000000000
01c1ccc70c11ccc70111cc7701c1ccc70c11ccc7c111cc770111cc77000000000000000000000000000000000000000000000000000000000000000000000000
c111cccc011c1ccc0c111cc7c111cccc011c1ccc01c11cc70c111cc7000000000000000000000000000000000000000000000000000000000000000000000000
0001ccc0000c1cc00c01ccc00001ccc0000c1cc000c1ccc00c01ccc0000000000000000000000000000000000000000000000000000000000000000000000000
000ccc0000cccc0000cccc00000ccc0000cccc00000ccc0000cccc00000000000000000000000000000000000000000000000000000000000000000000000000
00777700000777007007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70017770000717700701777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07171777717117777111177900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07177779717177797111779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01717779071177790111779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71117777011717770711177900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00017770000717700701777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700007777000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003405034050270002a0002b000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002205022050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001105011050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
