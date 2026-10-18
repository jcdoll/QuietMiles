function start_drive()
 local p=road[1] local q=road[2]
 car={x=p.x,z=p.z,a=atan2(q.x-p.x,q.z-p.z),vx=0,vz=0,
  steer=0,yaw=0,omega=0,pitch=0,roll=0,h=elevation(p.x,p.z),mu=0.009,k=0.10}
 ca=car.a cx=car.x cz=car.z ch=car.h
 offroad=false speed=0 help_frames=300
 dust={} marks={} dist=0 current_surface=surface_at(car.x,car.z)
 car.mu=surfaces[current_surface].force car.k=surfaces[current_surface].k
end

function recover()
 local d,i,x,z=nearest(car.x,car.z)
 local p=road[i] local q=road[i%#road+1]
 car.x=x car.z=z car.a=atan2(q.x-p.x,q.z-p.z)
 car.vx=0 car.vz=0 car.yaw=0 car.omega=0 car.steer=0
 car.h=elevation(x,z) car.pitch=0 car.roll=0
 ca=car.a cx=x cz=z ch=car.h
 speed=0 dust={} marks={}
 current_surface=surface_at(x,z)
 car.mu=surfaces[current_surface].force car.k=surfaces[current_surface].k
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
  if p.solid and abs(dx)<2.3 and abs(dz)<2.3 then
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
