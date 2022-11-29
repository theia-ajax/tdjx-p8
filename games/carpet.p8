pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function _init() 
	play_init()
end

function _update60()
	for seq in all(sequences) do
		if costatus(seq)=="suspended"
		then
			assert(coresume(seq))
		else
			del(sequences,seq)
		end
	end

	if (active_update) active_update()
end

function _draw()
	if (active_draw) active_draw()
end

hint_up=1
hint_down=2
hint_mid=3
hint_guess=4

function play_init()
	⧗=0

	pl={
		x=64,y=64,
		w=8,h=8,
		sp=8,
		sw=16,sh=16,
		tw=2,th=2,
		frames={8,10,12,14},
		frame=1,
		fs=2,
		fc=0,
	}
	
	pos={0,0,0,0}
	vel=1
	
	rocks={}
	
	wave={
		x=-80,y=34,
		pfx={
			{},{},{},{}
		},
		edge_l={},
		edge_r={},
	}

	
	for i=1,64 do
		wave.edge_r[i]=-32768
		wave.edge_l[i]=32767
		for x=79,0,-1 do
			if sget(x,32+i-1)>0 then
				wave.edge_r[i]=x
				break
			end
		end
		for x=0,79 do
			if sget(x,32+i-1)>0 then
				wave.edge_l[i]=x
				break
			end
		end
	end
	
	seq(function()
		active_update=play_update
		active_draw=play_draw
	end)
	
	script=seq(gamescript)
end

function play_update()
	⧗+=1
	
	foreach(rocks,update_rock)

	-- update player
	local ix,iy=0,0
	if (btn(0)) ix-=1
	if (btn(1)) ix+=1
	if (btn(2)) iy-=1
	if (btn(3)) iy+=1
	
	pl.x+=ix
	pl.y+=iy
	
	pl.y=mid(pl.y,30,87)
	
	pl.fc+=1
	if pl.fc>=pl.fs then
		pl.frame+=1
		pl.fc=0
		if pl.frame>#pl.frames then
			pl.frame=1
		end
		pl.sp=pl.frames[pl.frame]
	end

	local mtbl={0.33,0.67,1,1.33}

	for i,p in ipairs(pos) do
		p=(p+vel*mtbl[i])%128
		pos[i]=p
	end		
	vel+=0.001
	vel=min(vel,4)
		
	wave_update()
end

function play_draw()
	cls()
	
	-- scrolling
	
	for i=0,3 do
		local px=-pos[i+1]
		local ipx=128+px
		local mx=i*16
		
		local toy=-8
		local boy=-4
		
		if i==0 then
			map(mx,0,px,0,16,16)
			map(mx,0,ipx,0,16,16)
		else
			map(mx,0,px,toy,16,8)
			map(mx,0,ipx,toy,16,8)

			map(mx,8,px,64+boy,16,8)
			map(mx,8,ipx,64+boy,16,8)
		end
	end

--	map(16,0,-pos/4,-8,16,16)
--	map(16,0,128-pos/4,-8,16,16)	
--
--	map(16,0,-pos/2,0,16,16)
--	map(16,0,128-pos/2,0,16,16)	
--
--	map(0,0,-pos,0,16,16)
--	map(0,0,128-pos,0,16,16)

	
	-- draw wave
	if ⧗%8<4 then
		pal(7,7)
		pal(11,10)
	else
		pal(7,10)
		pal(11,7)
	end
