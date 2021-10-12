pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
a=64
x={a,a,a,a,a,a}y={a,a,a,a,a,a}c=a
d=a
l=10
n=6::_::cls()c=a+48*cos(t()/3)d=a+48*sin(t()/2)for j=-1,1,2 do
if (j<0) s,f,x[n],y[n]=n-1,1,c,d
if (j>0) s,f,x[1],y[1]=2,n,a,a
for i=s,f,j do
h=x[i-j]k=y[i-j]
f=x[i]-h
e=y[i]-k
m=sqrt(f*f+e*e)
f=f/m*l
e=e/m*l
x[i]=h+f
y[i]=k+e
end
end
for i=2,n do
line(x[i-1],y[i-1],x[i],y[i],7)
end
circfill(x[n],y[n],8,5)
flip()goto _
