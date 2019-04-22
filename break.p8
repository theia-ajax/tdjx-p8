pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

function _init()
	poke(0x5f2d,1)
	
	_log_max=7
	
	gui={
		play_widget={
			x=128-8,y=128-8,
			col=6,
			play_sp=17,pause_sp=18,frame_sp=16,
			sp=0,
			t=0,
			set=function(self,wtype,dur,col)
				self.t=dur
				self.col=col or 6
				if wtype=="play" then
					self.sp=self.play_sp
				elseif wtype=="pause" then
					self.sp=self.pause_sp
				elseif wtype=="frame" then
					self.sp=self.frame_sp
				else
					assert(false)
				end
			end,
			update=function(self,dt)
				if (self.t>0) self.t-=dt
			end,
			draw=function(self)
				if self.t>0 then
					pal(6,self.col)
					spr(self.sp,self.x,self.y)
					pal()
				end
			end
		}
	}
	
	camera_shake_mag=1
	debug_fbf=false
	debug_advance=false
	
	cheat_no_death=false
	cheat_100_power=false
		
	sleep_f=0
	
	add_gamestate("play",
		play_init,play_update,play_draw)
		
	add_gamestate("test_coll",
		test_coll_init,
		test_coll_update,
		test_coll_draw)
		
	set_gamestate("play")
end

function _update60()

	--local dt=0x0000.0888
	local dt=0x0000.0444
	
	while stat(30) do
		keypress(stat(31))
	end
	
	for k,widget in pairs(gui) do
		widget:update(dt)
	end
	
	-- update camera shake
	-- even when play is locked
	-- because it's fucking awful
	-- otherwise
	
	if cam_shake_t>0 then
		cam_shake_t-=dt
	end

	
	if debug_fbf then
		if debug_advance then
			debug_advance=false
		else
			return
		end
	end
	
	if sleep_f>0 then
		sleep_f-=1
		return
	end

	clear_watches()

	tick_sequences()

	gamestate_update(dt)
end

function _draw()
	gamestate_draw()

	if peek(0x5f2d) then
		draw_watches()
		draw_log()
		
		for k,widget in pairs(gui) do
			widget:draw()
		end
	end
end

function keypress(key)
	if key=="n" then
		debug_fbf=not debug_fbf
		if debug_fbf then
			gui.play_widget:set("pause",2,9)
		else
			gui.play_widget:set("play",2,11)
		end
	elseif key=="m" and debug_fbf then
		debug_advance=true
		gui.play_widget:set("frame",0.25,12)
	elseif key=="l" then
		_logs={}
	elseif key=="f" then
		paddle_powerup(paddle,k_ptype_lazer)
	elseif key=="d" then
		paddle_powerup(paddle,k_ptype_wide)
	elseif key=="s" then
		paddle_powerup(paddle,k_ptype_shield)
	elseif key=="a" then
		paddle_powerup(paddle,k_ptype_multi)
	elseif key=="q" then
		paddle_powerup(paddle,k_ptype_super)
	elseif key=="k" then
		cheat_no_death=not cheat_no_death
		log("no death: "..tostr(cheat_100_power))
	elseif key=="j" then
		cheat_100_power=not cheat_100_power
		log("100 power: "..tostr(cheat_100_power))
	elseif key=="b" then
		local b=rnd_elem(balls)
		b.x=20
		b.y=2
		b.angle=7/8
	elseif key=="u" then
		next_powerup(64,64)
	end
end

function camera_shake(dur,mag)
	cam_shake_mag=(mag or 0)*camera_shake_mag
	cam_shake_t=dur or 0
end

