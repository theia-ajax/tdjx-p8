pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

poke(0x5f2d, 1)

chains={}

count=50
for j=1,count do
	chain={}
	
	chain.tx=64
	chain.ty=30
	chain.bx=0
	chain.by=j*24
	chain.t=j/count

	chain.points={}
	chain.lengths={}
	
	for i=1,8 do
		point={}
		point.x=chain.bx+(i-1)*15
		point.y=chain.by
		if (i>1) then
			dx=point.x-chain.points[i-1].x
			dy=point.y-chain.points[i-1].y
			dist=sqrt(dx*dx+dy*dy)
			chain.lengths[i]=dist
		end
		chain.points[i]=point
	end
	chain.col=(j+2)%15+1
	add(chains,chain)
end

function norm(dx,dy)
	local sdist=dx*dx+dy*dy
	local dist
	if (abs(dx)>128 or abs(dy)>128 or abs(dx)+abs(dy)>200) then
		dx/=10
		dy/=10
		sdist=dx*dx+dy*dy
		dist=sqrt(sdist)*10
	else
		dist=sqrt(sdist)
	end
	return dx/dist,dy/dist
end

function _update()

	for chain in all(chains) do
		local points=chain.points
		chain.tx=stat(32)+.5
		chain.ty=stat(33)+.5
		
		chain.t+=1/300
		if (chain.t>=1) then
			chain.t-=1
		end
		if (chain.t<.25) then
			chain.bx=0
			chain.by=127*chain.t/.25
		elseif (chain.t<.5) then
			chain.bx=127*(chain.t-.25)/.25
			chain.by=127
		elseif (chain.t<.75) then
			chain.bx=127
			chain.by=127*(1-(chain.t-.5)/.25)
		else
			chain.bx=127*(1-(chain.t-.75)/.25)
			chain.by=0
		end
	
		for j=-1,1,2 do
			local point
			local start
			local finish
			if (j==-1) then
				start=#points-1
				finish=1
				point=points[#points]
				point.x=chain.tx
				point.y=chain.ty
			else
				start=2
				finish=#points
				point=points[1]
				point.x=chain.bx
				point.y=chain.by
			end
			
			for i=start,finish,j do
				local gx=points[i-j].x
				local gy=points[i-j].y
				point=points[i]
				local dx=point.x-gx
				local dy=point.y-gy
				dx,dy=norm(dx,dy)
				local blength
				if (j==-1) then
					blength=chain.lengths[i+1]
				else
					blength=chain.lengths[i]
				end
				point.x=gx+dx*blength
				point.y=gy+dy*blength
			end
		end
	end
end

function _draw()
	cls()
	local bcount=0
	for chain in all(chains) do
		local points=chain.points
		bcount+=#points
		for i=2,#points do
			line(points[i-1].x,points[i-1].y,
			     points[i].x,points[i].y,
			     chain.col)
		end
	end
	
	local mem=flr((stat(0)/1024)*100)
	local cpu=flr(stat(1)*100)
	print("mem: "..mem.."%",1,1,7)
	print("cpu: "..cpu.."%",1,7,7)
	print("bones: "..bcount,1,13,5)
end
