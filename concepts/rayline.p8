pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	rx,ry=99.2609/8,36.7182/8
	rr=-1.1194
	rdx,rdy=1,0
	rlen=5/8
	
	hits={}
	
	pts={}
--[[	for i=0,20 do
		add(pts,{
			x=cos(i/20)*7+8,
			y=sin(i/20)*5+8
		})
	end]]
	
	pts={
		{x=2,y=9},
		{x=14,y=9},
		{x=12,y=15},
		{x=4,y=15},
		{x=2,y=9},
	}
end

function _update()
	hits={}
	hits.byseg={}

	if (btn(0)) rr+=0.025
	if (btn(1)) rr-=0.025
	if (btn(2)) rx+=cos(rr)*1/8; ry+=sin(rr)*1/8
	if (btn(3)) rx-=cos(rr)*1/8; ry-=sin(rr)*1/8
	
	rdx,rdy=cos(rr),sin(rr)
	
	local n=#pts
	for i=1,n-1 do
		local a,b=pts[i],pts[i+1]
		local hit,dist=ray_line_check(
			rx,ry,rdx,rdy,a.x,a.y,b.x,b.y)
		
		if hit and dist<=rlen then
			local data=add(hits,{
				segid=i,
				dist=dist,
			})
			hits.byseg[i]=data
		end
	end
end

function _draw()
	cls()

	line(rx*8,ry*8,rx*8+rdx*rlen*8,ry*8+rdy*rlen*8,9)
	pset(rx*8,ry*8,10)

	local n=#pts
	for i=1,n-1 do
		local a,b=pts[i],pts[i+1]
		local h=hits.byseg[i]
		local c=5
		if (h) c=8
		line(a.x*8,a.y*8,b.x*8,b.y*8,c)
		
	end
	
	foreach(pts,function(p)
		pset(p.x*8,p.y*8,12)
	end)
end


function
ray_line_check
(ox,oy,dx,dy,ax,ay,bx,by)

 local tox,toy=ox-ax,oy-ay
 local dlx,dly=bx-ax,by-ay
 local px,py=-dy,dx
 
 local dot=dlx*px+dly*py
 
 if dot==0 then
 	return false,-1
 end
 
 --x1*y2-y1*x2
 local det=dlx*toy-dly*tox
 local hit=det/dot

	local pos=(tox*px+toy*py)/dot
	
	return (hit>=0 and
		pos>=0 and pos<=1),hit,pos
end
