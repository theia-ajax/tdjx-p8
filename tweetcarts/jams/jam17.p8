pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls()
f=t()/10
for i=0,32 do
x=cos(f)
y=sin(f)
j=((i-16)*(12+sin(t())*6))
line(64-y*j+x*128,64+x*j+y*128,
	64-y*j-x*128,64+x*j-y*128)
line(64-x*j-y*128,64-y*j+x*128,
	64-x*j+y*128,64-y*j-x*128)

end
flip()goto _
