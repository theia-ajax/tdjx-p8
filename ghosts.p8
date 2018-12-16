pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	ghosts={}
	
	for i=1,20 do
		add_ghost()
	end
end

function add_ghost()
	add(ghosts,{x=rnd(128),y=rnd(128),dx=rnd(2)-1,dy=rnd(2)-1,r=2+rnd(2)})
end

function _update()
	for g in all(ghosts) do
		g.x+=g.dx*1/30
		g.y+=g.dy*1/30
		for h in all(ghosts) do
			if g~=h then
				local dx=g.x-h.x
				local dy=g.y-h.y
				if sqrt(dx*dx+dy*dy)<=g.r+h.r then
					g.destroy,h.destroy=true,true
				end
			end
		end
	end
	
	for g in all(ghosts) do
		if g.destroy then del(ghosts,g) end
	end
	
	if #ghosts<20 and t()%1==0 and rnd()<0.25 then
		add_ghost()
	end
end

function _draw()
	cls()
	for g in all(ghosts) do
		circfill(g.x,g.y,g.r,6)
	end
end
