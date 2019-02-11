pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- xorshift16 sort of
function rgen(seed,ct)
	seed=seed or 1
	ct=ct or 0
	local ret={
		seed=seed,
		sx=seed,
		count=0,
		_next=function(self)
			self.count+=1
			self.sx=bxor(self.sx,shl(self.sx,7))
			self.sx=bxor(self.sx,shr(self.sx,9))
			self.sx=bxor(self.sx,shl(self.sx,8))
			return self.sx
		end,
		next=function(self,mn,mx)
			if not mn then
			 mn,mx=0,1
			elseif not mx then
				mx,mn=mn,0
			elseif mx<mn then
				mn,mx=mx,mn
			end
			
			local f=(self:_next()/32767+1)/2
			return f*(mx-mn)+mn
		end,
		reset=function(self,ct)
			self.state=self.seed
			self.count=0
			for i=1,ct do
				self:next()
			end
		end,
		clone=function(self)
			return rgen(self.seed,self.count)
		end
	}
	for i=1,ct do ret:next() end
	return ret
end

function wait_key()
	while not stat(30) do end
	return stat(31)
end
		
local r,r2=rgen(1),rgen(1,5)
local r3=r2:clone()
poke(0x5f2d,1)
local quit=false
cls()
while not quit do
	local key=wait_key()
	if key=="q" then
		quit=true
	end
	
	print(tostr(r:next(),true))
	print(tostr(r2:next(),true))
	print(tostr(r3:next(),true))
	print("--------")
--	print(r:next(5))
--	print(r:next(5,10))
end
