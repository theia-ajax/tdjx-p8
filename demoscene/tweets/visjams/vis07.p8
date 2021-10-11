pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cls()
function z(r,i) return r*r-i*i,2*r*i end	
a={}b={}
srand(1)
for i=1,10 do
	add(a,rnd(2)-1)add(b,rnd(2)-1)
end
::_::
srand(2)
cls()
for i=1,10 do
	c,d=z(a[i],b[i])
	if abs(c-a[i])>0.01 and
		abs(d-b[i])>0.01 then
		line(64+a[i]*64,64+b[i]*64,64,64,rnd(4)+12)
		a[i],b[i]=c,d
	else
		a[i]=rnd(2)-1
		b[i]=rnd(2)-1
	end	
end
flip()goto _
