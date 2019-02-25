pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function clone(tbl)
	local ret={}
	for k,v in pairs(tbl) do
		ret[k]=v
	end
	return ret
end

function _init()
	plr=player:new({x=24,y=64})
	bullets=system:new("bullets")
	stars=system:new("stars")
	enemies=system:new("enemies")

	colliders=system:new("colliders")
	colliders.make=function(self,owner,param)
		if (not param) return nil
		param.owner=owner
		return self:ins(
			collider:new(clone(param)))
	end
	
	colliders.ins=function(self,coll)
		local l=coll:left()
		local n=#colliders
		local i=0
		for i=1,n do
			if l>=colliders[i]:right() then
				ins(colliders,i,coll)
				return coll,i
			end
		end
		colliders[n+1]=coll
		return coll,n+1
	end
	
--	register_enemies()
	
	star_col={11,12,10,9,8}
	star_col={5,6,7,5,6,7}
	star_col={8,12,10,10,10,10}
	star_cl_ct=30
	star_cl_min=12
	star_cl_max=50
	star_cl_x_min=-100
	star_cl_x_max=100
	star_cl_y_min=-30
	star_cl_y_max=30
	star_cl_z_min=25
	star_cl_z_max=40
	star_cl_rad_min=2
	star_cl_rad_max=6
	star_cluster_size=3
	star_seed=202
	star_r=rgen(star_seed)
	for i=1,star_cl_ct do
		st=flr(star_r:next(#star_col))+1
		local cx,cy,cz=
			star_r:next(star_cl_x_min,star_cl_x_max),
			star_r:next(star_cl_y_min,star_cl_y_max),
			star_r:next(star_cl_z_min,star_cl_z_max)
			
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
		star_speed_impulse=12,
		star_speed_hyper=750,
		star_speed=10,
		player=plr,
		move_speed=20,
	}
	
	poke(0x5f2d,1)
	
	sequences={}

	gm.star_speed=gm.star_speed_impulse
	
	for i=0,30 do
		add_enemy(ufo,130+i*24,rnd(64)+31)
	end
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
	elseif key=="h" then
		sequence(seq_hyper_drive)
	elseif key=="l" then
		_logs={}
	end
	
	gm.player.gun_level=mid(1,3,
		gm.player.gun_level)
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
			--coresume(seq)
		else
			del(sequences,seq)
		end
	end

	foreach(stars,
		function(s)
			s.cx-=gm.star_speed*gm.dt
			if s.cx<-100 then
				s.cx+=200+s.r:next(5)
				s.cy=s.r:next(star_cl_y_min,star_cl_y_max)
				s.cz=s.r:next(star_cl_z_min,star_cl_z_max)
				s.seed=flr(s.r:next(10000))
				s.r:reset(0,s.seed)
			end
		end
	)
	
	gm.lbox.f=lerp(gm.lbox.f,
		gm.lbox.targ,dt*5)

	plr:update(dt)
	
	enemies:pump_adds()
	bullets:pump_adds()
	colliders:pump_adds()
	
	foreach(bullets,
		function(b)
			b:update(dt)
			if band(b.flags,b.k.flag_del)~=0 then
				--bullets:del(b)
				b.on_del(b)
				del(bullets,b)
			end
		end)
	
	foreach(enemies,
		function(e)
			e:update(dt)
			if e.x<-128 then
				enemies:del(e)
			elseif not e.awake
				and e.x<256
			then
				e:on_awake()
			end
		end)
			
	check_collisions()
		
	enemies:pump_dels()
	bullets:pump_dels()
	colliders:pump_dels()
		
	watch_stat(0)
	watch_stat(1)
	watch_stat(2)
	watch(#colliders)
--	watch("pos:"..gm.player.x..","..gm.player.y)
end

_stat_labels={
	{l="mem",s=1/204.8},
	{l="cpu",s=100},
	{l="drw",s=100},
}

function watch_stat(s,label)
	local lb=_stat_labels[s+1]
	local label,scl=lb.l,lb.s
	local sperc=band(stat(s)*scl,0xffff)
	local col=12
	if sperc>=45 then
		col=8
	elseif sperc>=35 then
		col=9
	end
	watch(label..":"..sperc.."%",col)
end

function sequence(seq)
	assert(type(seq)=="function")
	add(sequences,cocreate(seq))
end

function defer(fn,sec)
	sequence(function()
		wait_sec(sec)
		fn()
	end)
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

--			vx,vy,vz=norm3(vx,vy,vz)
			local rad=sr:next(
					star_cl_rad_min,
					star_cl_rad_max)
			sx+=vx*rad
			sy+=vy*rad
			sz+=vz*rad
			
			local px0,py0=64+64*sx/sz,
				64+64*sy/sz
			
			local px1,py1=px0+gm.star_speed/100,py0
			
			local c=6
			if (sz>35) c=5
			line(px0,py0,px1,py1,c)
		end
	end
	
	plr:draw()
	foreach(enemies,function(e) e:draw() end)
	foreach(bullets,function(b) b:draw() end)
	
	draw_colliders()
	
	-- hud
	
	rectfill(31,-1,31+64,6,0)
	rect(31,-1,31+64,6,7)
	
	local bg,fg=3,11
	for i=0,plr.max_health-1 do
		local x,y=33+i*2,1
		local c=bg
		if (i<plr.health) c=fg
		line(x,y,x,y+3,c)
	end
	
	letterbox(
		gm.lbox.f*gm.lbox.height,
		gm.lbox.bg,gm.lbox.fg)
	
	draw_watch()
	draw_log()
	
	if is_dev() then
		circ(stat(32),stat(33),1,11)
	end
end

function add_enemy(etype,x,y)
	local ret=etype:new({x=x,y=y})
	return enemies:add_now(ret)
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
		print(m,56-#m*2,130-h+8,7)
		spr(6,90,132-h,2,2)
	end
end

function centerx(msg)
	return 64-#msg*2
end

-- class player
player={
	id=0,
	x=24,y=64,
	w=4,h=4,
	dx=0,dy=0,
	max_health=16,
	health=16,
	move_speed=48,
	guns={
		{
			shot_sp=8,
			ship_sp=17,
			burst_ct=3,
			burst_ivl=0.1,
			fire=function(self)
				fire_bullet(0,144,0,{
					x=plr.x+3,y=plr.y+1,
					sp=self.shot_sp,
					t_life=1,
					colldef={
						layer=3,
						ox=2,oy=0,
						w=2,h=3
					}
				})
			end,
		},
		{
			shot_sp=12,
			ship_sp=18,
			burst_ct=2,
			burst_ivl=12/60,
			speed=144,
			fire=function(self)
				local bullet={
					x=plr.x+3,--y=plr.y+1,
					sp=self.shot_sp,
					t_life=0.75,
					colldef={
 					layer=3,
 					ox=0,oy=0,w=3,h=4
 				}
				}
				local top=merge(bullet,
					{y=plr.y-2})
				local bot=merge(bullet,
					{y=plr.y+3})
				fire_bullet(0,144,0,top)
				fire_bullet(0,144,0,bot)
			end
		},
		{
			shot_sp=24,
			ship_sp=19,
			burst_ct=3,
			burst_ivl=8/60,
			speed=144,
			fire=function(self)
				local start,spacing=plr.y-3,4
				local bullet={
					x=plr.x+3,y=plr.y+1,
					sp=self.shot_sp,
					t_life=1,
					colldef={
 					layer=3,
 					ox=0,oy=0,w=3,h=4
 				}
				}
				
				local ang=8/360
				for i=0,2 do
					local delay=0.1
					fire_bullet(ang+i*-ang,144,
						0,
						merge(bullet,{
							y=start+spacing*i,
						}))
				end
--[[				
				for i=-5,5 do
					local ang=i*5/360
					
					fire_bullet(ang,144,rnd(delay),clone(bullet))
				end
				]]
			end
		},
	},
	gun_level=1,
	t_shot=0,
	n_shot=0,
	t_charge=0,
	flash_ivl=0,
	flash_pal={
		{12,7},
		{7,9},
		{9,7},
		{1,9},
	},
	charge_delay=0.25,
	charge_time=0.75,
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
	
	if (self.t_shot>0) self.t_shot-=dt
	
	local gun=self.guns[mid(self.gun_level,1,#self.guns)]
	local burst_ct=gun.burst_ct
	local burst_ivl=gun.burst_ivl
	
	if not lock and btn(4,self.id)
	then
		if (burst_ct<=0 or
			   self.n_shot<burst_ct)
		then
 		if self.t_shot<=0	then
 			gun:fire()
 			self.n_shot+=1
 			self.t_shot=burst_ivl
 		end
 	else
 		-- if holding fire after
 		-- burst has finished
 		-- increment charge time
 		-- if charge time passes
 		-- delay threshold start
 		-- 'charging' flash interval
 		-- if charge time passes
 		-- delay+full charge time
 		-- start the 'charged' flash
 		self.t_charge+=dt
 		if self.t_charge>=self.charge_delay+self.charge_time then
 			self.flash_ivl=1/8
 		elseif self.t_charge>=self.charge_delay then
 			self.flash_ivl=1/4
 		end
 	end
	else
		-- if was charged, on release
		-- then fire the charged shot
		if self.t_charge>=self.charge_delay+self.charge_time then
			-- charge shot
			fire_bullet(0,144/2,0,
				{
					x=plr.x+3,y=plr.y+1,
					--sp=flr(rnd(3))*2+96,
					sp=98,
					w=8,h=8,
					sw=2,sh=2,
					anim_f=1,
					t_life=10,
					pal_sets={
						{{5,0},{6,9},{7,7}},
						{{5,9},{6,7},{7,0}},
						{{5,7},{6,0},{7,9}},
					},
					pal_s=20,
				})
		end
	
		self.n_shot=0
		self.t_shot=0
		self.t_charge=0
		self.flash_ivl=0
	end
	self.t_charge=mid(self.t_charge,
		0,self.charge_delay+self.charge_time)
	
	--watch("charge:"..self.t_charge)
end

function player:draw()

	if gm.star_speed>200 then
--		fillp(0xf0f0)
 	local trail_col={7,8,9,1,1,1,1,1,8,9,7}
 	local tn=#trail_col
 	local th=flr(gm.star_speed/200)
		local ty=64-th*tn/2

		if th>0 then
 		for i=1,#trail_col do
 			local y=ty+(i-1)*th
 			rectfill(0,y,127,y+th-1,trail_col[i])
	 	end
	 end
 		
--[[ 	local w=ceil(128/3)
 	for i=0,tn do
 		local ii=(i+1)%tn
 		local x=(i*w-t()*64)%(128+w)-w
 		rectfill(x,ty,x+w,ty+th*4,trail_col[ii+1])
 	end]]
 	
 	fillp()
 end
 
 if self.flash_ivl>0
 	and blink(self.flash_ivl)
 then
 	for p in all(self.flash_pal) do
 		pal(p[1],p[2])
 	end
 end
 
	local gun=self.guns[mid(self.gun_level,1,#self.guns)]
	spr(gun.ship_sp,self.x-self.w,self.y-self.h)
	
	pal()
	
	if self.t_charge>self.charge_delay then
		local s=self.t_charge/(self.charge_time+self.charge_delay)
		spr_scale(98,plr.x+3,plr.y+1,s,2,2)
	end
	
	spr(48+(t()*16)%4,self.x-self.w-6,self.y-self.h) 	

end

function seq_hyper_drive()
	if gm.hyper_lock then
		return
	end
	
	gm.hyper_lock=true

	gm.lbox.targ=0

	p=gm.player

	p.lock_input=true
	p.dx,p.dy=0,0

	do_until(
		function()
			p.x=lerp(p.x,24,3*gm.dt)
			p.y=lerp(p.y,64,3*gm.dt)
			gm.star_speed=lerp(
				gm.star_speed,0,2*gm.dt)
				watch(p.x..","..p.y)
		end,
		function()
			return approx(p.x,24,1)
				and approx(p.y,64,1)
				and gm.star_speed<1
		end)
	
	gm.star_speed=0
	
	wait_sec(1)
	
	gm.lbox.targ=1.5
	p.dx=250
	local targ=24

	do_until(
 	function()
 		p.dx-=ceil(p.dx*2.4*gm.dt)
 		p.dx=max(p.dx,0)
 		--gm.star_speed-=100*gm.dt
 		gm.star_speed=move_to(
 			gm.star_speed,
 			gm.star_speed_hyper,
 			5000*gm.dt)
 	end,
 	function()
 		return p.dx==0
 	end
 )
	
	wait_sec(2)
	
	local mark=p.x
	
	do_until(
 	function()
 		p.x=move_to(p.x,targ,40*gm.dt)
 		gm.star_speed=lerp(gm.star_speed_hyper,gm.star_speed_impulse,ilerp(mark,targ,p.x))
 		gm.lbox.targ=move_to(gm.lbox.targ,0,2*gm.dt)
 	end,
 	function()
 		return p.x==targ
 	end
 )
 
	gm.star_speed=gm.star_speed_impulse 
	gm.lbox.targ=0
	p.dx=0
	
	p.lock_input=false
	
	gm.hyper_lock=false
end

-- class bullet
bullet={
	k={
		flag_del=1
	},
	x=0,y=0,
	w=4,h=4,
	dx=0,dy=0,
	sw=1,sh=1,
	anim_f=4,
	anim_s=15,
	t0=0,
	t_life=2,
	flags=0,
	coll=nil,
	damage=1,
	on_collide=function(self,other)
		self.flags=bullet.k.flag_del
	end,
	on_del=function(self)
		if self.coll then
			colliders:del_now(self.coll)
			self.coll=nil
		end
	end
}

function bullet:new(b)
	self.__index=self
	return setmetatable(b or {},
		self)
end

function bullet:update(dt)
	self.x+=self.dx*dt
	self.y+=self.dy*dt
	self.t0+=dt
	self.t_life-=dt
	if self.t_life<=0 then
		self.flags=self.k.flag_del
	end
end

function bullet:draw()
	if self.pal_sets then
		local pi=flr(self.t0*self.pal_s)%#self.pal_sets
		local ps=self.pal_sets[pi+1]
		for p in all(ps) do
			pal(p[1],p[2])
		end
	end

	local frame=self.sp+
		(self.t0*self.anim_s)%self.anim_f
	spr(frame,
		self.x-self.w,self.y-self.h,
		self.sw,self.sh)
	
	pal()
end

bid=0
function fire_bullet(ang,speed,delay,param)
	local make=function(ang,speed,param)
		param.dx=cos(ang)*speed
		param.dy=sin(ang)*speed
		param.bid=bid
		bid+=1
		local blt=bullet:new(param)
		bullets:add_now(blt)
		if blt.colldef then
			blt.coll=colliders:make(blt,blt.colldef)
		end
	end
	defer(
		function()
			make(ang,speed,param)
		end,
		delay)
end

powerup={
	x=0,y=0,
	dx=-20,dy=0,
	w=4,h=4,
}

function powerup:new(p)
	self.__index=self
	return setmetatable(p or {},
		self)
end

function powerup:update(dt)
	
end

-- layers
-- 1: player
-- 2: enemy
-- 3: player article
-- 4: enemy article

-- collision detection
l_masks={}
l_masks[1]=0b0000000000001010
l_masks[2]=0b0000000000000101
l_masks[3]=0b0000000000000010
l_masks[4]=0b0000000000000001

collider={
	layer=0,
	ox=0,oy=0, -- offset
	w=0,h=0, -- half width/height
	owner=nil, -- offset from this
												-- owner should have
												-- x,y
}

function collider:new(param)
	self.__index=self
	return setmetatable(
		param or {},self)
end

function collider:left()
	local cx=self:world()
	return cx-self.w
end

function collider:right()
	local cx=self:world()
	return cx+self.w-1
end

function collider:top()
	local _,cy=self:world()
	return cy-self.h
end

function collider:bottom()
	local _,cy=self:world()
	return cy+self.h-1
end

function collider:world()
	if self.owner then
		return self.ox+self.owner.x,
			self.oy+self.owner.y
	else
		return self.ox,self.oy
	end
end

function layer_check(l1,l2)
	if l1==0 or l2==0 then
		return true
	else
		local mask=l_masks[l1] or 0xffff
		return band(mask,shl(1,l2-1))~=0
	end
end

function collider:intersect(other)
	return self:left()<=other:right()
		and self:right()>=other:left()
		and self:top()<=other:bottom()
		and self:bottom()>=other:top()
end

function check_collisions()
	--[[sort(colliders,
		function(a,b)
			return a:left()<b:left()
		end)]]
		
	-- sort
	local n=#colliders
	for xx=1,3 do
 	for i=1,n-1 do
 		if colliders[i]:left()>colliders[i+1]:left() then
 			colliders[i],colliders[i+1]=
 				colliders[i+1],colliders[i]
 		end
 	end
 end
		
	local cmpct=0

	local n=#colliders
	for i=1,n-1 do
		local j=i+1
		local a=colliders[i]
		local r=a:right()
		while j<=n
			and r>=colliders[j]:left()
		do
			local b=colliders[j]
			if layer_check(a.layer,b.layer) then
				cmpct+=1
 			if a:intersect(b) then
 				if a.owner and a.owner.on_collide then
 					a.owner:on_collide(b)
 				end
 				if b.owner and b.owner.on_collide then
 					b.owner:on_collide(a)
 				end
 			end
 		end
 		j+=1
 		
		end
	end
	
	watch("total comp:"..cmpct)
end

function draw_colliders()
	for c in all(colliders) do
		local cx,cy=c:world()
		rect(c:left(),c:top(),
			c:right(),c:bottom(),11)
		pset(cx,cy,8)
	end
end

system={
	name="base",
	verify=true,
}

function system:new(name)
	self.__index=self
	return setmetatable(
		{name=name,rem_q={},add_q={}},
		self)
end

function system:add_now(elem)
	local ret=add(self,elem)
	if ret.on_add then
		ret:on_add()
	end
	return ret
end

function system:del_now(elem)
	if elem then
		if elem.on_del then
			elem:on_del()
		end
		del(self,elem)
	end
end

function system:contains(elem)
	local len=#self
	for i=1,len do
		if self[i]==elem then
			return true
		end
	end
	return false
end

function system:add(elem)
	assert(false,"use something else")
	if verify then
		assert(not self:contains(elem))
	end
	add(self.add_q,elem)
end

function system:del(elem)
	if (elem) add(self.rem_q,elem)
end

function system:pump_adds()
	local len=#self.add_q
	for i=1,len do
		local o=self.add_q[i]
		add(self,o)
		if (o.on_add) o:on_add()
		self.rem_q[i]=nil
	end
end

function system:pump_dels()
	local len=#self.rem_q

	for i=1,len do
		local o=self.rem_q[i]
		
		self.rem_q[i]=nil
		if (o.on_del) o:on_del()
		del(self,o)
	end
end

-->8
-- enemies

enemy={
	k={
		s_idle=0,
		s_active=1,
	},
	awake=false,
	x=0,y=0,
	dx=0,dy=0,
	w=8,h=8, --half width/height
	state=0,
	sp=0,
	sw=1,sh=1,
	max_health=10,
	health=10,
	flash_dur=0.3,
	t_flash=0
}

function enemy:new(e)
	self.__index=self
	return setmetatable(e or {},self)
end

function enemy:on_add()
	self.health=self.max_health	
end

function enemy:on_del()
	colliders:del(self.coll)
end

function enemy:on_collide(other)
	local hit=other.owner
	if hit and hit.damage 
		and self.health>0
	then
		self:on_damage(hit)
	end
end

function enemy:on_damage(source)
	self.health-=1
	self.t_flash=self.flash_dur
	if self.health<=0 then
		enemies:del(self)
	end
end

-- called when enemy gets in
-- range to be "live"
-- add collider and stuff
function enemy:on_awake()
	self.awake=true
	self.coll=colliders:make(self,self.colldef)
end

function enemy:update(dt)
	if self.state==enemy.k.s_idle then
		self.x-=gm.move_speed*dt
		
		if self.x<120 then
			self.state=enemy.k.s_active
		end
		
	elseif self.state==enemy.k.s_active then
		local mv=gm.move_speed
		mv+=25
		self.x-=mv*dt
	end
end

function enemy:draw()
	if self.sp>0 then
		spr(self.sp,self.x-self.w,
			self.y-self.h,
			self.sw,self.sh)
	end
end

eyemonster=enemy:new(
	{sp=36,sw=2,sh=2,
		colldef={layer=2,w=8,h=8}})
		


ufo=enemy:new(
	{sp=71,sw=1,sh=1,w=4,h=4,
		max_health=3,
		colldef={layer=2,w=4,h=4}})

function ufo:update(dt)
	if self.state==enemy.k.s_idle
	then
		enemy.update(self,dt)
	else
		local tx,ty=gm.player.x,gm.player.y
		
	end
end
-->8
function sort(a,lt,n)
	local n=n or #a
	local i=2
	while i<=n do
		local j=i
		while j>1 and lt(a[j-1],a[j]) do
			a[j],a[j-1]=a[j-1],a[j]
			j-=1
		end
		i+=1
	end
end

function ins(arr,idx,elem)
	local n=#arr
	for i=n+1,idx+1,-1 do
		arr[i]=arr[i-1]
	end
	arr[idx]=elem
end

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

function approx(a,b,eps)
	eps=eps or 0.0001
	return abs(a-b)<=eps
end

function ilerp(a,b,v)
	if (b==a) return 1
	return (v-a)/(b-a)
end

function clone(tbl)
	local ret={}
	for k,v in pairs(tbl) do
		ret[k]=v
	end
	return ret
end

function merge(t1,t2)
	local out={}
	for k,v in pairs(t1) do
		out[k]=v
	end
	for k,v in pairs(t2) do
		out[k]=v
	end
	return out
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

function watch(msg,col)
	add(_watches,{msg=tostr(msg),
		col=col or 12})
end

function draw_watch(col)
	col=col or 12
	local n=#_watches
	for i=0,n-1 do
		local w=_watches[i+1]
		print(w.msg,0,i*6,w.col)
	end
end

_logs={}

function log(msg,col)
	add(_logs,{msg=tostr(msg),
		col=col or 6})
	if #_logs>20 then
		for i=1,20 do
			_logs[i]=_logs[i+1]
		end
		_logs[21]=nil
	end
end

function draw_log()
	for i=1,#_logs do
		local l=_logs[i]
		print(l.msg,
			127-#l.msg*4,(i-1)*6,l.col)
	end
end

function halt(msg)
	cls()
	log("halt:"..tostr(msg),8)
	stop()
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

-- sp: sprite in sheet
-- cx: center x pixel coord
-- cy: center y pixel coord
-- scale: 0 invis, 1 normal, 2 double
-- sw: sprite width (def: 1)
-- sh: sprite height (def: 1)

function
spr_scale(sp,cx,cy,scale,sw,sh)
	sw,sh=sw or 1,sh or 1

	if (scale<=0) return
	
	local dw,dh=sw*8*scale,sh*8*scale
	local dx,dy=cx-dw/2,cy-dh/2
	local sx,sy=sp%16*8,flr(sp/16)*8
	
	sspr(sx,sy,sw*8,sh*8,
		dx,dy,dw,dh)
end


-->8
-- todo/notes

-- buckets:
-- 	entities
--		drawables
--		players				
--		enemies
--		bullets
-->8
-- state machine tinkering...

-- states:
--		action (code that runs)
--		transitions:
--			vars to check
--			state to transition to

fsm={
	vars={},
	states={},
	transitions={
		
	}
}

state={
	tick=
	function(self,dt)
		-- code to do stuff
 end,
	transitions={
		
	}
}
__gfx__
0000000020000000c000000010000000100000000000000000000000007000000000000000000000000000000000000000099900000000000009990000000000
0000000044211000ccc7700011177000111110000000000000000000070000000000000000000900000000000000090000019990000119900001999000011990
0070070094429a00cccc770011117700111177000000000007777777777777000001190000017790000119000001779000911999901111990011199900119199
00077000a94219a09cccccc091111110911111100000000007000000700007000111799001177979011177900117797900011997000111970001199700011197
00077000a94211117777777777777777111111110000000000700007000070000111799001177979011177900117797990011997000111970011999700911197
00700700944211aa77ccc79777111797777777970000000000077777777700000001190000017790000119000001779000119999009111999011199900111199
0000000044209a9accc0099911100999771079990000000000007777777000000000000000000900000000000000090000019990000119900001999000011990
0000000020000000cc00000011000000110000000000000000000777770000000000000000000000000000000000000000099900000000000009990000000000
c0000000c0000000c0000000c0000000008e000000a9000000000077700000000077790000097700009777009007770000000000000000000000000000007700
cd000000cc999000cc999000cc99900000788e00007aa900000000070000000070019770000717700071777007017790000cc77000000000000cc7700000c770
cdcccc001c9999001c9999001c9999007787778077a777a000000007000000000717177791711779071117997111197700cccc7700000c7000cccc77000ccc77
cdddccc091ccccc0977cccc0977cccc70e88887e09aaaa79000000070000000007177779717177990711797771119777000ccc790000cc79000ccc7900ccc779
cccddddd7777777777777777777777770e88887e09aaaa79000000070000000001917779071177999111797701119777000ccc790000cc79000ccc7900ccc779
cddcd5d57711177977119779771979797787778077a777a000000007000000007111777701171779017117990711197700cccc7700000c7000cccc77000ccc77
cddc5555ccc000007cc000007cc0000000788e00007aa900000000777000000000019770000717700071777007017790000cc77000000000000cc7700000c770
ccc00000cc000000cc000000cc000000008e000000a9000000007777777000000007790000977700900777000077770000000000000000000000000000007700
00000000000000000000000000000000000000000000000000000000000000000222220009999900033333000000000000099900000000000009990009999900
0000000000000000000000000000000000007777000000000000000000000000228888209aaaaa903bbbbb3000000000000c9990000cc990000c999000099990
000000000000000000cccc000000000007777ee7700000000000000000000000288888209aaaaa903bb333300000000000ccc999000ccc9900ccc99900cc9999
00000d00000ddd000ccddd000002220007666eee770000000000000000000000288222209a9a9a903bb3333000000000000cc9970000cc97000cc9970cc99997
00000d00000ddd000ccddd00000222007766e6eee77000000000000000000000288882209a9a9a903bb3333000000000000cc9970000cc97000cc9970cc99997
000000000000000000cccc00000000007666666eee7770000000000000000000288222209a999a903bbbbb300000000000ccc999000ccc9900ccc99900cc9999
00000000000000000000000000000000766666eeeeee7770000000000000000002222200099999000333330000000000000c9990000cc990000c999000099990
0000000000000000000000000000000076ee6e6eeeeeee7700000000000000000000000000000000000000000000000000099900000000000009990009999900
0000000000000000000000000000000076ee6e6eeeeeee77000000000000000000099000000aa000000000000000000000000000000000000000000000000000
00000000000000000000000000000000766666eeeeee77700000000000000000091111900a7777a000000000000000000ccc9900000cc9900ccc9900cccc9900
000000000000000000007700000000007666666eee77700000000000000000000101101007077070000000000000000000ccc999000ccc9900ccc9990cccc999
000009000000790000079900000079007766e6eee7700000000000000000000091199119a77aa77a0000000000000000000cc9970000cc97000cc99700cc9997
0000090000007900000799000000790007666eee77000000000000000000000091199119a77aa77a0000000000000000000cc9970000cc97000cc99700cc9997
0000000000000000000077000000000007777ee77000000000000000000000000101101007077070000000000000000000ccc999000ccc9900ccc9990cccc999
0000000000000000000000000000000000007777000000000000000000000000091111900a7777a000000000000000000ccc9900000cc9900ccc9900cccc9900
000000000000000000000000000000000000000000000000000000000000000000099000000aa000000000000000000000000000000000000000000000000000
00cccc00000ccc00c00ccc0000cccc00000ccc0000cccc00c00ccc00000000000000000000000000000000000000000000000000000000000000000000000000
c001ccc0000c1cc00c01ccc0c001ccc0000c1cc000c1ccc00c01ccc0000bb0000000000000000000000000000000000000000000000000000000000000000000
0c1c1cccc1c11cccc1111cc70c1c1cccc1c11ccc0c111cc7c1111cc70033bb000000000000000000000000000000000000000000000000000000000000000000
0c1cccc7c1c1ccc7c111cc770c1cccc7c1c1ccc70c11cc77c111cc7703333bb00000000000000000000000000000000000000000000000000000000000000000
01c1ccc70c11ccc70111cc7701c1ccc70c11ccc7c111cc770111cc77566666660000000000000000000000000000000000000000000000000000000000000000
c111cccc011c1ccc0c111cc7c111cccc011c1ccc01c11cc70c111cc7056666600000000000000000000000000000000000000000000000000000000000000000
0001ccc0000c1cc00c01ccc00001ccc0000c1cc000c1ccc00c01ccc0005555000000000000000000000000000000000000000000000000000000000000000000
000ccc0000cccc0000cccc00000ccc0000cccc00000ccc0000cccc00000000000000000000000000000000000000000000000000000000000000000000000000
00777700000777007007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70017770000717700701777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07171777717117777111177900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07177779717177797111779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01717779071177790111779900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71117777011717770711177900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00017770000717700701777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700007777000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000770000000500000055000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000700660070000060000066000006000000000000000000000000000000000000000000000000000000000000000000000000000000000
00705606606507000050050550500500000056077065000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067067760760000006006666006000000760055006700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00576077770675000700777777770070005657066075650000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600667766006000050755555570500006075666657060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067655556760000006756666576000000006677660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05677755557776507656756776576567567566777766576500000000000000000000000000000000000000000000000000000000000000000000000000000000
05677755557776507656756776576567567566777766576500000000000000000000000000000000000000000000000000000000000000000000000000000000
00067655556760000006756666576000000006677660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600667766006000050755555570500006075666657060000000000000000000000000000000000000000000000000000000000000000000000000000000000
00576077770675000700777777770070005657066075650000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067067760760000006006666006000000760055006700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00705606606507000050050550500500000056077065000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000700660070000060000066000006000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000770000000500000055000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003405034050270002a0002b000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002205022050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001105011050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
