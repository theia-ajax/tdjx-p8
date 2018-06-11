pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls()
for j=1,5
for i=0,j*10 do
f=(t()/4+i/(j*10))%1
y=127*min(f*2,1)
x=127*max(f*2-1,0)
rect(x,x,y,y,8+(i%7))
end
end

flip()goto _
