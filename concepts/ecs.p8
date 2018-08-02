pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- ecs
-- tdjx

function _init()
	ents={}
	for i=0,100 do
		entity({
			-- position
			pos={x=rnd(128),y=rnd(128)},
			-- heading
			hed=rnd(),
			col=11,
			sz=3
		})
	end

	rements=system({"flags"},
		function (e)
			if ent_hasflg(e,_k_ent_flg_destroy)
			then
				add(ents_rq,e.id)
			end
		end)

	movents=system({"pos","hed"},
		function (e)
			local dx,dy=cos(e.hed),sin(e.hed)
			e.pos.x+=dx*1
			e.pos.y+=dy*1
			local dstx,dsty=e.pos.x-64,e.pos.y-64
			local d=sqrt(dstx*dstx+dsty*dsty)
			if d>40 then
				tg=atan2(64-e.pos.x,64-e.pos.y)
				e.hed=anglerp(e.hed,tg,0.1)
			end
		end)

	drawents=system({"pos","col","hed","sz"},
		function(e)
			circ(e.pos.x,e.pos.y,e.sz,e.col)
			line(e.pos.x,e.pos.y,
				e.pos.x+cos(e.hed)*e.sz,
				e.pos.y+sin(e.hed)*e.sz,
				e.col)
		end)
end

function _update()
	movents(ents)
	-- rements(ents)

	-- for remid in all(ents_rq) do
	-- 	for i=1,#ents do
	-- 		local e=ents[i]
	-- 		if e.id==remid then
	-- 			idelf(ents,i)
	-- 			break
	-- 		end
	-- 	end
end

function _draw()
	cls()
	drawents(ents)
end

function _has(e, ks)
  for k,v in pairs(ks) do
    if not e[v] then
      return false
    end
  end
  return true
end

function system(ks, f)
  return function(es)
    for e in all(es) do
      if _has(e, ks) then
        f(e)
      end
    end
  end
end

_curr_ent_id=0

_k_ent_flg_clear=0
_k_ent_flg_destroy=1

function entity(compos)
	_curr_ent_id+=1
	local ent=clone(compos)
	ent.id=_curr_ent_id
	ent.flags=0
	add(ents,ent)

	return ent
end

function ent_destroy(ent)
	ent_addflg(ent,_k_ent_flg_destroy)
end

function ent_flgs(...)
	local arg={...}
	local flg=0
	for a in all(arg) do
		flg=bor(flg,a)
	end
	return flg
end

function ent_addflg(ent,flg)
	ent.flags=bor(ent.flags,flg)
end

function ent_remflg(ent,flg)
	ent.flags=bxor(ent.flags,bnot(flg))
end

function ent_hasflg(ent,flg)
	return band(ent.flags,flg)~=0
end

function lerp(a, b, t)
	return a+(b-a)*t
end

function anglerp(a, b, t)
	local ax,ay=cos(a),sin(a)
	local bx,by=cos(b),sin(b)
	return atan2(lerp(ax, bx, t),
		lerp(ay, by, t))
end

-----------------------------------
-- table utilities --
-----------------------------------
-- clear array
function clra(arr)
	for i, _ in pairs(arr) do
		arr[i] = nil
	end
end

function cpya(arr, dst)
	if dst then
		clra(dst)
	else
		dst = {}
	end
	for i = 1, #arr do
		dst[i] = arr[i]
	end
	return dst
end

function idxof(arr, v)
	local n = #arr
	for i = 1, n do
		if arr[n] == v then
			return i
		end
	end
	return -1
end

function contains(arr, v)
	return idxof(arr, v) >= 0
end

-- fast add, no check
function fadd(t, v)
	t[#t+1] = v
end

-- fast del, swap in last element
-- instead of maintaining order
function delf(t, v)
	local n = #t
	for i = 1, n do
		if t[i] == v then
			t[i] = t[n]
			t[n] = nil
			return true
		end
	end
	return false
end

-- delete at index, maintain order
function idel(t, i)
	local n = #t
	if i > 0 and i <= n then
		for j = i, n - 1 do
			t[j] = t[j + 1]
		end
		t[n] = nil
		return true
	end
	return false
end

-- delete [s, e], maintain order
-- compress for space
function idelr(t, s, e)
	local n = #t
	e = min(n, e)
	local d = e - s + 1
	for i = s, e do
		t[i] = nil
	end
	for i = e + 1, n do
		t[i - d] = t[i]
		t[i] = nil
	end
end

-- delete at index, swap in last
-- element, loses ordering
function idelf(t, i)
	local n = #t
	if i > 0 and i <= n then
		t[i] = t[n]
		t[n] = nil
		return true
	end
	return false
end

-- fast deletion of an array of
-- indices
function idelfa(arr, idx)
	local l = #arr

	for i in all(idx) do
		arr[i] = nil
	end
	if (#idx == l) return
	for i = 1, l do
		if arr[i] == nil then
			while not arr[l]
				and l > i
			do
				l -= 1
			end
			if i ~= l then
				arr[i] = arr[l]
				arr[l] = nil
			else return end
		end
	end
end

function clone(from, to)
	from=from or {}
	to=to or {}
	return clone_helper(from,to,{})
end

function clone_helper(from,to,seen)
	seen=seen or {}

	if from==nil then
		return to
	elseif type(from)~="table" then
		return from
	elseif seen[from] then
		return seen[from]
	end

	seen[from]=to
	for k,v in pairs(from) do
		k=clone_helper({},k,seen)
		if to[k]==nil then
			to[k]=clone_helper({},v,seen)
		end
	end
	return to
end
-----------------------------------