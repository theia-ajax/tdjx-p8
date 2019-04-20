pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include util.p8

function _init()
	poke(0x5f2d,1)
	
	debug_fbf=false
	debug_advance=false
	
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
	
	if debug_fbf then
		if debug_advance then
			debug_advance=false
		else
			return
		end
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
	end
end

function keypress(key)
	if key=="n" then
		debug_fbf=not debug_fbf
	elseif key=="m" then
		debug_advance=not debug_advance
	elseif key=="l" then
		_logs={}
	end
end

function camera_shake(dur,mag)
	cam_shake_mag=mag or 0
	cam_shake_t=dur or 0
end

function play_init()
	k_block_width=4
	k_block_height=2.5
	
	cam_shake_mag=0
	cam_shake_t=0
	
	blocks={}
	
	for y=3,10 do
		for x=2,14 do
			local col=12
			local hits=3

			

			add(blocks,{
				x=x*k_block_width*2,
				y=y*k_block_height*2,
				w=k_block_width,
				h=k_block_height,
				hits=hits,
			})
		end
	end
	
	paddle={
		x=64,y=121,
		dx=0,
		accel=100,
		sfrac=0,
		w=8,h=1.5,-- half width/height
		sticks={},
		wide_dur=12,
		wide_t=0,
		norm_w=8,
		wide_w=16,
	}
	
	balls={}
	
	k_min_ball_angle=1/16
	k_max_ball_angle=1/2-1/16

	add_ball(64,0,0.125,paddle,0,-3)
	
	k_powerup_perc=0.2
	powerups={}
end

function add_ball(x,y,angle,stick,sx,sy)
	local b=add(balls,{
		stuck=nil,
		soffx=0,soffy=0,
		x=x or 0,
		y=y or 0,
		w=1,h=1, -- half width/height
		norm_speed=70,
		max_speed=120,
		speed_decay=18,
		speed=50,
		angle=angle or 0,
		has_bounced=false,
	})
	b.speed=b.norm_speed
	ball_stick(b,stick,sx,sy)
end

k_ptype_laser=0
k_ptype_wide=1
k_ptype_shield=2
k_ptype_multi=3

k_powerup_colors={
	8,9,12,11
}

function add_powerup(x,y,ptype)
	return add(powerups,{
		x=x or 0,
		y=y or 0,
		w=2,h=1, --half width/height
		ptype=ptype or 0,
		t0=0,
	})
end

function play_update(dt)
	if paddle.wide_t>0 then
		paddle.wide_t-=dt
		paddle.w=paddle.wide_w
	else
		paddle.w=paddle.norm_w
	end

	local ix,iy=input_xy(0)

	local maxspd=100
	local accel=500
	local decay=800
	
	if btn(5) then
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
	
	if btnp(4) then
		paddle_launch_balls(paddle)
	end
	
	foreach(balls,function(ball)
		if ball.stuck then
			ball.x=ball.stuck.x+ball.soffx
			ball.y=ball.stuck.y+ball.soffy
		else
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

--[[			
			if ball.y>128-ball.h then
				ball.y=128-ball.h
				ball_bounce(ball,2)
			end]]
			
			if ball.y>128+ball.h then
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
						local ang=ball.angle+paddle.sfrac*-0.125
						ang=mid(ang,
							k_min_ball_angle,
							k_max_ball_angle)
						ball.angle=ang
						ball.speed+=lerp(10,60,abs(paddle.sfrac))
					end
				end
			end
			
			-- ball hit blocks
			for b in all(blocks) do
				local hit,side,pos=rect_coll(b,ball)
				if hit then
					b.hits-=1
					if b.hits<=0 then
						del(blocks,b)
						if chance(k_powerup_perc) then
							add_powerup(b.x,b.y,flr(rnd(4)))
						end
					end
					
					ball.speed+=10
					if side<2 then
						ball.x=pos
					else
						ball.y=pos
					end
					ball_bounce(ball,side)
					camera_shake(8/60,3)
					break
				end
			end
		end
	end)
	
	foreach(powerups,function(p)
		p.t0+=dt
		p.y+=20*dt
		if p.y>128+p.h then
			del(powerups,p)
		end
		
		if rect_coll(p,paddle) then
			del(powerups,p)
			paddle_powerup(paddle,p.ptype)
		end
	end)
	
	if cam_shake_t>0 then
		cam_shake_t-=dt
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
	{0xcc33,0x6996,0xcc33,0x6996}, -- dl
	{0xcc33,0x9966,0x33cc,0x6699}, -- l
	{0xcc33,0x9669,0xcc33,0x9669}, -- ul
	{0xcc33,0xc33c,0x33cc,0x3cc3}, -- u
	{0xcc33,0x6996,0xcc33,0x6996}, -- ur
	{0xcc33,0x6699,0x33cc,0x9966}, -- r
	{0xcc33,0x9669,0xcc33,0x9669}, -- dr
}

