pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
l=line
p=fillp
m=127n=96
::_::u=t()cls(0)p(shl(0x000f,flr(u%4)*4))circfill(64,64,48,0x09)p(0)rectfill(0,n,m,m,0)l(0,n,m,n,12)h=n+(m-n)*(u%1)j=n+(m-n)*((u+.5)%1)l(0,h,m,h,12)l(0,j,m,j,12)for i=0,m,16 do
l(i,n,i+(-64+i)*1.5,m,12)end
flip()goto _
