pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	_update60=play_update
	_draw=play_draw
	
	e0=add_entity({
		pos={x=64,y=0},
		vel={x=0,y=1},
		size={x=4,y=8},
		offs={x=0,y=-4},
		input={pid=0},
		pxcol=7,
		spawn={},
		lifetime={frames=0},
	})
	log("test")
end

function play_update()
	sys_update()
	watch("#ents:"..tostr(#sys_ents))
	watch(e0.pos.x..","..e0.pos.y)
	watch(stat(7))
end

function play_draw()
	cls()
	sys_draw()
	
	draw_log()
	draw_watch()
end



-->8
-- entities

invalid_id=0xffff

entity={
	id=invalid_id,
	kill=false,
}

function entity:new(p)
	self.__index=self
	return
		setmetatable(p or {},self)
end

function entity:has(comp)
	return self[comp]~=nil
end

function entity:message(name,...)
	if type(self[name])=="function" then
		self[name](...)
	end
end

_e_id=1
function add_entity(p)
	local e=add(sys_ents,
		entity:new(p))
	e.id=_e_id
	_e_id+=1
	dirty_all_cache()
	return e
end

-->8
-- systems

move_sys={
	comps=
		{"pos","vel"},
	update=function(self,e)
		e.pos.x+=e.vel.x
		e.pos.y+=e.vel.y
	end
}

bounds_sys={
	comps=
		{"pos","vel"},
	update=function(self,e)
		if e.pos.x>127 and e.vel.x>0 then
			e.pos.x=127
			e.vel.x=-e.vel.x
		end
		if e.pos.x<0 and e.vel.x<0 then
			e.pos.x=0
			e.vel.x=-e.vel.x
		end
		if e.pos.y>127 and e.vel.y>0 then
			e.pos.y=127
			e.vel.y=-e.vel.y
		end
		if e.pos.y<0 and e.vel.y<0 then
			e.pos.y=0
			e.vel.y=-e.vel.y
		end
	end
}

lifetime_sys={
	comps=
		{"lifetime"},
	update=function(self,e)
		local life=e.lifetime
		if life.frames>0 then
			life.frames-=1
			if life.frames<=0 then
				e.kill=true
			end
		end
	end,
}

draw_pos_sys={
	comps={"pos","pxcol"},
	draw=function(self,e)
		pset(e.pos.x,e.pos.y,8)
	end
}

draw_size_sys={
	comps={"pos","size","offs"},
	draw=function(self,e)
		local px,py=e.pos.x+e.offs.x,
			e.pos.y+e.offs.y
		local hx,hy=e.size.x/2,e.size.y/2
		rectfill(px-hx,py-hy,
			px+hx,py+hy,
			12)
	end,
}

test_sys={
	comps={"pxcol"},
	update=function(self,e)
		local ix=0
		if (btnp(0)) ix-=1
		if (btnp(1)) ix+=1
		e.pxcol+=ix
	end
}

test_ivl_sys={
	comps={"pos","spawn"},
	update=function(self,e)
		if btn(4) then
			local a=rnd()
			local vx=cos(a)*4
			local vy=sin(a)*4
			log(vx*vx+vy*vy)
			local n=add_entity({
				pos={x=e.pos.x,y=e.pos.y},
				vel={x=vx,y=vy},
				lifetime={frames=60*10},
				pxcol=7
			})
		end
	end
}

sys_systems={
	lifetime_sys,
	move_sys,
	bounds_sys,

	draw_size_sys,
	draw_pos_sys,
	test_sys,
	test_ivl_sys,
}

sys_ents={}

function sys_exec(name)
	for i,sys in ipairs(sys_systems) do
		if type(sys[name])=="function"
		then
			local intvl=nil
			if sys.intvls then
				intvl=sys.intvls[name]
			end
			local skip=false
			if intvl then
				sys.timers=sys.timers or {}
				sys.timers[name]=
					sys.timers[name] or 0
				if sys.timers[name]>0 then
					sys.timers[name]-=1
					skip=true
				else
					sys.timers[name]=intvl
				end
			end
			
			if not skip then
				if not sys.cache then
					sys.cache=gather_ents(
						sys,sys_ents)
				end
				foreach(sys.cache,function(e)
					sys[name](sys,e)
				end)
			end
		end
	end
end

function deep_clone(tbl)
	local ret={}
	for k,v in pairs(tbl) do
		if type(v)=="table" then
			ret[k]=deep_clone(v)
		else
			ret[k]=v
		end
	end
	return ret
end

function sys_update()
	sys_exec("update")
	garbage_collect_ents()
end

function sys_draw()
	sys_exec("draw")
end

function garbage_collect_ents()
	local ents=sys_ents
	local n=#ents
	local any=false
	for i=n,1,-1 do
		if ents[i].kill then
			for j=i,n do
				ents[j]=ents[j+1]
			end
			n-=1
			any=true
		end
	end
	
	if any then
		dirty_all_cache()
	end
end

function gather_ents(sys,ents)
	if sys.comps==nil then
		return {}
	end
	
	local result={}

	for i,e in ipairs(ents) do
		local valid=true
		for i,comp in ipairs(sys.comps) do
			if not e:has(comp) then
				valid=false
				break
			end
		end
		if valid then
			add(result,e)
		end
	end
			
	return result
end

function dirty_all_cache()
	for sys in all(sys_systems) do
		sys.cache=nil
	end
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
-->8
_logs={}
_watch={}

function log(m)
	add(_logs,tostr(m))
	if #_logs>21 then
		for i=1,22 do
			_logs[i]=_logs[i+1]
		end
	end
end

function watch(m)
	add(_watch,tostr(m))
end

function draw_log()
	for i,m in ipairs(_logs) do
		local ml=#m*4
		print(m,129-ml,(i-1)*6,6)
	end
end

function draw_watch()
	for i,m in ipairs(_watch) do
		print(m,0,(i-1)*6,11)
	end
	_watch={}
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
