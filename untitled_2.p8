pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	_update60=play_update
	_draw=play_draw
end

function play_update()

end

function play_draw()
end

function add_entity(ent)
	return add(entities,ent)
end




function ent_has(ent,comp)
	assert(type(ent)=="table")
	assert(type(comp)=="string")
	return type(ent[comp])=="table"
end

-->8
-- entities

invalid_id=0xffff

entity={
	id=invalid_id
	kill=false,
	comps={},
}

function entity:new(p)
	self.__index=self
	return
		setmetatable(p or {},self)
end

-->8
-- systems

move_sys={
	comps=
		{"pos","vel"},
	update=function(self,ents)
		for i,e in ipairs(ents) do
			e.pos.x+=e.vel.x
			e.pos.y+=e.vel.y
		end
	end
}

lifetime_sys={
	comps=
		{"lifetime"},
	update=function(self,ents)
		for i,e in ipairs(ents) do
			local life=e.lifetime
			if life.frames>0 then
				life.frames-=1
				if life.frames<=0 then
					e.kill=true
				end
			end
		end
	end,
}

systems={
	lifetime_sys,
	move_sys,
}

function sys_preupdate()
end

function sys_update()
end

function sys_postupdate()
end

function sys_draw()
end

-- garbage collect
function sys_gc()
	
end

function _sys_gather_ents(self)
	
end
-->8
function make_flags(tbl)
	local flags={}
	flags["none"]=0
	for i,v in ipairs(tbl) do
		assert(type(v)=="string")
		flags[v]=shl(1,i-1)
	end
	return flags
end

function test_flag(bits,flag)
	return band(bits,flag)==flag
end

function set_flag(bits,flag,v)
	if v then
		return bor(bits,flag)
	else
		return band(bits,bnot(flag))
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
