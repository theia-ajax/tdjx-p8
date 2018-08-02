pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	chains={}
	actors={}
	
	c1=make_chain()
	
	a1=make_actor(20,20)
	a1.chain=c1
end

function _update()
	c1.bx=64
	c1.by=32

	foreach(actors,
		actor_preupdate)
	foreach(chains,chain_update)
	foreach(actors,
		actor_postupdate)
end

function _draw()
	cls()
	foreach(chains,chain_draw)
	foreach(actors,actor_draw)
	print(a1.dx..","..a1.dy,0,6)
end


function make_chain()
	local chain={}
	
	chain.tx=64
	chain.ty=64
	chain.bx=90
	chain.by=64
	chain.pts={}
	chain.lens={}
	
	for i=1,16 do
		pt={}
		pt.x=chain.bx+(i-1)*5
		pt.y=chain.by
		if i>1 then
			dx=pt.x-chain.pts[i-1].x
			dy=pt.y-chain.pts[i-1].y
			dst=sqrt(dx*dx+dy*dy)
			chain.lens[i]=dst
		end
		chain.pts[i]=pt
	end
	
	add(chains,chain)
	return chain
end

function chain_update(chain)
	local pts=chain.pts
	for j=-1,1,2 do
		local pt,start,finish
		if j==-1 then
			start=#pts-1
			finish=1
			pt=pts[#pts]
			pt.x=chain.tx
			pt.y=chain.ty
		else
			start=2
			finish=#pts
			pt=pts[1]
			pt.x=chain.bx
			pt.y=chain.by
		end
		
		for i=start,finish,j do
			local gx=pts[i-j].x
			local gy=pts[i-j].y
			pt=pts[i]
			local dx=pt.x-gx
			local dy=pt.y-gy
			dx,dy=lnorm(dx,dy)
			local blen
			if j==-1 then
				blen=chain.lens[i+1]
			else
				blen=chain.lens[i]
			end
			pt.x=gx+dx*blen
			pt.y=gy+dy*blen
		end
	end
end

function chain_draw(chain)
	local pts=chain.pts
	for i=2,#pts do
		line(pts[i-1].x,pts[i-1].y,
			pts[i].x,pts[i].y,
			7)
	end
end

gravity=9.81/30
function make_actor(x,y)
	local actor={}
	
	actor.x=x or 0
	actor.y=y or 0
	actor.dx=2
	actor.dy=0
	actor.rad=4
	actor.mass=1
	actor.chain=nil
	
	return add(actors,actor)
end

function
actor_preupdate(actor)
	if actor.chain then
		actor.chain.tx=actor.x
		actor.chain.ty=actor.y
	end
end

function
actor_postupdate(actor)
	actor.dy+=gravity

	if actor.chain then
		local x,y=actor.x,actor.y
		local pts=actor.chain.pts
		local cx=pts[#pts].x
		local cy=pts[#pts].y
		local dx,dy=cx-x,cy-y
		local d2=dx*dx+dy*dy
		if d2>4 then
			local nx,ny=lnorm(dx,dy)
			local mag=mag(actor.dx,
				actor.dy)
			actor.x=cx
			actor.y=cy
		 actor.dx=0
		 actor.dy=0
		end
	end

	actor.x+=actor.dx
	actor.y+=actor.dy
	
	if actor.y+actor.rad>127 then
		actor.y=127-actor.rad
		actor.dy*=-.9
	end
	
	if actor.x+actor.rad>127 then
		actor.x=127-actor.rad
		actor.dx*=-.9
	end
	
	if actor.x-actor.rad<0 then
		actor.x=actor.rad
		actor.dx*=-.9
	end
	

end

function actor_draw(actor)
	circ(actor.x,actor.y,
		actor.rad,7)
	print(actor.x..","..actor.y,0,0)
end

function dist(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return sqrt(dx*dx+dy*dy)
end

function mag(x,y)
	return sqrt(x*x+y*y)
end

function norm(x,y)
	local l=sqrt(x*x+y*y)
	if (l==0) return 0,0
	return x/l,y/l
end

function lnorm(dx,dy)
	local sdist=dx*dx+dy*dy
	local dist
	if abs(dx)>128 or
		abs(dy)>128 or
		abs(dx)+abs(dy)>200
	then
		dx/=10
		dy/=10
		sdist=dx*dx+dy*dy
		dist=sqrt(sdist)*10
	else
		dist=sqrt(sdist)
	end
	return dx/dist,dy/dist
end

