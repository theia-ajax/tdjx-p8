pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
t=0;function _draw()cls()t+=2for c=1,8 do for i=1,28 do a=cos((t-i+c*2)/360)/8+.75;circfill(cos(a)*i*6+63,sin(a)*i*6,2,(c%8)+7)end;end;end