function play_init()
	play_lock=false

	k_block_width=4
	k_block_height=2.5
	
	block_c1=0xaa
	block_c2=0x99
	k_block_col=bor(shl(band(block_c2,0xf),4),band(block_c1,0xf))
	
	cam_shake_mag=0
	cam_shake_t=0
	
	blocks={}
	
	local power_ct=0
	
	for y=0,15 do
		for x=0,15 do
			local m=mget(x,y)
		
			local col=12
			local hits=1
			local btype=0
			
			if m==22 then
				btype=1
				power_ct+=1
			else
				hits=m-19+1
			end
			
			if m~=0 then
				add(blocks,{
					x=(x+1)*k_block_width*2,
					y=(y+1)*k_block_height*2,
					w=k_block_width,
					h=k_block_height,
					hits=hits,
					btype=btype,
				})
			end
		end
	end
	
	powers={}
	powers_n=power_ct
	for i=1,powers_n do
		add(powers,rnd_wt(k_powerup_weights))
	end
	shuffle(powers)
	power_idx=0
	
	paddle={
		x=0x49.05f7,y=121,
		dx=0,
		face=1,
		face_ang=0.07,
		accel=100,
		sfrac=0,
		w=10,h=1.5,-- half width/height
		sticks={},
		stick_n=0,
		wide_dur=9,
		wide_t=0,
		norm_w=10,
		wide_w=20,
		shots=0,
	}
	
	------------
	-- balls :)
	
	-- ball super power
	-- ball gets bigger for n sec
	-- doesn't bounce off blocks
	-- sweeps a clean path through
	-- doesn't give a shit
	-- shake the screen a lot
	
	balls={}
	
	k_min_ball_angle=0.0972
	k_max_ball_angle=0.4028

	add_start_ball()
	
	k_powerup_chance=0.25
	powerups={}
	
	lazers={}
	
	text_fx={}
	
	ui={
		message={show=false,x=64,y=64,text=""}
	}
	
	play={
		shield_level=0
	}
	
	sequence(seq_play_intro)
end

function seq_play_intro()
	play_lock=true
	
	ui.message.show=true
	ui.message.text="ready"
	
	wait_sec(0.25)
	
	ui.message.show=false
	
	play_lock=false
end

function add_start_ball() add_ball(64,0,0,paddle,0,-3) end

function add_ball(x,y,angle,stick,sx,sy)
	local b=add(balls,{
		stuck=nil,
		soffx=0,soffy=0,
		x=x or 0,
		y=y or 0,
		stop_f=0,
		super_t=0,
		norm_w=1,norm_h=1,
		super_w=2,super_h=2,
		w=1,h=1, -- half width/height
		norm_speed=70,
		max_speed=110,
		speed_decay=12,
		speed=50,
		angle=angle or 0,
		has_bounced=false,
	})
	b.speed=b.norm_speed
	ball_stick(b,stick,sx,sy)
end

-- powerup definitions
k_ptype_lazer=1
k_ptype_wide=2
k_ptype_shield=3
k_ptype_multi=4
k_ptype_super=5

k_powerup_weights={
	3,3,3,3,1
}

k_powerup_colors={
	8,9,12,11,14
}

k_powerup_names={
	"lazer",
	"wide",
	"shield",
	"multiball",
	"big boi"
}

powerup_pals={
	{5,6,7},
	{6,7,5},
	{7,5,6}
}

function next_powerup(x,y)
	local pt=powers[power_idx+1]
	power_idx=(power_idx+1)%powers_n
	if power_idx==0 then
		log("wrap")
	end
	return add_powerup(x,y,pt)
end

function add_powerup(x,y,ptype)
	return add(powerups,{
		x=x or 0,
		y=y or 0,
		w=3.5,h=2.5, --half width/height
		ptype=ptype or 0,
		t0=0,
	})
end

function powerup_pal(tm)
	local pi=flr((tm*15)%3)+1
	local pals=powerup_pals[pi]
	for i=1,3 do
		pal(4+i,pals[i])
	end
end

function play_btn(b,p)
	return not play_lock and btn(b,p)
end

function play_btnp(b,p)
	return not play_lock and btnp(b,p)
end

