-- Deterministic model checks; native PICO-8 separately checks fixed point/CPU.
local out=print
abs=math.abs sqrt=math.sqrt flr=math.floor ceil=math.ceil
min=math.min max=math.max
function mid(a,b,c) return math.max(math.min(a,c),math.min(math.max(a,c),b)) end
function cos(a) return math.cos(a*math.pi*2) end
function sin(a) return -math.sin(a*math.pi*2) end
function atan2(x,z) return (-math.atan(z,x)/(math.pi*2))%1 end
function srand(n) math.randomseed(n) end
function rnd(n) return math.random()*(n or 1) end
function add(t,v) t[#t+1]=v return v end
function deli(t,i) return table.remove(t,i) end
function del(t,v) for i,x in ipairs(t) do if x==v then table.remove(t,i) return end end end
function all(t) local i=0 return function() i=i+1 return t[i] end end
function stat() return 0 end
function tostr(n) return tostring(n) end
function btn() return false end
function btnp() return false end
for _,f in ipairs({'sspr','memcpy','pal','poke','sfx','menuitem','print','pset','line','rectfill','circfill','ovalfill','cls'}) do _G[f]=function(...) for _,v in ipairs({...}) do if type(v)=='number' then assert(v==v and math.abs(v)<1e8,'invalid drawing coordinate') end end end end
-- Load the delivered cartridge, avoiding a second copy of the game source.
local cart=assert(io.open('quiet_miles.p8','rb'))
local text=cart:read('*a'):gsub('\r\n','\n')
cart:close()
local source=assert(text:match('__lua__\n(.-)\n__gfx__'),'missing cartridge sections')
assert(load(source,'@quiet_miles.p8'))()
_init()
local real_surface=surface_at
local real_elevation=elevation
local real_lake=lake
local material_id=1
surface_at=function() return material_id,0,1,0,0 end
lake=function() return false end
hills=false scenery={}
local function reset(id,vx,vz)
 material_id=id start_drive() car.x=0 car.z=0 car.a=0
 car.vx=vx or 0 car.vz=vz or 0
 car.mu=surfaces[id].force car.k=surfaces[id].k
end
local slides={} local stops={}
for _,id in ipairs({1,2,4}) do
 reset(id,0.45,0.16)
 local distance=0
 for i=1,45 do drive(false,false,false,0) distance=distance+abs(car.vz) end
 slides[id]=distance
 reset(id,0.5,0)
 local n=0
 repeat drive(false,true,false,0) n=n+1 until speed<0.03 or n>300
 stops[id]=n
 out(string.format('%s: lateral impulse travel %.3f, brake frames %d',surfaces[id].name,distance,n))
end
assert(slides[2]<slides[1] and slides[1]<slides[4], 'surface slip ordering')
assert(stops[2]<stops[1] and stops[1]<stops[4], 'surface braking ordering')
for _,id in ipairs({1,2,4}) do
 reset(id)
 for i=1,100 do drive(true,false,false,0) end
 assert(speed>0.2 and speed<0.8,'drive speed')
 assert(abs(car.a)<0.00001,'straight stability')
 local start=car.a local maxslip=0
 for i=1,45 do drive(true,false,false,1) maxslip=max(maxslip,abs(-car.vx*sin(car.a)+car.vz*cos(car.a))) end
 assert(wrap(car.a-start)<0,'right steering')
 out(string.format('%s: powered turn peak side speed %.3f, yaw %.3f',surfaces[id].name,maxslip,wrap(car.a-start)))
end
reset(1,0.4,0)
for i=1,35 do drive(true,false,true,1) end
assert(abs(-car.vx*sin(car.a)+car.vz*cos(car.a))>0.06,'handbrake slide')
reset(1)
for i=1,60 do drive(false,true,false,0) end
assert(car.vx<0,'reverse')
reset(1,0.4,0) material_id=2 drive(true,false,false,0)
assert(car.mu>surfaces[1].force and car.mu<surfaces[2].force,'smooth grip transition')
elevation=function(x,z) return x*0.2 end
reset(1,0.3,0) drive(true,false,false,0) local uphill=speed
reset(1,-0.3,0) car.a=0.5 drive(true,false,false,0) local downhill=speed
assert(downhill>uphill,'gravity along slopes')
assert(abs(car.h-elevation(car.x,car.z))<0.001,'car follows height')
assert(abs(car.pitch)>0.001,'car pitches')
surface_at=real_surface elevation=real_elevation lake=real_lake hills=true
local heightmin=100 local heightmax=-100
for r=1,2 do
 region=r world() panel=false
 for i=1,#road,3 do
  car.x=road[i].x car.z=road[i].z car.h=elevation(car.x,car.z)
  heightmin=min(heightmin,car.h) heightmax=max(heightmax,car.h)
  for v=1,2 do
   view=v
   for a=0,7 do
    tick=tick+1 ca=a/8 cx=car.x cz=car.z ch=car.h _draw()
   end
  end
 end
 car.x=150 car.z=150 recover()
 assert(nearest(car.x,car.z)<0.1,'recover')
 out('region '..r..': sampled road positions, both camera heights, eight yaw angles PASS')
end
assert(heightmax-heightmin>12,'meaningful hills')
hills=false assert(elevation(4,8)==0,'flat comparison')
out(string.format('terrain height range %.2f to %.2f',heightmin,heightmax))
out('PASS: surface grip/braking, steering, handbrake, reverse, slope gravity, body pitch, recovery, projection')
