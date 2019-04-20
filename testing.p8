pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
harness={}
function harness:new()
	self.__index=self
	local o={}
	o.tests={}
	return setmetatable(o,self)
end

function harness:add_test(name,test_fn)
	add(self.tests,{fn=test_fn,name=name})
end

function harness:run_tests()
	test.harness=self
	test.failure=false
	for t in all(self.tests) do
		test.id=1
		t.fn()
		if test.failure then
			color(8)
			print(t.name.." #"..test.index..": "..test.failure.expected.."\n fail: "..test.failure.result)
			test.failure=nil
		else
			color(11)
			print(t.name..": pass")
		end
	end
end

test={}

function test:fail(result,expected)
	if not test.failure then
		test.failure={result=result or "",expected=expected or ""}
		test.index=test.id
	end
end

function test:pass()
	test.id+=1
end

function teststr(lhs,rhs,op)
	lhs=lhs or "nil"
	rhs=rhs or "nil"
	if (type(lhs)=="table") lhs="{}"
	if (type(rhs)=="table") rhs="{}"
	return tostr(lhs)..op..tostr(rhs)
end

function test.equal(a,b)
	if a==b then
		test:pass()
	else
		test:fail(teststr(a,b,"=="),"a==b")
	end
end

function test.not_equal(a,b)
	if a~=b then
		test:pass()
	else
		test:fail(teststr(a,b,"~="),"a~=b")
	end
end

function test.is_not_nil(a)
	if a then
		test:pass()
	else
		test:fail("a==nil","a~=nil")
	end
--	return test.not_equal(a,nil)
end

function test.is_nil(a)
	if not a then
		test:pass()
	else
		test:fail(teststr("a",tostr(a),"=="),"a==nil")
	end
end

function test.is_true(a)
	if type(a)=="function" then
		a=a()
	end
	if a then
		test:pass()
	else
		test:fail("a==false","a==true")
	end
end


function test.is_false(a)
	if type(a)=="function" then
		a=a()
	end
	if not a then
		test:pass()
	else
		test:fail("a==true","a==false")
	end
end

function test_ex()
	local a=0
	local b=1
	
	test.equal(1,1)
	test.equal(2,2)
end

function test_ex2()
	test.equal(1,2)
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
