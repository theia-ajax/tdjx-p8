pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.71828
::_::
cls()
for i=0,99 do
	u=t()/e/32
	a=i*1/e/1+u
	b=(i+.2)*1/e/1+u
	r=i*2/e+sin(a*20)*20
	q=(i+.2)*2/e+sin(b*20)*20
	x=cos(a)*r+64
	y=sin(a)*r+64
	w=cos(b)*q+64
	z=sin(b)*q+64
	pset(x,y,7)
	c=8+(15-i/30+t()*8)%8
	d=a/e/3
	circfill(x,y,d,c)
	circfill(x+d/3,y-d/3,d/2.2,7)
//	line(x,y,w,z,8+(15-i/30+t()*8)%8)
end
?"★ special stage ★",30+sin(t()/2)*20,60
flip()goto _
