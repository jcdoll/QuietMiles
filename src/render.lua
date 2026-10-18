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