function play_update(dt)
	----------------
	-- update paddle

	local targ_w=paddle.norm_w
	local clamp_fn=flr
	if paddle.wide_t>0 then
		paddle.wide_t-=dt
		targ_w=paddle.wide_w
		clamp_fn=ceil
	end
	
	paddle.w=clamp_fn(lerp(paddle.w,targ_w,10*dt))

	local ix,iy=input_xy(0)
	
	if play_lock then
		ix,iy=0,0
	end
	
	local maxspd=100
	local accel=500
	local decay=800
	
	if play_btn(5) then
		maxspd*=2
		accel*=2
		decay*=2
	end
	
	if sgn(ix)~=sgn(paddle.dx) then
		accel*=2
	end
	
	paddle.dx+=ix*dt*accel
	
	if ix==0 then
		paddle.dx=moveto(paddle.dx,
			0,accel*dt)
	else
		paddle.face=sgn(ix)
	end
	
	if paddle.dx>maxspd then
		paddle.dx=moveto(paddle.dx,
			maxspd,
			decay*dt)
	elseif paddle.dx<-maxspd then
		paddle.dx=moveto(paddle.dx,
			-maxspd,
			decay*dt)
	end

	paddle.sfrac=paddle.dx/maxspd
	
	paddle.x+=paddle.dx*dt
		
	if paddle.x<paddle.w then
		paddle.x=paddle.w
		paddle.dx=0
	elseif paddle.x>128-paddle.w then
		paddle.x=128-paddle.w
		paddle.dx=0
	end
	
	if play_btnp(4) then
		paddle_launch_balls(paddle)
	end
	
	local add_lazer=function(x,y,w,h)
		add(lazers,{
			x=x,y=y,
			w=1,h=1,
			head=0.25,
			speed=200,
			turn_rate=0.9,
			target=nil,
			t_life=5,
			trail={},
		})
	end
	
	-- shooting
	if paddle.shots>0 and
		paddle.stick_n<=0 and
		play_btnp(4)
	then
		local left=topleft(paddle)
		local right=botright(paddle)
		add_lazer(left,paddle.y-1,1,2)
		add_lazer(right+1,paddle.y-1,1,2)
		paddle.shots-=1
	end
	
	----------------
	-- update lazers
	
	foreach(lazers,function(l)
		if not l.target then
			local best=32767
			local select=nil
			for _,b in pairs(blocks) do
				local dx=b.x-l.x
				local dy=b.y-l.y
				local d2=dx*dx+dy*dy
				if d2>0 and d2<1024 and d2<best then
					best=d2
					select=b
				end
			end

			l.target=select
		else
			local tang=angle_to(l.x,l.y,
				l.target.x,l.target.y)

			l.head=moveto_angle(
				l.head,tang,l.turn_rate*dt)			

			if l.target.hits<=0 then
			 l.target=nil
			end
		end

		local dx,dy=direction(l.head)
		l.x+=dx*dt*l.speed
		l.y+=dy*dt*l.speed

		for i=5,1,-1 do
			l.trail[i]=l.trail[i-1]
		end
		l.trail[1]={x=l.x,y=l.y}
		
		l.t_life-=dt
		if (l.t_life<=0) del(lazers,l)
		
		foreach(blocks,function(b)
			if rect_coll(l,b) then
				del(lazers,l)
				block_hit(b)
			end
		end)
	end)
		
	---------------
	-- update balls
	foreach(balls,function(ball)
		if ball.stop_f>0 then
			ball.stop_f-=1
			return
		end
	
		if ball.stuck then
			ball.x=ball.stuck.x+ball.soffx
			ball.y=ball.stuck.y+ball.soffy
		else
			if ball.super_t>0 then
				ball.super_t-=dt
				ball.w=ball.super_w
				ball.h=ball.super_h
			else
				ball.w=ball.norm_w
				ball.h=ball.norm_h
			end
		
			local dx,dy=direction(ball.angle)
			
			if ball.speed>ball.max_speed then
				ball.speed=ball.max_speed
			end
			
			if ball.speed>ball.norm_speed then
				ball.speed=moveto(ball.speed,
					ball.norm_speed,
					ball.speed_decay*dt)
			end
			
			ball.x+=dx*dt*ball.speed
			ball.y+=dy*dt*ball.speed
			
			if ball.y<110 then
				ball.has_bounced=false
			end
					
			if ball.x<ball.w then
				ball.x=ball.w
				ball_bounce(ball,1)
			end
			
			if ball.x>128-ball.w then
				ball.x=128-ball.w
				ball_bounce(ball,0)
			end
			
			if ball.y<ball.h then
				ball.y=ball.h
				ball_bounce(ball,3)
			end
	
			if play.shield_level>0 or
				cheat_no_death
			then
				local boty=128-min(play.shield_level,3)-ball.h
				if ball.y>boty then
					ball.y=boty
					ball_bounce(ball,2)
					play.shield_level=max(play.shield_level-1,0)
				end
			end
			
			if ball.y>148+ball.h then
				del(balls,ball)
			end
			
			local hit,side,pos=rect_coll(paddle,ball)
			if hit then
				if side<2 then
					ball.x=pos
				else
					ball.y=pos
				end
				ball_bounce(ball,side)
				
				if side~=3 then
					-- paddle bounce
					ball_bounce(ball,2)
					if not ball.has_bounced then
						ball.has_bounced=true
						local locf=(ball.x-paddle.x)/paddle.w
						local spdf=paddle.sfrac
						local locang=lerp(k_max_ball_angle,k_min_ball_angle,(locf+1)/2)
						local spdang=ball.angle-0.1*spdf
						ball.angle=mid(locang,
							k_min_ball_angle,
							k_max_ball_angle)
						local accel=lerp(0,80,abs(paddle.sfrac))
						ball.speed+=accel
					end
				end
			end
			
			-- ball hit blocks
			for b in all(blocks) do
				local hit,side,pos=rect_coll(b,ball)
				if hit then
					local mag=4-b.hits
					
					block_hit(b,ball.super_t>0)
									
					ball.speed+=10
					if side<2 then
						ball.x=pos
					else
						ball.y=pos
					end
					
					if ball.super_t<=0 then
						ball_bounce(ball,side)
					else
						ball.stop_f=6
					end
					camera_shake(3/60,mag/2)
					break
				end
			end
		end
	end)
	
	------------------
	-- update powerups
	
	foreach(powerups,function(p)
		p.t0+=dt
		p.y+=45*dt
		if p.y>128+p.h then
			del(powerups,p)
		end
		
		if rect_coll(p,paddle) then
			del(powerups,p)
			paddle_powerup(paddle,p.ptype)
		end
	end)
	
	----------------------
	-- update text effects
	foreach(text_fx,function(t)
		t.t-=dt
		if (t.t<=0) del(text_fx,t)
		t.y-=10*dt
	end)
		
	----------------------
	-- win/lose conditions
	
	if #balls==0 then
		paddle_reset(paddle)
		add_start_ball()
		powerups={}
	end
