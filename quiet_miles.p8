pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- quiet miles
-- a small, unhurried rally study

function _init()
 region=1 view=1 grip=1 road_mode=1 hills=true zoom_step=3
 sound=true panel=true row=1
 views={"rally low","high view"}
 regions={"pine lake","ochre hills"}
 grips={"rally","assisted"}
 road_modes={"mixed","dirt","pavement","snow test"}
 -- grip, lateral force, drive, brake, rolling drag
 surfaces={
  {name="dirt",k=0.10,force=0.009,drive=0.0085,brake=0.014,drag=0.007,col=6},
  {name="pavement",k=0.20,force=0.022,drive=0.010,brake=0.022,drag=0.004,col=5},
  {name="grass",k=0.065,force=0.006,drive=0.0065,brake=0.010,drag=0.024,col=3},
  {name="snow",k=0.038,force=0.0042,drive=0.0058,brake=0.007,drag=0.011,col=6}}
 tick=0 cpupeak=0
 make_sprites() make_audio() world()
 menuitem(1,"drive settings",function() panel=true end)
 menuitem(2,"return to road",function() recover() end)
 menuitem(3,"restart drive",function() start_drive() end)
end



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

function make_sprites()
 cls(0)
 -- cached upright scenery; native scaled blits are cheap
 tri(1,21,15,21,8,1,1)
 tri(8,2,15,21,9,21,11)
 tri(3,13,13,13,8,0,1)
 line(8,1,11,10,11) line(8,21,8,24,4)
 tri(20,12,34,12,26,3,5)
 tri(26,3,34,12,28,12,6)
 line(48,23,48,12,4)
 ovalfill(41,2,55,14,9)
 ovalfill(44,2,53,9,10)
 memcpy(0,0x6000,8192)
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

function start_drive()
 local p=road[1] local q=road[2]
 car={x=p.x,z=p.z,a=atan2(q.x-p.x,q.z-p.z),vx=0,vz=0,
  steer=0,yaw=0,omega=0,pitch=0,roll=0,h=elevation(p.x,p.z),mu=0.009,k=0.10}
 ca=car.a cx=car.x cz=car.z ch=car.h
 offroad=false speed=0 help_frames=300
 dust={} marks={} dist=0 current_surface=surface_at(car.x,car.z)
end

