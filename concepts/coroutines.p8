pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function wait_frames(n)
	while n>0 do
		n-=1
		yield()
	end
end

function _init()
	obj={x=64,y=64}
	
	a=cocreate(function()
		for i=0,10 do
			obj.x+=1
			wait_frames(5)
		end
	end)
end

function _update()
	if costatus(a)=="suspended" then
		assert(coresume(a))
	end
end

function _draw()
	cls()
	circfill(obj.x,obj.y,4,7)
end
