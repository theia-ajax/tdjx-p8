pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
t=0
function _draw()
 cls()t+=2
 for c=1,8 do for i=1,28 do
   h=cos((t-i+c*2)/360)*.125+.75;x=cos(h)*i*6+63;y=sin(h)*i*6
	  circfill(x,y,2,(c%8)+7)
 end end
end