function recover()
 local d,i,x,z=nearest(car.x,car.z)
 local p=road[i] local q=road[i%#road+1]
 car.x=x car.z=z car.a=atan2(q.x-p.x,q.z-p.z)
 car.vx=0 car.vz=0 car.yaw=0 car.omega=0 car.steer=0
 car.h=elevation(x,z) car.pitch=0 car.roll=0
 ca=car.a cx=x cz=z ch=car.h
 speed=0 dust={} marks={}
end

function settings()
 if btnp(2) then row=(row-2)%9+1 end
 if btnp(3) then row=row%9+1 end
 local change=btnp(0) or btnp(1) or btnp(4)
 if change then
  if row==1 then panel=false end
  if row==2 then road_mode=road_mode%4+1 end
  if row==3 then hills=not hills make_terrain() recover() end
  if row==4 then view=3-view end
  if row==5 then
   if btnp(0) then zoom_step=max(1,zoom_step-1)
   elseif btnp(1) then zoom_step=min(6,zoom_step+1)
   else zoom_step=zoom_step%6+1 end
  end
  if row==6 then grip=3-grip end
  if row==7 then region=3-region world() end
  if row==8 then sound=not sound audio_state() end
  if row==9 then start_drive() panel=false end
 end
 if btnp(5) then panel=false end
end

function _update()
 if panel then
  tick=(tick+1)%3600 settings()
  return
 end
 -- PICO-8 presents at 30 fps; the car integrates twice at 60 Hz.
 physics_step() physics_step()
end

function physics_step()
 tick=(tick+1)%3600
 help_frames=max(0,help_frames-1)
 local throttle=btn(2) or btn(4)
 local brake=btn(3) local hand=btn(5)
 local steer=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 drive(throttle,brake,hand,steer)
 camera_step()
 for p in all(dust) do
  p.life=p.life-1 p.x=p.x+p.vx p.z=p.z+p.vz
  if p.life<=0 then del(dust,p) end
 end
 if tick%12==0 and sound then
  local note=12+flr(speed*27)
  for i=0,31 do poke(0x3200+i*2,note+192) end
 end
end

function drive(throttle,brake,hand,steer)
 local c=car
 local id,d,idx=surface_at(c.x,c.z)
 current_surface=id offroad=id==3
 local material=surfaces[id]
 -- Interpolate across surfaces, avoiding an abrupt grip snap.
 c.mu=c.mu+(material.force-c.mu)*0.12
 c.k=c.k+(material.k-c.k)*0.12
 local fx=cos(c.a) local fz=sin(c.a)
 local forward=c.vx*fx+c.vz*fz
 local lateral=-c.vx*fz+c.vz*fx
 c.steer=c.steer+(steer-c.steer)*0.16
 local wheel=c.steer*0.46/(1+abs(forward)*1.0)
 local front_cap=c.mu local rear_cap=c.mu*1.06
 if throttle then rear_cap=rear_cap*(id==2 and 0.94 or 0.66) end
 if brake then front_cap=front_cap*0.92 rear_cap=rear_cap*0.84 end
 if hand then rear_cap=rear_cap*0.10 end
 if grip==2 then rear_cap=rear_cap*1.3 end
 local front=mid(-front_cap,(forward*wheel-lateral-c.omega*1.65)*c.k,front_cap)
 local rear=mid(-rear_cap,(-lateral+c.omega*1.45)*c.k,rear_cap)
 lateral=lateral+front+rear
 c.omega=(c.omega+(front*1.65-rear*1.45)/4.2)*0.97
 if abs(forward)<0.025 then c.omega=c.omega*0.8 end
 c.yaw=c.omega/6.2832
 c.a=(c.a-c.yaw)%1
 if throttle then forward=forward+material.drive end
 if brake then
  if forward>0.025 then forward=max(0,forward-material.brake)
  else forward=max(-0.13,forward-material.drive*0.45) end
 end
 if hand then forward=forward*0.985 end
 forward=forward*(1-material.drag-abs(forward)*0.024)
 c.vx=fx*forward-fz*lateral c.vz=fz*forward+fx*lateral
 local gx=(elevation(c.x+2,c.z)-elevation(c.x-2,c.z))/4
 local gz=(elevation(c.x,c.z+2)-elevation(c.x,c.z-2))/4
 c.vx=c.vx-gx*0.0035 c.vz=c.vz-gz*0.0035
 -- Static friction permits a peaceful stop on a slope.
 if not throttle and not brake and length(c.vx,c.vz)<0.025 then c.vx=0 c.vz=0 c.omega=c.omega*0.8 end
 speed=length(c.vx,c.vz)
 c.x=mid(-166,c.x+c.vx,166) c.z=mid(-166,c.z+c.vz,166)
 if lake(c.x,c.z) then c.x=c.x-c.vx c.z=c.z-c.vz c.vx=c.vx*0.7 c.vz=c.vz*0.7 end
 for p in all(scenery) do
  local dx=c.x-p.x local dz=c.z-p.z
  if abs(dx)<2.3 and abs(dz)<2.3 then
   local len=length(dx,dz)
   if len<2.3 then
    len=max(0.01,len)
    c.x=p.x+dx/len*2.3 c.z=p.z+dz/len*2.3
    c.vx=c.vx*0.8 c.vz=c.vz*0.8
   end
  end
 end
 c.h=elevation(c.x,c.z)
 local pitch=gx*fx+gz*fz local roll=-gx*fz+gz*fx
 c.pitch=c.pitch+(pitch-c.pitch)*0.12
 c.roll=c.roll+(roll-c.roll)*0.12
 if speed>0.12 and tick%5==0 then
  if id~=2 then
   if #dust>=15 then deli(dust,1) end
   add(dust,{x=c.x-fx*2,z=c.z-fz*2,h=c.h+0.3,col=material.col,
    vx=-c.vx*0.1+rnd(0.05)-0.025,vz=-c.vz*0.1+rnd(0.05)-0.025,life=24+rnd(12)})
  end
  if abs(lateral)>0.06 or hand then
   if #marks>=40 then deli(marks,1) end
   add(marks,{x=c.x-fx*2,z=c.z-fz*2,h=c.h+0.1,a=c.a})
  end
 end
end

function camera_step()
 local target=ca
 if speed>0.05 then
  local travel=atan2(car.vx,car.vz)
  target=travel+wrap(car.a-travel)*0.15
 end
 local delta=wrap(target-ca)
 if abs(delta)>0.008 then ca=(ca+mid(-0.003,delta*0.04,0.003))%1 end
 cx=cx+(car.x-cx)*0.18 cz=cz+(car.z-cz)*0.18
 local future=elevation(car.x+cos(ca)*12,car.z+sin(ca)*12)
 ch=ch+((car.h*0.85+future*0.15)-ch)*0.065
end

function project(x,z,h)
 local dx=x-cx local dz=z-cz
 local along=dx*cc+dz*cs+back
 local up=(h or 0)-ch-eye_height
 local depth=along*cp-up*sp
 if depth<12 then return -1000,-1000,0,depth end
 local scale=focal/depth
 return 64+(-cs*dx+cc*dz)*scale,screen_y-(along*sp+up*cp)*scale,scale,depth
end

function project_vertex(p)
 if p.frame~=tick then
  local a=p.projected
  a[1],a[2],a[3],a[4]=project(p.x,p.z,p.h)
  p.frame=tick
 end
 return p.projected
end

function in_view(x,z,r)
 local dx=x-cx local dz=z-cz
 local along=dx*cc+dz*cs
 return along> -46-r and along<180+r and abs(-cs*dx+cc*dz)<60+along*0.45+r
end

function enqueue(kind,p,depth)
 local i=mid(1,flr(depth/10),32)
 add(buckets[i][kind],p)
end

function tri(x1,y1,x2,y2,x3,y3,col)
 if max(x1,max(x2,x3))<0 or min(x1,min(x2,x3))>127 or
  max(y1,max(y2,y3))<0 or min(y1,min(y2,y3))>127 then return end
 if y1>y2 then x1,x2=x2,x1 y1,y2=y2,y1 end
 if y2>y3 then x2,x3=x3,x2 y2,y3=y3,y2 end
 if y1>y2 then x1,x2=x2,x1 y1,y2=y2,y1 end
 if y3-y1<0.01 then return end
 local slope=(x3-x1)/(y3-y1)
 local top=(x2-x1)/max(0.01,y2-y1)
 local bot=(x3-x2)/max(0.01,y3-y2)
 local y=max(0,ceil(y1)) local endy=min(127,ceil(y2)-1)
 local a=x1+(y-y1)*slope local b=x1+(y-y1)*top
 for row=y,endy do
  rectfill(a,row,b,row,col) a=a+slope b=b+top
 end
 y=max(0,ceil(y2)) endy=min(127,flr(y3))
 a=x1+(y-y1)*slope b=x2+(y-y2)*bot
 for row=y,endy do
  rectfill(a,row,b,row,col) a=a+slope b=b+bot
 end
end

function quad(a,b,c,d,col)
 if a[4] and (a[4]<12 or b[4]<12 or c[4]<12 or d[4]<12) then return end
 tri(a[1],a[2],b[1],b[2],c[1],c[2],col)
 tri(a[1],a[2],c[1],c[2],d[1],d[2],col)
end

function point(x,z,h)
 local a,b,k,d=project(x,z,h or elevation(x,z)) return {a,b,k,d}
end

function draw_road(i)
 local p=road[i] local q=road[i%#road+1]
 local a=project_vertex(p.left) local b=project_vertex(q.left)
 local c=project_vertex(q.right) local d=project_vertex(p.right)
 if min(a[1],min(b[1],min(c[1],d[1])))>127 or max(a[1],max(b[1],max(c[1],d[1])))<0 or
  min(a[2],min(b[2],min(c[2],d[2])))>127 or max(a[2],max(b[2],max(c[2],d[2])))<0 then return end
 local id=surface_id(i)
 quad(a,b,c,d,surfaces[id].col)
 if a[4]>12 and b[4]>12 and c[4]>12 and d[4]>12 then
  line(a[1],a[2],b[1],b[2],id==2 and 6 or 4)
  line(c[1],c[2],d[1],d[2],id==2 and 6 or 4)
  if id==2 and i%2==0 then
   local x,y=project(p.x,p.z,p.h+0.1)
   local u,v=project((p.x+q.x)/2,(p.z+q.z)/2,(p.h+q.h)/2+0.1)
   line(x,y,u,v,6)
  end
 end
end

function ground()
 cls(13)
 rectfill(0,31,127,127,land)
 buckets={}
 for i=1,32 do buckets[i]={{},{},{},{}} end
 for t in all(terrain) do
  if in_view(t.x,t.z,30) then
   local a=project_vertex(t[1]) local b=project_vertex(t[2])
   local c=project_vertex(t[3]) local d=project_vertex(t[4])
   local col=t.col
   if road_mode==4 then col=col==land and 7 or 6 end
   enqueue(1,{a,b,c,d,col=col},(a[4]+b[4]+c[4]+d[4])/4)
  end
 end
 for i=1,#road do
  local p=road[i] local q=road[i%#road+1]
  if in_view((p.x+q.x)/2,(p.z+q.z)/2,10) then
   local _,_,_,depth=project((p.x+q.x)/2,(p.z+q.z)/2,(p.h+q.h)/2)
   enqueue(2,{i=i},depth)
  end
 end
 -- The dirt spur remains part of the same surface query.
 for p in all(road_dots) do
  if p.w<1 and in_view(p.x,p.z,5) then
   local x,y,k,d=project(p.x,p.z,elevation(p.x,p.z)+0.1)
   enqueue(2,{x=x,y=y,k=k,w=p.w},d)
  end
 end
 for p in all(marks) do
  if in_view(p.x,p.z,2) then
   local x,y,k,d=project(p.x,p.z,p.h)
   enqueue(3,{x=x,y=y,col=4},d)
  end
 end
 local carx,cary,cark,card=project(car.x,car.z,car.h)
 enqueue(4,{car=true,depth=card},card)
 for p in all(scenery) do
  if in_view(p.x,p.z,8) then
   local x,y,k,d=project(p.x,p.z,p.ground)
   if k>0 and x>-16 and x<144 and y>-5 and y<151 then
    enqueue(4,{x=x,y=y,k=k,p=p,depth=d},d)
   end
  end
 end
 for p in all(dust) do
  local x,y,k,d=project(p.x,p.z,p.h)
  enqueue(3,{x=x,y=y,col=p.col},d)
 end
 -- Terrain first: roads conform to the same height field.
 for i=32,1,-1 do
  for t in all(buckets[i][1]) do quad(t[1],t[2],t[3],t[4],t.col) end
 end
 if region==1 then
  local middle=point(-12,-3,0.3)
  local previous=point(28,-3,0.3)
  for j=1,24 do
   local next=point(-12+40*cos(j/24),-3+51*sin(j/24),0.3)
   tri(middle[1],middle[2],previous[1],previous[2],next[1],next[2],water)
   previous=next
  end
 end
 for i=32,1,-1 do
  local bucket=buckets[i]
  for r in all(bucket[2]) do
   if r.i then draw_road(r.i)
   else
    local w=r.k*4
    ovalfill(r.x-w,r.y-w*sp,r.x+w,r.y+w*sp,road_mode==4 and 7 or 6)
   end
  end
  for p in all(bucket[3]) do pset(p.x,p.y,p.col) end
  -- Small depth buckets keep foliage and car ordering inexpensive.
  local order=bucket[4]
  for j=2,#order do
   local item=order[j] local k=j
   while k>1 and order[k-1].depth<item.depth do order[k]=order[k-1] k=k-1 end
   order[k]=item
  end
  for o in all(order) do
   if o.car then draw_car()
   elseif abs(o.x-carx)>7 or abs(o.y-cary)>18 then draw_tree(o.p,o.x,o.y,o.k) end
  end
 end
end

function carpoint(f,r,h)
 local fx=cos(car.a) local fz=sin(car.a)
 return point(car.x+fx*f-fz*r,car.z+fz*f+fx*r,
  car.h+(h or 0)+f*car.pitch+r*car.roll)
end

function draw_car()
 local x,y=project(car.x,car.z,car.h)
 ovalfill(x-4,y-2,x+5,y+3,edge)
 for f=-1.5,1.5,3 do
  for r=-1.5,1.5,3 do
   local p=carpoint(f,r,0.4)
   circfill(p[1],p[2],1,0)
  end
 end
 local a=carpoint(2.6,-1.35,1)
 local b=carpoint(2.6,1.35,1)
 local c=carpoint(-2.4,1.35,1)
 local d=carpoint(-2.4,-1.35,1)
 quad({d[1],d[2]+2},{c[1],c[2]+2},c,d,8)
 quad({a[1],a[2]+2},{b[1],b[2]+2},b,a,8)
 quad(a,b,c,d,14)
 quad(carpoint(1.3,-1.1,1.6),carpoint(1.3,1.1,1.6),
  carpoint(-1.5,1.1,1.6),carpoint(-1.5,-1.1,1.6),7)
 quad(carpoint(1.4,-1.05,1.65),carpoint(1.4,1.05,1.65),
  carpoint(0.7,1.05,1.65),carpoint(0.7,-1.05,1.65),1)
 local l=carpoint(2.6,-0.85,1.1) local r=carpoint(2.6,0.85,1.1)
 pset(l[1],l[2],10) pset(r[1],r[2],10)
end

function draw_tree(p,x,y,k)
 local h=p.h*k*cp local w=p.r*k
 ovalfill(x-w,y-1,x+w+2,y+1,1)
 if region==1 then
  sspr(0,0,16,25,x-w,y-h,w*2,h)
 elseif p.k<2 then
  sspr(40,0,16,24,x-w,y-h,w*2,h)
 else sspr(20,0,16,13,x-w,y-h*0.45,w*2,h*0.45) end
end





function center(s,y,c)
 print(s,64-#s*2,y,c)
end

function _draw()
 pal(3,131,1) pal(11,3,1) pal(6,134,1)
 if road_mode==4 then pal(6,6,1) end
 cc=cos(ca) cs=sin(ca)
 back=90 eye_height=60 sp=0.46 cp=0.8879 focal=125
 if view==2 then back=65 eye_height=85 sp=0.72 cp=0.694 focal=125 end
 focal=focal*(1+(zoom_step-1)*0.1)
 -- Keep the car near the same screen height as the lens changes.
 screen_y=78+(back*sp-eye_height*cp)*focal/(back*cp+eye_height*sp)
 ground()
 if not panel then
  print(regions[region],4,4,7)
  print(surfaces[current_surface].name,4,11,6)
  if help_frames>0 then print("z go x slide p settings",4,118,7) end
 end
 if panel and row==5 then
  rectfill(7,99,120,126,1)
  center("zoom: < "..tostr(90+zoom_step*10).."% >",103,7)
  center("l/r adjust x drive",111,6)
  center("up/down settings",119,6)
 elseif panel then
  rectfill(7,14,120,113,1)
  center("quiet miles",20,7)
  center("camera + handling",29,6)
  local items={"drive","road: "..road_modes[road_mode],
   "hills: "..(hills and "rolling" or "flat"),"view: "..views[view],
   "zoom: "..tostr(90+zoom_step*10).."%",
   "feel: "..grips[grip],"place: "..regions[region],
   "sound: "..(sound and "on" or "off"),"restart drive"}
  for i=1,9 do
   local y=36+i*8
   if row==i then rectfill(11,y-1,116,y+5,5) end
   print(items[i],16,y,row==i and 7 or 6)
  end
  center("z choose x drive",119,7)
 end
 cpupeak=max(cpupeak,stat(1))
end

function make_audio()
 -- original, very quiet triangle notes; no sampled assets
 for s=0,2 do
  local base=0x3200+s*68
  for i=0,31 do
   local pitch=12 local wave=3 local vol=1
   if s>0 then
    local notes={24,31,36,40,43,40,36,31}
    pitch=notes[flr(i/4)%8+1]+(s-1)*7
    wave=0 vol=1
    if i%4~=0 then vol=0 end
   end
   poke(base+i*2,pitch+wave*64)
   poke(base+i*2+1,vol*2)
  end
  poke(base+64,0) poke(base+65,s==0 and 5 or 36)
  poke(base+66,0) poke(base+67,32)
 end
 audio_state()
end

function audio_state()
 sfx(-1)
 if sound then sfx(0,0) sfx(1,1) sfx(2,2) end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
