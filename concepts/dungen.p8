pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include ../util.p8

sleepf=0

function _init()
	rooms={}
	doors={}
	
	
	
	gen_cr=cocreate(gen_map)
end

function gen_map()
	for i=1,60 do
		add_room(0,0)
	end
	
	local moved_room=nil

	local finished=false
	
	local dirwt=shuffle({7,8,8,9})
	local sizewt={1,4}
	
	while not finished do
		finished=true
		for i=1,#rooms-1 do
			for j=i+1,#rooms do
				local r1=rooms[i]
				local r2=rooms[j]
				if r1.x==r2.x and r1.y==r2.y
				then
					finished=false
					local r=r1
					if r2.id>r1.id then
						r=r2
					end
					--r.moved=true
					moved_room=r
					r.fromx=r.x
					r.fromy=r.y
					local d=rnd_wt(dirwt)-1
					if d==0 then
						r.x-=1
					elseif d==1 then
						r.x+=1
					elseif d==2 then
						r.y-=1
					elseif d==3 then
						r.y+=1
					end
					break
				end
			end
		end
		yield()
	end
	
	local sizes={1,3}
	for r in all(rooms) do
		local n=room_by_xy(
			r.fromx,r.fromy)
		if n then
			local sz=sizes[rnd_wt(sizewt)]
			add_door(r,n,sz)
		end
	end
end

function _update()
	if sleepf>0 then
		sleepf-=1
		return
	end

	if gen_cr and costatus(gen_cr)~="dead" then
		coresume(gen_cr)
	end
end

function _draw()
	cls()

	for r in all(rooms) do
		local x1,y1=r.x*8+60,r.y*8+60
		local x2,y2=x1+8,y1+8
		if not r.moved then
			rectfill(x1,y1,x2,y2,6)
		end
	 rect(x1,y1,x2,y2,8)
	end

	for r in all(rooms) do
		local x1,y1=r.x*8+60,r.y*8+60
		local x2,y2=x1+8,y1+8
		if r.moved then
			rectfill(x1,y1,x2,y2,12)
		end
	 rect(x1,y1,x2,y2,8)
	end


	for r in all(rooms) do
		local cx,cy=r.x*8+64,r.y*8+64
		local x1,y1=cx-4,cy-4
		local x2,y2=cx+4,cy+4

	 for d=0,3 do
	 	local sz=r.doors[d+1]
	 	if sz>0 then
	 		if d==0 then
	 			line(x2,cy-sz,x2,cy+sz,6)
	 		elseif d==1 then
	 			line(cx-sz,y1,cx+sz,y1,6)
	 		elseif d==2 then
	 			line(x1,cy-sz,x1,cy+sz,6)
	 		elseif d==3 then
	 			line(cx-sz,y2,cx+sz,y2,6)
	 		end
	 	end
	 end
	end
end

_room_id=0
function add_room(x,y)
	local room={}
	room.x=x or 0
	room.y=y or 0
	room.fromx=room.x
	room.fromy=room.y
	room.doors={
		0,0,0,0
	}
	
	room.id=_room_id
	_room_id+=1
	
	add(rooms,room)
end

function add_door(r1,r2,sz)
	local cdir1=room_adj_cdir(r1,r2)
	local cdir2=room_adj_cdir(r2,r1)
	
	if cdir1>=0 then
		r1.doors[cdir1+1]=sz or 1
		r2.doors[cdir2+1]=sz or 1
	end
end

function room_by_xy(x,y)
	for r in all(rooms) do
		if r.x==x and r.y==y then
			return r
		end
	end
	return nil
end

function room_adj_cdir(r1,r2)
	if r1.y==r2.y then
		if r2.x-r1.x==1 then
			return 0
		elseif r1.x-r2.x==1 then
			return 2
		end
	elseif r1.x==r2.x then
		if r2.y-r1.y==1 then
			return 3
		elseif r1.y-r2.y==1 then
			return 1
		end
	end
	return -1
end

function sleep(frm)
	sleepf=frm
end
