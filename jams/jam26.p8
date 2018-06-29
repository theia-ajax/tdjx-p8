pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls(12)
srand()
for x=0,127 do
if rnd(100)<15 then
	y=rnd(128)
	r=8+sin(t())*4
	circfill(x-r/2,y,r,6)
	circfill(x,y,r,7)
end
end
flip()goto _
