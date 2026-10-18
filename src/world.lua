function wrap(a)
 return (a+0.5)%1-0.5
end

function length(x,z)
 -- scale before squaring: pico-8 is 16.16 fixed point
 x=x/8 z=z/8
 return sqrt(x*x+z*z)*8
end

function curve(a,b,c,d,t)
 -- hermite interpolation avoids large intermediate products
 local u=t*t local v=u*t
 return (2*v-3*u+1)*b+(v-2*u+t)*(c-a)/2+
  (-2*v+3*u)*c+(v-u)*(d-b)/2
end

function elevation(x,z)
 if not hills then return 0 end
 local h=13+7*cos(x/240+z/390)+6*sin(z/210)+4*cos((x-z)/155)
 if region==1 then
  local a=(x+12)/40 local b=(z+3)/51
  h=h*mid(0,(sqrt(a*a+b*b)-0.95)*0.75,1)
 end
 return h
end

function surface_id(index)
 if road_mode>1 then
  if road_mode==4 then return 4 end
  return road_mode-1
 end
 return flr((index-1)/24)%2+1
end

function surface_at(x,z)
 local d,i,bx,bz,spurroad=road_distance(x,z)
 local id=surface_id(i)
 if spurroad then id=road_mode==4 and 4 or 1 end
 if d>5.7 then id=road_mode==4 and 4 or 3 end
 return id,d,i,bx,bz
end

function vertex(x,z)
 return {x=x,z=z,h=elevation(x,z),projected={0,0,0,0}}
end

function make_terrain()
 terrain={} grid={}
 for iz=0,12 do
  grid[iz+1]={}
  for ix=0,12 do grid[iz+1][ix+1]=vertex(-240+ix*40,-240+iz*40) end
 end
 for iz=1,12 do
  for ix=1,12 do
   local a=grid[iz][ix] local b=grid[iz][ix+1]
   local c=grid[iz+1][ix+1] local d=grid[iz+1][ix]
   local shade=(b.h-a.h+c.h-d.h)/80
   local col=land
   if shade>0.07 then col=light end
   add(terrain,{a,b,c,d,x=(a.x+c.x)/2,z=(a.z+c.z)/2,col=col})
  end
 end
 for i=1,#road do
  local p=road[i] local prev=road[(i-2)%#road+1]
  local nx=p.nx+prev.nx local nz=p.nz+prev.nz
  local n=length(nx,nz) nx=nx/n nz=nz/n
  p.left=vertex(p.x+nx*5.7,p.z+nz*5.7)
  p.right=vertex(p.x-nx*5.7,p.z-nz*5.7)
  p.h=elevation(p.x,p.z)
 end
 for p in all(scenery) do p.ground=elevation(p.x,p.z) end
end

function world()
 srand(region*71)
 road={} scenery={} dust={} marks={}
 local anchors
 if region==1 then
  anchors={{-93,65},{-114,22},{-98,-35},{-61,-77},
   {-5,-91},{48,-73},{98,-38},{111,17},
   {82,65},{35,59},{-4,85},{-54,93}}
  land=3 light=11 edge=4 gravel=6 water=1
 else
  anchors={{-95,64},{-118,4},{-84,-49},{-33,-58},
   {-5,-101},{55,-89},{98,-42},{78,7},
   {110,58},{59,87},{9,69},{-48,91}}
  land=4 light=9 edge=5 gravel=6 water=13
 end
 local n=#anchors
 for i=1,n do
  local a=anchors[(i-2)%n+1]
  local b=anchors[i]
  local c=anchors[i%n+1]
  local d=anchors[(i+1)%n+1]
  for j=0,7 do
   local t=j/8
   add(road,{x=curve(a[1],b[1],c[1],d[1],t),
    z=curve(a[2],b[2],c[2],d[2],t)})
  end
 end
 for i=1,#road do local p=road[i]
  local q=road[i%#road+1]
  local dx=q.x-p.x local dz=q.z-p.z
  local len=length(dx,dz)
  p.nx=-dz/len p.nz=dx/len
 end
 -- one road network; a spur reaches a quiet lookout
 spur={{x=road[49].x,z=road[49].z},
  {x=66,z=-28},{x=44,z=-11},{x=28,z=0}}
 road_dots={}

 for i=1,#spur-1 do sample_road(spur[i],spur[i+1],0.7) end
 for i=1,235 do
  local x=rnd(290)-145 local z=rnd(290)-145
  local dist=road_distance(x,z)
  if dist>10 and not lake(x,z) then
   add(scenery,{x=x,z=z,h=6+rnd(7),k=flr(rnd(5)),r=2+rnd(3)})
  end
 end
 make_terrain()
 start_drive()
end

function sample_road(p,q,w)
 local dx=q.x-p.x local dz=q.z-p.z
 local n=ceil(length(dx,dz)/2.5)
 for i=0,n-1 do
  add(road_dots,{x=p.x+dx*i/n,z=p.z+dz*i/n,w=w})
 end
end

function lake(x,z)
 return region==1 and ((x+12)/40)^2+((z+3)/51)^2<1
end

function nearest(x,z)
 local best=300 local index=1 local bx=0 local bz=0
 for i=1,#road do local p=road[i]
  local q=road[i%#road+1]
  -- early reject prevents fixed-point overflow
  if abs(p.x-x)<best+10 and abs(p.z-z)<best+10 then
   local dx=q.x-p.x local dz=q.z-p.z
   local t=mid(0,((x-p.x)*dx+(z-p.z)*dz)/(dx*dx+dz*dz),1)
   local px=p.x+dx*t local pz=p.z+dz*t
   local dist=length(x-px,z-pz)
   if dist<best then best=dist index=i bx=px bz=pz end
  end
 end
 return best,index,bx,bz
end

function road_distance(x,z)
 local dist,idx,bx,bz=nearest(x,z)
 local is_spur=false
 for i=1,#spur-1 do
  local p=spur[i] local q=spur[i+1]
  local dx=q.x-p.x local dz=q.z-p.z
  local t=mid(0,((x-p.x)*dx+(z-p.z)*dz)/(dx*dx+dz*dz),1)
  local d=length(x-p.x-dx*t,z-p.z-dz*t)/0.7
  if d<dist then dist=d is_spur=true end
 end
 return dist,idx,bx,bz,is_spur
end
