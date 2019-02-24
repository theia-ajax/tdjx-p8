pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
	ecs.systems[1]=test_sys
	ecs.systems[2]=draw_pos_sys
	
	for i=1,100 do
		local z=flr(rnd(3))
		local e=ecs:make_entity({
			components={
				{
					comp_t=comp_pos,
					data={x=rnd(128),y=rnd(128),z=z}
				},
				{
					comp_t=comp_vel
				},
				{
					comp_t=comp_col,
					data={col=z+5}
				},
			}
		})
	end
	
	cpu_val=0
	cpu_max=0
	cpu_max_t=0
	
	tf=0
end

--[[function _update()
	dt=1/30
	update()
end]]

function _update60()
	dt=1/60
	update()
end
di=0
function update()
	tf+=1

	if btnp(4) then
		ecs:rem_entity(di)
		di+=1
	end

	if btnp(5) then
		local e=ecs:make_entity({
			components={
				{comp_t=comp_pos,data={x=rnd(128),y=rnd(128)}},
				{comp_t=comp_vel},
				{comp_t=comp_col,data={col=flr(rnd(15))+1}},
			}
		})
	end

	ecs:update(dt)
	
	cpu_val=band(stat(1)*100,0xffff)
	if cpu_val>cpu_max then
		cpu_max=cpu_val
		cpu_max_t=t()
	else
		if t()-cpu_max_t>5 then
			cpu_max=cpu_val
		end
	end
end

function _draw()
	cls()
	ecs:draw()
	
	lastval=cpuval
	
	
	if lastval and cpuval>lastval then
		log("cpu up:"..cpuval,8)
	end
	
	print("cpu:"..cpu_val.."%".." max:"..cpu_max.."%",0,0,11)
	print("ren:"..tostr(band(stat(2)*100,0xffff)).."%",0,6,11)
	print("mem:"..band(stat(0),0xffff).."/2048",0,12,11)
	
	draw_log()
end


-->8
-- util

-- slow but maintains order
function compress_slow(a,n)
	local n=n or #a
	local i=1
	while i<n do
		local j=i
		while a[j]==nil and j<n do
			local k=j+1
			while k<n and a[k]==nil do
				k+=1
			end
			a[j]=a[k]
			a[k]=nil
			j=k
		end
		i+=1
	end
end

function idel(a,i)
	local n=#a
	if (i<1 or i>n) return
	a[i]=nil
	
	for j=i,n-1 do
		a[j]=a[j+1]
	end
	a[n]=nil
end

function idel_fast(a,i)
	local n=#a
	assert(n>0)
	a[i]=a[n]
	a[n]=nil
end


function compress(a,n)
	local n=n or #a
	local h,t=1,n

	-- wind tail back to first
	-- non-nil entry in case len
	-- is wrong
	while a[t]==nil and t>h do
		t-=1
	end

	while h<t do
		if a[h]==nil then
			a[h]=a[t]
			a[t]=nil
			while a[t]==nil and t>h do
				t-=1
			end
		end
		h+=1
	end
end

function sort(a,lt,n)
	local n=n or #a
	local i=2
	while i<=n do
		local j=i
		while j>1 and lt(a[j-1],a[j]) do
			a[j],a[j-1]=a[j-1],a[j]
			j-=1
		end
		i+=1
	end
end

function clr(a,n)
	local n=n or #a
	for i=1,n do	a[i]=nil end
end

_log={}
function log(msg,col)
	add(_log,{msg=tostr(msg),
		col=col or 6})
	if #_log>20 then
		for i=1,20 do
			_log[i]=_log[i+1]
		end
		_log[21]=nil
	end
end

function draw_log()
	for i=1,#_log do
		local l=_log[i]
		local len=#l.msg
		print(l.msg,
			127-len*4,(i-1)*6,l.col)
	end
end

-->8
component={
	entity=-1,
	name="base",
	requires={},
	owner=nil,
}

function component:new(p)
	self.__index=self
	return setmetatable(p or {},
		self)
end

comp_list={}

function comp_list:new(comp_t)
	assert(comp_t and
		type(comp_t.new)=="function")

	-- init free stack
	-- todo: configurable size
	--							dynamic resize
	local free_stack={}
	local size=512
	for i=1,size do
		free_stack[i]=size-i+1
	end

	self.__index=self
	return setmetatable({
			comp_t=comp_t,
			entity_idx={},
			data={},
			size=size,
			free_s=free_stack,
			free_head=size,
		},self)
end

function comp_list:add(entity,param)
	assert(not self.entity_idx[entity])
	
	param=param or {}
	param.entity=entity
	param.owner=self
	local c=self.comp_t:new(param)
	
	assert(self.free_head>0,"out of space")
	
	local idx=self.free_s[self.free_head]
	self.free_head-=1
	
	self.entity_idx[entity]=idx
	self.data[idx]=c
	return c,idx
end