function play_draw()
	cls()
	local ptn=ptns[flr((t()*1)%#ptns)+1]
	fillp(ptn[flr((t()*30)%#ptn)+1])
	rectfill(0,0,127,127,0x10)
	fillp()
	
	if cam_shake_t>0 then
		local a=rnd()
		local cx,cy=cos(a),sin(a)
		camera(cx*cam_shake_mag,
			cy*cam_shake_mag)
	end
	
	foreach(blocks,function(b)
		local tlx,tly=topleft(b)
		local brx,bry=botright(b)
		
		pal(1,13)
		pal(2,13)
		if (b.hits<3) pal(1,12)
		if (b.hits<2) pal(2,12)
		
		sspr(8,0,8,5,tlx,tly,b.w*2,b.h*2)
	end)
	pal()
	
	rectfill(paddle.x-paddle.w,
		paddle.y-paddle.h,
		paddle.x+paddle.w-1,
		paddle.y+paddle.h-1,
		6)
		
	foreach(balls,function(ball)
		local tlx,tly=topleft(ball)
		local brx,bry=botright(ball)
		rectfill(tlx,tly,brx,bry,6)
	end)
	
	foreach(powerups,function(p)
		local tlx,tly=topleft(p)
		local brx,bry=botright(p)
		local col=k_powerup_colors[p.ptype+1]
		circfill(p.x,p.y,2,col)
		local oc=7
		if blink(0.25,t()/2+p.t0) then
			pset(p.x,p.y,7)
			circfill(p.x,p.y,1,7)
			oc=col
		end
		circ(p.x,p.y,2,oc)
		//rectfill(tlx,tly,brx,bry,col)
	end)
	
	camera()
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
	end

	ball.stuck=stick
	
	if ball.stuck then
		ball.soffx=ox or ball.x-stick.x
		ball.soffy=oy or ball.y-stick.y
		ball.stuck.sticks[ball]=true
	end
end

function paddle_launch_balls(paddle)
	for ball,_ in pairs(paddle.sticks) do
		ball_stick(ball,nil)
		ball.speed=100
	end
end

function paddle_powerup(paddle,ptype)
	if ptype==k_ptype_laser then
	elseif ptype==k_ptype_wide then
		paddle.wide_t=paddle.wide_dur
	end
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
		local hx=h*dx
		
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
__gfx__
00000000077777700aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000721212254999a00000700700066666600666666006666660066666600000000000000000000000000000000000000000000000000000000000000000
00700700722122154999a0000778877067bbbb766799997667cccc766788777600eeee0000000000000000000000000000000000000000000000000000000000
00077000712221254999a000008ee80067b777766797777667c77776678877760e8888e000000000000000000000000000000000000000000000000000000000
000770000555555004440000008ee80067bbb77667979976677ccc76678877760e8888e000000000000000000000000000000000000000000000000000000000
0070070000000000000000000778877067b777766799997667cccc766788887600eeee0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700700066666600666666006666660066666600000000000000000000000000000000000000000000000000000000000000000
