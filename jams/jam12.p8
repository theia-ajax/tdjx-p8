pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls()
srand()
for i=90,0,-1 do
	r=flr(rnd(5))/5+0.1
	f=(t()*10+i*.1)%16
	x=cos(r)*f
	y=sin(r)*f+(f*.4)*(f*.4)
	circfill(x+64,y+64,4-r/4,11-f/12)
end
flip()goto _
