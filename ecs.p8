pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
component={
	entity=-1,
	owner=nil,
	name="base",
}

function component:new(p)
	self.__index=self
	return setmetatable(p or {},
		self)
end

comp_pos=component:new({
	name="pos",
	x=0,y=0,
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

comp_list={}

function comp_list:new(comp_t)
	assert(comp_t and
		type(comp_t.new)=="function")

	-- init free stack
	-- todo: configurable size
	--							dynamic resize
	local free_stack={}
	local size=128
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
end

function comp_list:del(entity)
	assert(self.entity_idx[entity])
	local idx=self.entity_idx[entity]
	
	-- todo: events or something
	
	self.data[idx]=nil
	self.free_head+=1
	self.free_s[self.free_head]=idx
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
	
	self.__index=self
	return setmetatable(
		sys,self)
end

function system:gather()
	-- todo: dirty checking
	
	if not self.dirty then
		return
	end
	
	clr(self.entrefs)
	
	local ct=self.look[1]
	for ent,idx in pairs(ecs.components[ct].entity_idx) do
		local ref={entity=ent}
		ref[ct.name]=ecs.components[ct].data[idx]
		add(self.entrefs,ref)
	end
	
	local filter=function(refs,ct)
		local len=#refs
		for i=1,len do
			local r=refs[i]
			local comp=ecs.components[ct]:get(r.entity)
			if comp  then
				r[ct.name]=comp
			else
				refs[i]=nil
			end
		end
		compress(refs,len)
		return refs
	end
	
	for i=2,#self.look do
		self.entrefs=filter(
			self.entrefs,
			self.look[i])
	end
	
	self.dirty=false
end

draw_pos_sys=system:new({
	look={comp_pos,comp_col}})
	
function draw_pos_sys:draw()
	for ref in all(self.entrefs) do
		pset(ref.pos.x,
			ref.pos.y,
			ref.col.col)
	end
end

test_sys=system:new({
	look={comp_pos,comp_vel,comp_col}})
	
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
		if ref.entity==1 then
			print(ref.vel.x,0,20,7)
		end
		ref.pos.x+=ref.vel.x*dt
		ref.pos.y+=ref.vel.y*dt
	end
end

function init_ecs()
	assert(ecs==nil)
	ecs={
		next_ent_id=0,
		entities={},
		components={},
		systems={},
	}
end

function ecs_reg_component(comp_t)
	ecs.components[comp_t]=
		comp_list:new(comp_t)
end

function ecs_make_entity()
	-- todo:track free spaces
	local entity=ecs.next_ent_id
	ecs.entities[entity]=entity
	ecs.next_ent_id+=1
	return entity
end

function
ecs_add_component(entity,comp_t,param)
	ecs.components[comp_t]:add(
		entity,param)
		
	for sys in all(ecs.systems) do
		for l in all(sys.look) do
			if l==comp_t then
				sys.dirty=true
			end
		end
	end
end


function _init()
	init_ecs()
	ecs_reg_component(comp_pos)
	ecs_reg_component(comp_vel)
	ecs_reg_component(comp_col)

	ecs.systems[1]=test_sys
	ecs.systems[2]=draw_pos_sys
	
	for i=1,100 do
		local e=ecs_make_entity()
		ecs_add_component(e,comp_pos,
			{x=rnd(128),y=rnd(128)})
		ecs_add_component(e,comp_vel)

	if i%2==0 then
		ecs_add_component(e,comp_col,
			{col=flr(rnd(15))+1})
		end
	end
end

function _update()
	if btnp(4) then
		local e=ecs_make_entity()
		ecs_add_component(e,comp_pos,
			{x=rnd(128),y=rnd(128)})

		ecs_add_component(e,comp_col,
			{col=flr(rnd(15))+1})
	end

	for sys in all(ecs.systems) do
		sys:gather()
	end
	
	for sys in all(ecs.systems) do
		if sys.update then
			sys:update(1/30)
		end
	end
end

function _draw()
	cls()
	for sys in all(ecs.systems) do
		if sys.draw then
			sys:draw()
		end
	end
	
	print("cpu:"..tostr(band(stat(1)*100,0xffff)).."%",0,0,11)
	print("ren:"..tostr(band(stat(2)*100,0xffff)).."%",0,6,11)
	print("mem:"..band(stat(0),0xffff).."/2048",0,12,11)
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
		while j>1 and lt(a[j],a[j-1]) do
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
