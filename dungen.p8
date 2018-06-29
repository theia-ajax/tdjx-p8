pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
sleepf=0

function _init()
	rooms={}
	doors={}
	
	for i=1,80 do
		add_room(0,0)
	end
end

function _update()
	if sleepf>0 then
		sleepf-=1
		return
	end

	for r in all(rooms) do
		r.moved=false
	end

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
				r.moved=true
				r.fromx=r.x
				r.fromy=r.y
				local d=flr(rnd(4))
				if d==0 then
					r.x+=1
				elseif d==1 then
					r.y-=1
				elseif d==2 then
					r.x-=1
				elseif d==3 then
					r.y+=1
				end
				break
			end
		end
	end
	
	::stop_gen::
	
	if finished then
		for r in all(rooms) do
			local n=room_by_xy(
				r.fromx,r.fromy)
			if n then
				add_door(r,n)
			end
		end
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
	 	if r.doors[d+1] then
	 		if d==0 then
	 			line(x2,cy-1,x2,cy+1,6)
	 		elseif d==1 then
	 			line(cx-1,y1,cx+1,y1,6)
	 		elseif d==2 then
	 			line(x1,cy-1,x1,cy+1,6)
	 		elseif d==3 then
	 			line(cx-1,y2,cx+1,y2,6)
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
		false,false,false,false
	}
	
	room.id=_room_id
	_room_id+=1
	
	add(rooms,room)
end

function add_door(r1,r2)
	local cdir1=room_adj_cdir(r1,r2)
	local cdir2=room_adj_cdir(r2,r1)
	
	if cdir1>=0 then
		r1.doors[cdir1+1]=true
		r2.doors[cdir2+1]=true
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