--	spr(64,wave.x,wave.y,10,8)
	
	local wt=sin(t()*4)*1
	local wtx=cos(t())*2
	sspr(0,32,80,96,
		wave.x+wtx,wave.y+wt,80-wtx,96-wt)
	pal()
	
	for pfx in all(wave.pfx) do
		for p in all(pfx) do
			local col=p.col
			if type(col)=="table" then
				local colt=mid(p.⧗/p.col⧗,0,0x0000.ffff)
				local coli=flr(colt*#col)+1
				col=col[coli]
			end
			
			if p.∧=="circ" then
--				spr(39,p.x-2,p.y-2)
				circfill(p.x,p.y,p.r,col)
			elseif p.∧=="line" then
				local nx,ny=norm(p.dx,p.dy)
				local x2,y2=p.x+nx*p.r,p.y+ny*p.r
				line(p.x,p.y,x2,y2,col)
			end
		end
	end

	-- draw player
	spr(pl.sp,
		pl.x-pl.sw/2,
		pl.y-pl.sh/2,
		pl.tw,pl.th)
		
	foreach(rocks,draw_rock)
	
	local hs=sin(t()*4)*2
	local hc=-sin(t()*4)*2
	
	if hint==hint_up then
		spr(42,102,54+hs,2,2)
	elseif hint==hint_down then
		spr(44,106,58+hc,2,2)
	elseif hint==hint_mid then
		spr(42,102,54+hs,2,2)
		spr(44,106,58+hc,2,2)
	elseif hint==hint_guess then
		spr(46,102,56,2,2)
	end

	rectfill(0,0,127,15,0)
	rectfill(0,111,127,127,0)
end

function wave_update()
	wave.x+=0x0000.2800
--wave.x+=1
wave.x=min(wave.x,-12)

	for pfx in all(wave.pfx) do
		for p in all(pfx) do
			p.⧗+=1	
			p.x+=p.dx
			p.y+=p.dy
			
			if p.phys then
								
				local ex=wave_edge(p.y)
				if p.x<ex then
					p.dx+=0.05
					p.dx=mid(p.dx,-1,3)
					local nex=wave_edge(p.y-1)
					if p.x<nex-3 then
						p.dy+=0.05
					else
						p.dy-=0.1
					end
				else
					p.dx-=0.5
					p.dx=max(p.dx,-3)
					p.dy*=0.95
				end
			elseif p.wave then
				if p.x<wave_edge_l(p.y)
				then
					p.⧗=p.life⧗
--					p.r=0
				end
			end
			
			if p.⧗>=p.life⧗ then
				p.r-=1
				if p.r<=0 then
					del(pfx,p)
				end
			end
		end
	end

	local le=0
	for i,e in ipairs(wave.edge_r)
	do
		local y=wave.y+i-1
		local x=wave.x+e
		local left=wave.edge_l[i] or 32767
		if e>=0 and rnd()<0.1 then
			local m=e-le
			add(wave.pfx[1],{
				∧="circ",
				phys=true,
				x=x,y=y,
				dx=0,dy=-0.3,
				⧗=0,
				life⧗=7+flr(rnd(20)),
				r=rnd(2)+1,
				col=rnd({9}),
				col⧗=30,
			})
		end
		if e>=0 and rnd()<0.1 then
			local m=e-le
			colors={8,9,10}
			add(wave.pfx[2],{
				∧="line",
				wave=true,
				⧗=0,
				x=x,y=y,
				r=8,
				dx=-2,dy=(rnd()-0.5),
				life⧗=7+flr(rnd(20)),
				col={10,4,8,9,9,9,9,10},
				col⧗=e-left-4,
			})
		end
	end	
end

function wave_edge(y)
	local ly=flr(y-wave.y)
	local ei=ly+1
	local ex=wave.edge_r[ei]
	if ex==nil then
		return -32768
	end
	return ex+wave.x
end

function wave_edge_l(y)
	local ly=flr(y-wave.y)
	local ei=ly+1
	local ex=wave.edge_l[ei]
	if ex==nil then
		return 32767
	end
	return ex+wave.x
end

function make_rock(x,y)
	local r={
		x=x,y=y,
		w=8,h=8,
		sw=24,sh=24,
		tw=2,th=2,
		flips=flr(rnd(4))
	}
	return add(rocks,r)
end

function update_rock(self)
	self.x-=vel
	if self.x<-16 then
		self.dead=true
		del(rocks,self)
	end
end

function draw_rock(self)
	sspr(104,32,24,24,
		self.x-self.sw/2,
		self.y-self.sh/2,
		self.sw,self.sh,
		self.flips&1~=0,
		self.flips&2~=0)
end
-->8
function tblcpy(src,dst)
	dst=dst or {}
	for k,v in pairs(src) do
		dst[k]=v
	end
	return dst
end

function aabb(t1,t2,r)
	r=r or 0
	local w1,w2=t1.w+r,t2.w+r
	return t1.x+w1>=t2.x-w2
		and t1.x-w1<=t2.x+w2
		and t1.y+w1>=t2.y-w2
		and t1.y-w1<=t2.y+w2
end

function cc(c1,c2)
	local l=len(c2.x-c1.x,c2.y-c1.y)
	return l<=c1.r+c2.r
end

function len2(x,y) return x*x+y*y end
function len(x,y) return sqrt(len2(x,y)) end
function norm(x,y)
	local l=len(x,y)
	if (l==0) return 0,0
	return x/l,y/l
end

function seq(fn)
	sequences=sequences or {}
	return add(sequences,cocreate(fn))
end

function wait_for(pred)
	while not pred() do yield() end
	yield()
end

function wait_sec(s)
	while s>=0 do
		s-=1/60
		yield()
	end
end

function wait_frames(n)
	for i=1,n do yield() end
end

function wait_any_key(s,id)
	while not any_btnp(id) do
		yield()
	end
end

function any_btnp(id)
	for b=0,6 do
		if (btnp(b,id)) return true
	end
	return false
end

_pow2={
	2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384
}
_pow2[0]=1

function pow2(v)
	assert(_pow2[v]~=nil)
	return _pow2[v]
end
-->8

lane_top=1
lane_mid=2
lane_bot=3

lane_y={
	[lane_top]=46,
	[lane_mid]=64,
	[lane_bot]=80,
}

lane_hint={
	[lane_top]=hint_down,
	[lane_mid]=hint_mid,
	[lane_bot]=hint_up,
}

hint⧗=60

function spawn_rock(lane,guess)
	if lane==nil then
		lane=flr(rnd(#lane_y))+1
	end
	if not guess then
		hint=lane_hint[lane]
	else
		hint=hint_guess
	end
	wait_frames(hint⧗)
	hint=nil
	wait_frames(0)
	local y=lane_y[lane]
	wait_rock_dead(make_rock(160,y))
end

function wait_rock_dead(r)
	while not r.dead do yield() end
end

function gamescript()
	wait_frames(200)
	
	vel=2
	
	wait_frames(30)
	
	spawn_rock(lane_top)
	spawn_rock(lane_bot)
	spawn_rock(lane_mid)
	spawn_rock(lane_top,true)
end
__gfx__
00000000000000005544555555455554444554444444455444444444555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000004554455554455555545544444554445544444444555544540000000000000000000000000000000000000000000000000000000000000000
00700700000000004444454555555555444442444555455544444444554444450000000000000000000000000000000000000000000000000000000000000000
000770000000000044444444544444444444222445555554444444444444444400000000000000000000cc000000000000000000000000000000000000000000
000770000000000042244444444444444422222445555444444444444444444400000cc007700000000cccc00770000000000cc007700000000cc00007700000
00700700000000002222244444444444442222444554444444444444424442420000ccccc7770000000cccccc77700000000ccccc777000000ccccccc7770000
0000000000000000222222444444444442222224445444444444444422244222000ccccccc4400000000cccccc440000000ccccccc44000000cccccccc440000
000000000000000022221d4444224442422022224454442444444444002222000000ccc77c44000000000cc77c4400000000ccc77c440000000cccc77c440000
000000000000000022100d444422222221000222444442245555555500000000000000677cc00000000000677cc00000000000677cc00000000000677cc00000
0000000000000000000000d444102221000000244444422255555555000000000002007666000222000200766600022200020076660002220002007666000222
0000000000000000000000d441000000000000244412410055555555000000000011477127222110001147712722211000114771272221100011477127222110
0000000000000000000000d441000000000000d4241d441055555555000000000122422214411200012242221441120001224222144112000122422214411200
0000000000000000000000d410000000000000d44100d41055555555000000002200220022220000220022002222000022002200222200002200220022220000
0000000000000000000000d41000000000000d241000d21055555555000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000d210000000000000060000060055555555000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000600000000000000000000000055555555000000000000000000000000000000000000000000000000000000000000000000000000
89899988888899990000000000000000000000000000000000000000009900000000000999999000000000c0000000000000000000000000000000ccccc00000
988889999998888900000000000000000000000000000000000000009aa8900000000994949889000000ccccc0000000000000000c00000000000cc000cc0000
98889999999999990000000000000000000000aaaaaa0000000000009a8000000000948849498990000ccccccc00000000000000ccc000000000cc00000cc000
89899889999999980aa00aa00aaaaa0000aaaaaaaaaaaaaa0000000008098000009949949894949000ccccccccc0000000000000ccc00000000cc000000cc000
9999998899988899aaaaaaaaaaaaaaaaaaaaaaa9888999aa0000000009900000009499498889490000ccccccccc0000000000000ccc00000000cc000000ccc00
9988999999999989a8aaa8aaaa8aaaaaa989989899988899000000000000000009498894988894900cc00ccc00cc000000000000ccc00000000ccc00000ccc00
8889988888999889898a89999898a8898998998999999998000000000000000094998899898944490c000ccc000c000000000000ccc00000000ccc00000ccc00
88999999888888999999998988899849999999998998998900000000000000009898889888949949cc000ccc000cc00000000000ccc000000000ccc0000cc000
98888889999999999888d4489894448998998898999988990000000000000000989888949499889900000ccc00000000000cc000ccc000cc0000ccc0000cc000
8999999999888898d9444449848d884d9988444889989d990000000000000000984989498994994900000ccc000000000000c000ccc000c00000000000cc0000
9998899999999998ddddd4444dd44448444444444d8dddd80000000000000000098894498889448900000ccc000000000000cc00ccc00cc000000000ccc00000
9988899999998889ddddddddd444ddd444dddddd44dd44d40aa00aa000000000098844998894899000000ccc0000000000000ccccccccc000000000cccc00000
8899998888889998dd4444dddddd444d9dd4944494d44444aaaaaaaa00000000099949849948900000000ccc0000000000000ccccccccc000000000cc0000000
998888899998899944dddd44444dd4449994994499d99999a9aaa9aa00000000000099899449000000000ccc00000000000000ccccccc0000000000000000000
8998889999999888d44ddd4444444ddd8888999999999999888a9888000000000000099894990000000000c0000000000000000ccccc0000000000ccccc00000
98999998888899994d44444ddddd44448888999999999999889999990000000000000099990000000000000000000000000000000c000000000000ccccc00000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888880000000
000000000000000000000000000000000000000000aaaaaaa0000000000000000000000000000000000000000000000000000000000088888889999998880000
00000000000000000000000000000000000000000aaa889aaaaaaaaa000000000000000000000000000000000000000000000000000899999999999999998000
000000000000000000000000000000000000000aaa88999ab799998aa00000000000000000000000000000000000000000000000008999999999999999999880
000000000000000000000000000000000000aaaa8888899ab799a998aa0000000000000000000000000000000000000000000000008999999999999999999998
00000000000000000000000000000000000aa9999999889aaa9a7b998aa000000000000000000000000000000000000000000000089999999999999999999998
00000000000000000000000000000000aaaa99994444899aaa9a7ba998a000000000000000000000000000000000000000000000089999999999999999999980
0000000000000000000000000000000aaaa999444422899aa99a79a999aa00000000000000000000000000000000000000000000089999999999999999999980
000000000000000000000000000000aaa999442222222999a9aaa9aa9998aa000000000000000000000000000000000000000000899999999999999999999998
00000000000000000000000000000aaa994444222222288899aa9bb7999988a00000000000000000000000000000000000000000899999999999999999999998
000000000000000000000000000aaa99944424222222222888999ba79a79988a0000000000000000000000000000000000000000899999999999999999999980
00000000000000000000000000aa9994444444222222442888899aa79bb9a98aa000000000000000000000000000000000000000899999999999999999999980
000000000000000000000000aaa999944444424424444222228899a99aa9a798a000000000000000000000000000000000000000899999999999999999999980
00000000000000000000000aaa999944444944444422222222222999aaaaab98a000000000000000000000000000000000000000899999999999999999999980
00000000000000000000000aa999444444444444422222222222228999aaab9a8a00000000000000000000000000000000000000089999999999999999999998
0000000000000000000000aa99994444494944442222222222222228899a99a78a00000000000000000000000000000000000000089999999999999999999998
000000000000000000000aaa9994444999994444442222422222222888899ba98a00000000000000000000000000000000000000899999999999999999999980
00000000000000000000aaa999444999994444444224442222222222288899998a00000000000000000000000000000000000000899999999999999999999980
0000000000000000000aaa999449999944994444444422222222222222288998a000000000000000000000000000000000000000089999999999999999999980
000000000000000000aaa9994499994449994499444424222444422222228aaa0000000000000000000000000000000000000000089999999999999999999980
00000000000000000aaa9994499994499944499944444444442222222299a0000000000000000000000000000000000000000000008999999999999988999980
000000000000000aaaa9999449994499944499944499444442222299990000000000000000000000000000000000000000000000008999999999999800888800
00000000000000aaaaa9994449944999444999444994444422299900000000000000000000000000000000000000000000000000000899999999988000000000
0000000000000aaaaa99994499949994444999449944999229900000000000000000000000000000000000000000000000000000000088888888800000000000
000000000000aaaaaa99944499499944499994499449994990000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaaa9999944994499944499944994499944900000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaa9999444994999444994949944999449900000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaa99999449944994449944449449994449000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaaaaaaaa99994449444994449944499449994490000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaaaa99aaa999944449449944499444994494944490000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aaaaa99aaa9999449449449944499444944499944990000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaa9999aaa9999449444449944994449944999944900000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaa9999a9999944449444449444994449444949449000000000000000000000000000000000000000000000000000001000010000100000010100000010000
aaa99999aa9999944499449449444994449444949449000000000000000000000000000000000000000000000000000000100001100100000010100000010000
aa999999a99999444494499499449944499444949449000000000000000000000000000000000000000000000000000000010000101000000011100000010000
a9999999999999444944494494449944494444949449000000000000000000000000000000000000000000000000000000001000011000000010110000010000
99999999999999449944494494449444994844949944900000000000000000000000000000000000000000000000000001001000010000000011010000010000
99999999999994449444944494444444944848449944900000000000000000000000000000000000000000000000000000001000111000000011010000100000
99999999999994448884944444494444448848448944900000000000000000000000000000000000000000000000000000001001100101100011001000100000
99999999999994448884948444444444848448848888900000000000000000000000000000000000000000000000000000001101000100100011100100100000
99999999999944448884948444844844848444888888890000000000000000000000000000000000000000000000000000000110000100110010010010100000
99999999999944488884448484848844888889888888890000000000000000000000000000000000000000000000000000000100000100010010010001000000
99999999999944488888448488888888888899998888890000000000000000000000000000000000000000000000000000001100000100010100001001100000
9999999999994448888844888888888898889899a9b9890000000000000000000000000000000000000000000000000000011010000100001100001001011000
999999999999444888888888889888aa998a989aaaba889000000000000000000000000000000000000000000000000000010011000100001100000101001000
9999999999994448888888998899988a8a9aa99aaab7889000000000000000000000000000000000000000000000000000010001000100000100000010001000
9999999999994448889998898899999aaaaaaa97aab7889000000000000000000000000000000000000000000000000000110001000100000100000011001000
99999999999944488899999998999999aaa9aaa79aa7a89900000000000000000000000000000000000000000000000000100001000100000100000010101000
9999999999944448889999999999aa9bbba7bba77ba9788900000000000000000000000000000000000000000000000000100001000100000100000010101100
999999999994444888999aba99b79b877ab77bbb7baa788990000000000000000000000000000000000000000000000000100001000100000100000010100100
9999999999944448889997ba99b77bb97abb7a9b79baa78899000000000000000000000000000000000000000000000000100001000100001100000100100010
9999999999994488888997bba9bb7ab977aba7abb7bba78889000000000000000000000000000000000000000000000000100001000100001100000100100001
99999999999944888889977bb9ab7abba7abb77abb7b9aa889900000000000000000000000000000000000000000000000100001000100011100000100100001
999999999999444888889977ba9bb9abb97abb77a97bb99888900000000000000000000000000000000000000000000000100001000100010100000100100000
999999999999444488889977bb9ab7aabba9abba7977bb8888890000000000000000000000000000000000000000000000100001000100010100000100100000
9999999999994444488889977bb9bb9aaba989bb9998798898889900000000000000000000000000000000000000000011100001000100100110001000100000
9999999999999444448889977ab9ab999b9998888998888889888990000000000000000000000000000000000000000001100011000100100010001000100000
99999999999994444448889977bb9bb9899888888898888888888899000000000000000000000000000000000000000001010010000101000010011001100000
999999999999999444444889977a99b9889888888888888888888889999000000000000000000000000000000000000001001110000101000010010001000000
99999999999999994444448899999898888888888888888888888888899990000000000000000000000000000000000001000110001110000010010011000111
99999999999999999944444488888888888888888888888888888888899999000000000000000000000000000000000011000010001010001100010000111000
aa999999999999999994449944448888888888888444488888999999999999999999999999000000000000000000000010000110001100000100011111100000
aaaaaa99aaa9999aaaa9999a999999448884444444444499999999999a99999999999aaa99999990000000000000000001000100000100001000100110000000
aaaaaaaaaaaaaaaaa99aaa9aaa9aaaa999aaaa999a9aa999999aaa999aaaaa999aaaa999aaaaa999000000000000000000000010001100000100100001000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000060606060606060606060606060606061616161616161616161616161616161600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000006060606060606060606060606060606060606060606060606060606060606061616161616161616161616161616161600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000006060606060606060606060606060606020304050203040502030405020304050707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8c8d8e8f8c8d8e8f8c8d8e8f8c8d8e8f02030405020304050203040502030405121314151213141512131415121314150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9c9d9e9f9c9d9e9f9c9d9e9f9c9d9e9f12131415121314151213141512131415000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
acadaeafacadaeafacadaeafacadaeaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bcbdbebfbcbdbebfbcbdbebfbcbdbebf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8c8d8e8f8c8d8e8f8c8d8e8f8c8d8e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9c9d9e9f9c9d9e9f9c9d9e9f9c9d9e9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
acadaeafacadaeafacadaeafacadaeaf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bcbdbebfbcbdbebfbcbdbebfbcbdbebf22232223222322232223222322232223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000032333233323332333233323332333233222322232223222322232223222322230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000020212021202120212021202120212021323332333233323332333233323332332425242524252425242524252425242500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000030313031303130313031303130313031202120212021202120212021202120213435343534353435343534353435343500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01040000070500a0500c0500a0500305003050030500a0000a0000a00007000050000a0000c0000a0000500005000050000300000000000000000000000000000000000000000000000000000000000000000000
000100001805016050160500f0500f0500c0500c05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000c6500a6500a6500a65007650076400563003620036100361003610036140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003562030620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0433f4151b3133f215246430c6433f4151b2130c0431b3133f5153f415246433f2151b2130c6430c0433f1151b2131b313246430c6431b3133f4150c0431b3133f2151b513246430c6433f2150c643
01100020240212403524045240452b0212b0352b0452b041270212703527045270452702527035270452704524021240352404524045330213303533045330452b0212b0352b0452b0452b0252b0352b0452b045
01100000180211803518045180451f0211f0351f0451f0411b0211b0351b0451b0451b0251b0351b0451b04518021180351804518045270212703527045270451f0211f0351f0451f0451f0251f0351f0451f045
011000002d0312d04724035240452d0312d04724035240452b0212b0252b0352b0452b0252b0252b0352b0452b0212b0252b0352b0452d0212d0252d0352d0453302133025330353304533025330253303533045
01040000053550a354073550735400355003540a35307354052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e5530e00313655136550e5530e50313655136050e5530e00313655136550e5530e50313655136050e5530e00313655136550e5530e50313655136050e5530e00313655136550e5530e5031365513605
01100000175501742019550194201c5501c4201e5501e4202055521555235552155520555255552655526200175521742019551194201c5511c4201e5511e4202855526555255552655528555235552155521400
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018630166301662013620116200c6200a6200a6100761007610056100561502600116000f6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400040862302020076200202000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001830018100183001810018300181001830018100133001310013300131001330013100133001310011300111001130011100113001110011300111001330013100133001310013300131001330013100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002135021350151000000023350233501c000000002535025350203001e300283502835019300003002a3502a35000300003002c3502c3502a3502a3501c3001c300283502835019300193002535225352
010e00002535225352253522535225352253522535225352253522535225352253522535225352253522535223352233522335223352233522335223352233522335223352233522335223352233522335223352
010e0000253522535225352253522535225352253522535225352253522535225352253522535225352253521700017000170001700017000170001700017000106001700010600170000c000170001700017000
010e00000d073103001240012400106751530012400124000d073103001240012400106751530012400124000d073103001240012400106751530012400124000d07310300124001240010675153001240012400
010e00000d073103001240012400106751530012400124000d073103001240012400106751530012400124000d073103001240012400106751530012400106750d0730c0030d0730c00310675153001060512400
010e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000106751700010675170000d073000000000000000
010e00001e2301e23000000000001e2301e230000000000000000000002123021230002000020021230212301e2001e2001e2301e2301e2001e3001e2301e23021230212301e2301e23023230232302523025230
010e00000000000000000000000000000000000000000000000000000000000000000000000000202302023020230202302123021230202302023021230212302323023230212302123020230202301c2301c230
010e00000613006130121301213006130061301213012130061300613012130121300613006130121301213002130021300e1300e13002130021300e1300e13002130021300e1300e13002130021300e1300e130
010e00000913009130151301513009130091301513015130091300913015130151300913009130151301513008130081301413014130081300813014130141300813008130141301413008130081301413014130
010e00000020000200000000000000000000000000000000000000000000000000000000000000000000000026230262302523025230232302323021230212302123021230232302323021230212302023020230
010e00002135021350151000000023350233501c000000002535025350203001e3002335023350193000030021350213500030000300233502335021350213501c3001c3001e3501e35019300193002135221352
010e00002135221352213522135221352213522135221352213522135221352213522135221352213522135200000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000000000000000000000000000000000000000000000000000000000000000000000000000000000026230262302523025230232302323021230212302123021230232302323021230212301e2301e230
__music__
01 04064344
00 04064344
00 04054344
02 04074344
03 090a4344
00 16195e44
00 17194344
00 16194344
00 181a1b44
01 16191e1c
00 17191f1d
00 16191e1c
00 181a1f20
00 16191e1c
00 17191f1d
00 21191e1c
00 221a1f23
00 41191e44
00 1b1a1f44
00 41191e44
02 1b1a1f44