end

ptns={
 0x1248,0x8124,0x4812,0x2481
}

ptns1={
	0xf060,0x0f06,0x60f0,0x060f
}

ptns2={
	0xf0a0,0x0f0a,0xa0f0,0x0a0f
}

ptns={ptns1,ptns2}

ptns={
	{0xcc33,0x3cc3,0x33cc,0xc33c}, -- d
--	{0xcc33,0x6996,0xcc33,0x6996}, -- dl
	{0xcc33,0x9966,0x33cc,0x6699}, -- l
--	{0xcc33,0x9669,0xcc33,0x9669}, -- ul
	{0xcc33,0xc33c,0x33cc,0x3cc3}, -- u
--	{0xcc33,0x6996,0xcc33,0x6996}, -- ur
	{0xcc33,0x6699,0x33cc,0x9966}, -- r
--	{0xcc33,0x9669,0xcc33,0x9669}, -- dr
}

function play_draw()
	cls(1)
--	local ptn=ptns[flr((t()*1)%#ptns)+1]
--	fillp(ptn[flr((t()*30)%#ptn)+1])
--	rectfill(0,0,127,127,0x10)
--	
--	srand()
--	for i=0,9 do
--		circfill(rnd(128),rnd(128),64+sin(t()/2)*24,8+flr(rnd(7)))
--	end
--	
--	fillp()
	
	if cam_shake_t>0 then
		local a=rnd()
		local cx,cy=cos(a),sin(a)
		camera(cx*cam_shake_mag,
			cy*cam_shake_mag)
	end
	
	--pal(1,k_block_col2)
	--pal(2,k_block_col2)
	-- draw blocks
	foreach(blocks,function(b)
		local tlx,tly=topleft(b)
		local brx,bry=botright(b)	
		
		--if (b.hits<3) pal(1,k_block_col1)
		--if (b.hits<2) pal(2,k_block_col1)
		local sx,sy=0,8
		local fx=false

		if b.btype==0 then
			sx=24+(b.hits-1)*8
		else
			sx=48
			--powerup_pal(t()/4)
			if blink(0.5) then
				pal(14,2)
				pal(2,14)
				fx=true
			end
		end
		
		sspr(sx,sy,8,5,tlx,tly,b.w*2,b.h*2,fx)
		pal()
	end)
	
	-- draw paddle
	rectfill(paddle.x-paddle.w,
		paddle.y-paddle.h,
		paddle.x+paddle.w-1,
		paddle.y+paddle.h-1,
		6)

	if paddle.stick_n>0 then
		local sx,sy=paddle.x,paddle.y-paddle.h
		local ang=0.25-paddle.face*paddle.face_ang
		local ex,ey=cos(ang)*6+sx,sin(ang)*6+sy
		line(sx,sy,ex,ey,8)
	end

	if paddle.wide_t>0 then
		local f=mid(paddle.wide_t/paddle.wide_dur,0,1)
		local hw=ceil(max(paddle.w*f,1))
		line(paddle.x-hw,paddle.y-1,
			paddle.x,paddle.y-1,9)
		line(paddle.x+hw-1,paddle.y-1,
			paddle.x,paddle.y-1,9)
	end


	
	if paddle.shots>0 then
	
		local left=topleft(paddle)
		local right=botright(paddle)
	
		sspr(80,0,2,4,
			left-1,
			paddle.y-3,
			2,4)
			
		sspr(82,0,2,4,
			right,
			paddle.y-3,
			2,4)
			
--[[	
		local string_reverse_like_a_dumbass=function(str)
			local ret=""
			local n=#str
			for i=n,1,-1 do
				ret=ret..sub(str,i,i)
			end
			return ret
		end

		local c=8
		if (blink(0.1)) c=7
		local m="!! lazers !!"
		local mr=string_reverse_like_a_dumbass(m)
		print(m,
			paddle.x+paddle.w,
			paddle.y-3,
			c)
		local holy_shit_the_left=paddle.x-paddle.w-#mr*4
		print(mr,
			holy_shit_the_left,
			paddle.y-3,
			c)
]]
	end


	-- draw balls
	foreach(balls,function(ball)
		local tlx,tly=topleft(ball)
		local brx,bry=botright(ball)
		rectfill(tlx,tly,brx,bry,6)
	end)
	
	
	-- draw powerups
	foreach(powerups,function(p)
		local tlx,tly=topleft(p)
		local brx,bry=botright(p)
		local sx=(p.ptype-1)*8+32
		local sy=0
		powerup_pal(p.t0)
		sspr(sx,sy,7,5,
			tlx,tly,p.w*2,p.h*2)
	end)
	pal()
	
	--------------
	-- draw lazers
	foreach(lazers,function(l)
		local tlx,tly=topleft(l)
		local brx,bry=botright(l)
		circfill(l.x,l.y,l.w,8)
--		rectfill(tlx,tly,brx,bry,8)
		
		local n=#l.trail
		if n>1 then
			for i=1,n-1 do
				local a,b=l.trail[i],l.trail[i+1]
				
				if not a then
					print(i)
					flip()
					stop()
				end
			
				local x1,y1=a.x,a.y
				local x2,y2=b.x,b.y
				line(x1,y1,x2,y2,8)
			end
		end
	end)
	
	---------------
	-- draw shields
	local draw_shield=function(level,col)
		if level>0 then
			rectfill(0,128-min(level,3),127,127,col)
		end
	end	
	draw_shield(play.shield_level,12)
	draw_shield(play.shield_level-3,11)
	draw_shield(play.shield_level-6,10)
	draw_shield(play.shield_level-9,13)
	draw_shield(play.shield_level-12,14)
	
	--------------------
	-- draw text effects
	
	foreach(text_fx,function(t)
		local n=#t.msg
		local c=t.col
		if (blink(0.15,t.t)) c=7
		print(t.msg,t.x-n*2,t.y-2.5,c)
	end)
	
	camera()
	
	-- hud
	
	if ui.message.show then
		local m=ui.message.text
		print(m,
			ui.message.x-#m*2,
			ui.message.y,
			7)
	end
end

function test_coll_init()
	aa={x=64,y=64,w=8,h=4}
	bb={x=64,y=56,w=1,h=1}
end

function test_coll_update(dt)
	local ix,iy=input_xy()
	
	bb.x+=ix*20*dt
	bb.y+=iy*20*dt
	
	local hit,side,pos=rect_coll(aa,bb)
	if hit then
		watch("side: "..side)
		watch("pos: "..pos)
	end
end

function test_coll_draw()
	draw_rect(aa,11)
	draw_rect(bb,8)
end

function draw_rect(r,col)
	local tlx,tly=topleft(r)
	local brx,bry=botright(r)
	rectfill(tlx,tly,brx,bry,col)

end

function block_hit(b,kill)
	if not kill then
		b.hits-=1
	else
		b.hits=0
	end
	if b.hits<=0 then
		del(blocks,b)
		local power=b.btype==1
		if power or cheat_100_power then
			next_powerup(b.x,b.y)
		end
	end
end

function ball_bounce(ball,side)
	local dx,dy=direction(ball.angle)
	if side==0 and dx>0 then
		ball.angle=hreflect_angle(ball.angle)
	elseif side==1 and dx<0 then
		ball.angle=hreflect_angle(ball.angle)
	elseif side==2 and dy>0 then
		ball.angle=vreflect_angle(ball.angle)
	elseif side==3 and dy<0 then
		ball.angle=vreflect_angle(ball.angle)
	end
end

function ball_stick(ball,stick,ox,oy)
	if ball.stuck then
		ball.stuck.sticks[ball]=nil
		ball.stuck.stick_n-=1
	end

	ball.stuck=stick
	
	if ball.stuck then
		ball.soffx=ox or ball.x-stick.x
		ball.soffy=oy or ball.y-stick.y
		ball.stuck.sticks[ball]=true
		ball.stuck.stick_n+=1
	end
end

function paddle_launch_balls(paddle)
	for ball,_ in pairs(paddle.sticks) do
		ball.angle=0.25-paddle.face*paddle.face_ang
		ball_stick(ball,nil)
		ball.speed=100
	end
end

function paddle_powerup(paddle,ptype)
	if ptype==k_ptype_lazer then
		paddle.shots+=3
	elseif ptype==k_ptype_wide then
		paddle.wide_t=paddle.wide_dur
	elseif ptype==k_ptype_shield then
		play.shield_level=min(
			play.shield_level+1,15)
	elseif ptype==k_ptype_multi then
		local b=rnd_elem(balls)
		add_ball(b.x,b.y,b.angle-0.015)
		add_ball(b.x,b.y,b.angle+0.015)
	elseif ptype==k_ptype_super then
		--local b=rnd_elem(balls)
		foreach(balls,function(b)
			b.super_t=5
		end)
	end
	
	local name=k_powerup_names[ptype]
	add_text_fx(name,paddle.x,paddle.y,k_powerup_colors[ptype])
end

function paddle_reset(paddle)
	paddle.x=64
	paddle.wide_t=0
	paddle.dx=0
end

function add_text_fx(msg,x,y,col)
	return add(text_fx,{
		msg=msg,x=x,y=y,t=0.8,col=col,
	})
end

function direction(angle)
	return cos(angle),sin(angle)
end

function hreflect_angle(angle)
	local dx,dy=direction(angle)
	return atan2(-dx,dy)
end

function vreflect_angle(angle)
	local dx,dy=direction(angle)
	return atan2(dx,-dy)
end

function topleft(o)
	return o.x-o.w,o.y-o.h
end

function botright(o)
	return o.x+o.w-1,o.y+o.h-1
end

function rect_coll(a,b)
	-- calculates minkowski sum
	-- of rectangles
	-- determines if collision
	-- occurs and on what side
	-- side is number based on
	-- btn inputs
	-- side: 0 left
	--       1 right
	--       2 top
	--       3 bottom

	local w=a.w+b.w
	local h=a.h+b.h
	
	local dx=a.x-b.x
	local dy=a.y-b.y
	
	if abs(dx)<=w and abs(dy)<=h then
		local wy=w*dy
		local hx=h*dx*0.75
		
		local side
		local position
		if wy>hx then
			if wy>-hx then
				side=2
				position=a.y-a.h-b.h
			else
				side=1
				position=a.x+a.w+b.w
			end
		else
			if wy>-hx then
				side=0
				position=a.x-a.w-b.w
			else
				side=3
				position=a.y+a.h+b.h
			end
		end
		return true,side,position
	end
	return false
end
-->8
-- todo/notes

--------
-- notes

-- specials thoughts

-- all:
-- fall speed tweaking
-- proc chances
-- table weighting

-- super:
--  possibly needs alternative
--  to timer, maybe blocks hit
--  or distance based?

-- lasers:
--  shooting straight up is
--  fucking lame
--  slight homing lazers with
--  big particle trails and
--  shit

-------
-- todo

-- __word effects__
-- on powerups
-- special moments
--  saving with a shield
--   after ball off screen

-- __specials__
-- various tweaks adjustments
--  (see thoughts above^)
-- replace visuals with new
-- sprites and adjust sizing

-- __blocks__
-- block reactions
-- bumps when getting hit
-- flashing colors into safe state

-- __game loop stuff__
-- lives
-- win state
-- game over state (no lives)
-- all the other stuff think about it later
__gfx__
00000000077777700ccc000000000000008ee0000094900000ccc00000bbb00000ee2000000000000ee000000000000000000000000000000000000000000000
00000000722112252fffc00000700700778ee7700794970077c1177077bbb77077e2e77000000000088000000000000000000000000000000000000000000000
00700700721111252fffc00007788770668ee6600694960066ccc66066b3b66066ee266000000000888800000000000000000000000000000000000000000000
00077000722112252fffc000008ee800558ee550059995005511c55055b3b55055e2e55000000000888800000000000000000000000000000000000000000000
000770000555555002220000008ee800008880000099900000ccc00000b3b00000ee200000000000000000000000000000000000000000000000000000000000
00700700000000000000000007788770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606000006000000660066007777770077777700777777007777770000000000000000000000000000000000000000000000000000000000000000000000000
0660660000660000066006607999999679dddd967dddddd6722e22e6000000000000000000000000000000000000000000000000000000000000000000000000
066066600066600006600660799999967dd99dd67dddddd67e2ee2e6000000000000000000000000000000000000000000000000000000000000000000000000
0660666600666600066006607999999679dddd967dddddd67e22e226000000000000000000000000000000000000000000000000000000000000000000000000
06606660006660000660066006666660066666600666666006666660000000000000000000000000000000000000000000000000000000000000000000000000
06606600006600000660066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606000006000000660066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131300131313131300131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131300131515151300131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131300131515151300131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131300131313131300131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131300131313131300131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013161300161313131600131613000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131600161316131600161313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0013131313000000000013131313000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0016131316000000000016131316000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
