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

function point(x,z,h)
 local a,b,k,d=project(x,z,h or elevation(x,z)) return {a,b,k,d}
end
