pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function do_move(body,cmd,ct)
	local mx,my=0,0
	if (cmd=="r") mx=1
	if (cmd=="l") mx=-1
	if (cmd=="d") my=1
	if (cmd=="u") my=-1
	for i=1,ct do
		move(body,mx,my)
		local h=hash(body[#body])
		visit[h]=true
	end	
end

function _init()
	body={}
	for i=1,10 do
		add(body,{x=0,y=0})
	end
	visit={}
	hide=false
	slow=false
--
--	do_move(body,"r",5)
--	do_move(body,"u",8)
--	do_move(body,"l",8)
--	do_move(body,"d",3)
--	do_move(body,"r",17)
--	do_move(body,"d",10)
--	do_move(body,"l",25)
--	do_move(body,"u",20)
end

function hash(b)
	return (((b.x+128)&0xff)<<8)|((b.y+128)&0xff)
end

function unhash(h)
	local x=((h>>8)&0xff)-128
	local y=(h&0xff)-128
	return x,y
end

function touch(b1,b2,mx,my)
	mx=mx or 0
	my=my or 0
	local dx,dy=abs(b1.x+mx-b2.x),
		abs(b1.y+my-b2.y)
	return dx<=1 and dy<=1
end

function touch2(b1,b2,mx,my)
	mx=mx or 0
	my=my or 0

	local dx,dy=abs(b1.x+mx-b2.x),
		abs(b1.y+my-b2.y)
	return (dx==0 and dy==0)
		or (dx==1 and dy==0)
		or (dx==0 and dy==1)
end

function seq_move(body,dx,dy,off)
	if not seq then
		seq=cocreate(function()
			move(body,dx,dy,off)
		end)
	end
end

function sgn3(v)
	if (v==0) return 0
	return sgn(v)
end

function move(body,dx,dy,off)
	off=off or 1
	local b0=nil
	if (off>1) b0=body[off-1]
	local b1=body[off]
	local b2=body[off+1]
	

--	
	if b0 and dx~=0 and dy~=0 then
		if touch2(b1,b0,dx,0) then
			dy=0
		elseif touch2(b1,b0,0,dy) then
			dx=0
		end
	end

	gdx=dx
	gdy=dy
	b1.x+=dx
	b1.y+=dy
	
	if not b2 then
		return
	end
	
	if not touch(b1,b2) then
		
		if b1.x~=b2.x and b1.y~=b2.y
		then
			if dx~=0 then

			 dy=sgn3(b1.y-b2.y)
--			 b2.y=b1.y
			elseif dy~=0 then
--				ctx.odx=dx
				dx=sgn3(b1.x-b2.x)
--				b2.x=b1.x
			end
		end
		
		 if (slow)	wait_step()
		move(body,dx,dy,off+1)
	end
end

function wait_sec(s)
	while s>0 do
		s-=1/30
		yield()
	end
end

function wait_step()
	while not step do
		yield()
	end
	step=false
end

function _update()
	local dx,dy=0,0
	
	if not seq then
		if (btnp(0)) seq_move(body,-1,0)
		if (btnp(1)) seq_move(body,1,0)
		if (btnp(2)) seq_move(body,0,-1)
		if (btnp(3)) seq_move(body,0,1)
		
		local h=hash(body[#body])
		visit[h]=true
		if (btnp(❎)) slow=not slow
		if (btnp(🅾️)) hide=not hide
	else
		if costatus(seq)=="suspended"
		then
			assert(coresume(seq))
		else
			seq=nil
		end
		if (btnp(❎)) step=true
	end
	

	
end

function _draw()
	cls()
	
	local ct=0
	for h,_ in pairs(visit) do
		local x,y=unhash(h)
		local sx,sy=w2s(x,y)
		local c=1
		if (x==0 and y==0) c=14
		pset(sx,sy,c)
		ct+=1
	end
	
	if not hide then
	local hw,hh=2,2
	for i=#body,1,-1 do
		local b=body[i]
		local bx,by=w2s(b.x,b.y)
		local c=7
		if (i>1) c=8+(i%7)
		rectfill(bx-hw,by-hw,bx+hw-1,by+hh-1,c)
	end
	end
end

function w2s(x,y)
	return x*4+64,y*4+64
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
