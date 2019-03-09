pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	rx,ry=99.2609,36.7182
	rr=-1.1194
	rdx,rdy=1,0
	rlen=5
	
	ax,ay=87.8506,26.0861
	bx,by=85.2175,23.6325
end

function _update()
	if (btn(0)) rr+=0.01
	if (btn(1)) rr-=0.01
	if (btn(2)) rx+=cos(rr)*1; ry+=sin(rr)*1
	if (btn(3)) rx-=cos(rr)*1; ry-=sin(rr)*1
	
	rdx,rdy=cos(rr),sin(rr)
	
	hit,dist=ray_line_check(
		rx,ry,rdx,rdy,ax,ay,bx,by)
end

function _draw()
	cls()

	line(rx,ry,rx+rdx*rlen,ry+rdy*rlen,9)
	pset(rx,ry,10)

	line(ax,ay,bx,by,5)
	pset(ax,ay,8)
	pset(bx,by,12)

	if hit and dist<=rlen then
		print("hit "..tostr(dist),0,0,11)
	else
		print("miss",0,0,8)
	end
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
