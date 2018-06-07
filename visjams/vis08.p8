pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
d={0,0,0,0,0,0,0,0,1,1,1,2,2}::_::srand()cls()for i=1,300 do
s=d[flr(rnd(#d))+1]r=rnd((s+1)*30)f=rnd(1)+t()/(r*r)*25
x=64+r*cos(f)y=64+r*sin(f)circfill(x,y,(sin(t()+rnd())+1),7)
end
flip()goto _