function comp_list:del(entity)
	if not self.entity_idx[entity] then
		return false
	end

	local idx=self.entity_idx[entity]
	
	-- todo: events or something
	
	self.data[idx]=nil
	self.free_head+=1
	self.free_s[self.free_head]=idx
	self.entity_idx[entity]=nil
	
	return true
end

function comp_list:get(entity)
	local idx=self.entity_idx[entity]
	if not idx then
		return nil
	else
		return self.data[idx]
	end
end

system={
	name="base",
	look={},
	update=nil,
	draw=nil,
	dirty=false,
}

function system:new(sys)
	assert(sys)
	assert(sys.look)
	assert(#sys.look>0)
	
	-- ensure fresh ref table
	-- on system
	sys.entrefs={}
	
	local has={}
	for ct in all(sys.look) do
		if not has[ct] then
			for r in all(ct.required) do
				if not has[r] then
					add(sys.look,r)
					has[r]=true
				end
			end
			has[ct]=true
		end
	end
	
	for l in all(sys.look) do
		sys.look[l]=true
	end
	
	self.__index=self
	return setmetatable(
		sys,self)
end

function system:dirty_entity(entity)
	local match=true
	for l in all(self.look) do
		if not ecs.components[ct]:get(entity) then
			match=false
			break
		end
	end
	
	if not match then
		
end

function system:gather(ecs)
	-- todo: dirty checking
	
	if not self.dirty then
		return
	end
	
	clr(self.entrefs)
	
	local ct,len=self.look[1],0
	for ent,idx in pairs(ecs.components[ct].entity_idx) do
		add(self.entrefs,ecs.entities[ent])
		len+=1
	end
	
	local filter=function(refs,len,ct)
		for i=len,1,-1 do
			local r=refs[i]
			local comp=ecs.components[ct]:get(r.entity)
			if comp  then
				r[ct.name]=comp
			else
				idel_fast(refs,i)
			end
		end
		return refs
	end
	
	for i=2,#self.look do
		filter(
			self.entrefs,
			len,
			self.look[i])
	end
	
	self.dirty=false
end

ecs={
	next_ent_id=0,
	entities={},
	components={},
	systems={},
	remove_q={},
}

function ecs:make_entity(prefab)
	local entity=self.next_ent_id
	self.next_ent_id+=1
	self.entities[entity]={
		entity=entity
	}
	local p=prefab or {}
	local comps=p.components or {}
	for c in all(comps) do
		self:add_component(entity,
			c.comp_t,c.data)
	end
	return entity
end

function ecs:rem_entity(entity)
	add(self.remove_q,entity)
end

function ecs:update(dt)
	for sys in all(ecs.systems) do
		sys:gather(ecs)
	end
	
	for sys in all(ecs.systems) do
		if sys.update then
			sys:update(dt)
		end
	end
	
	for entity in all(self.remove_q) do
		for ct,cl in pairs(self.components) do
			if cl:del(entity) then
				for sys in all(self.systems) do
					if sys.look[ct] then
						sys.dirty=true
					end
				end
			end
		end
		self.entities[entity]=nil
	end

	clr(self.remove_q)
end

function ecs:draw()
	for sys in all(ecs.systems) do
		if sys.draw then
			sys:draw()
		end
	end
end

function
ecs:add_component(entity,comp_t,param)
	if not self.components[comp_t]
	then
		self.components[comp_t]=
			comp_list:new(comp_t)
	end
		
	local comp,idx=
		self.components[comp_t]:add(
			entity,param)
		
	local ref=self.entities[entity]
	ref[comp_t.name]=comp
	
	for sys in all(self.systems) do
		if not sys.dirty then
			for l in all(sys.look) do
				if l==comp_t then
					sys.dirty=true
					break
				end
			end
		end
	end
end

-->8
comp_pos=component:new({
	name="pos",
	x=0,y=0,z=0,
})

function comp_pos:new(p)
	self.__index=self
	return setmetatable(
		component:new(p),self)
end

comp_vel=component:new({
	name="vel",
	x=0,y=0,
})

comp_col=component:new({
	name="col",col=7})
	
function comp_col:new(p)
	self.__index=self
	return setmetatable(
		component:new(p),self)
end

-->8
draw_pos_sys=system:new({
	name="draw_pos",
	look={comp_pos,comp_col}})
	
function draw_pos_sys:draw()
	sort(self.entrefs,
		function(a,b)
			return a.pos.z<b.pos.z
		end)

	for ref in all(self.entrefs) do
		circfill(ref.pos.x,
			ref.pos.y,
			4,
			ref.col.col)
	end
end

test_sys=system:new({
	name="test",
	look={comp_pos,comp_vel}})
	
function test_sys:update(dt)
	for ref in all(self.entrefs) do
		local dx=64-ref.pos.x
		local dy=64-ref.pos.y
		local l=0
		if dx~=0 and dy~=0 then
			l=sqrt(dx*dx+dy*dy)
			dx/=l
			dy/=l
		end
		ref.vel.x+=dx*10*dt
		ref.vel.y+=dy*10*dt
		ref.pos.x+=ref.vel.x*dt
		ref.pos.y+=ref.vel.y*dt
	end
end
