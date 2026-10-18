// Generate a native diagnostic cartridge from the same source as the game.
const fs = require('node:fs');
const path = require('node:path');
const { readCartridge, buildDir } = require('./cartridge');
const source = readCartridge();
const diagnostic = `
-- Native QA only; excluded from the playable cartridge.
local base_init=_init
local base_draw=_draw
function _init()
 base_init() sound=false audio_state() panel=false
 test_zooms={1,5,6} test_scenes=0
 test_step=1 test_peak=0 test_done=false test_worst=0 test_count=0 test_ready=false
end
function _update()
 -- PICO-8 can run multiple updates before drawing after region setup.
 -- Advance only after a draw so none of the requested views are skipped.
 if test_done or test_ready then return end
 if test_step>960 then
  if region<#regions then region=region+1 world() panel=false test_step=1
  else test_done=true return end
 end
 local sample=flr((test_step-1)/48)
 local index=sample*6+1
 ca=((test_step-1)%8)/8 view=flr((test_step-1)/8)%2+1
 zoom_step=test_zooms[flr((test_step-1)/16)%3+1]
 if index<=96 then car.x=road[index].x car.z=road[index].z
 else car.x=(sample-17.5)*32 car.z=0 end
 car.a=ca car.h=elevation(car.x,car.z) cx=car.x cz=car.z ch=car.h
 speed=0.4 tick=(tick+1)%3600
 for i=1,15 do dust[i]={x=car.x+rnd(8)-4,z=car.z+rnd(8)-4,h=car.h,col=6,life=18,vx=0,vz=0} end
 for i=1,40 do marks[i]={x=car.x+rnd(70)-35,z=car.z+rnd(70)-35,h=car.h,a=ca} end
 drive(true,false,test_step%4==0,(test_step%3)-1)
 drive(true,false,test_step%4==0,(test_step%3)-1)
 camera_step()
 test_ready=true
end
function _draw()
 if test_done then
  cls(1)
  print("native sweep complete",5,30,7)
  print(test_scenes.." camera scenes",5,42,7)
  print("peak cpu: "..tostr(test_peak),5,54,7)
  print("worst: "..tostr(test_worst),5,66,7)
  print("over budget: "..tostr(test_count),5,78,7)
  return
 end
 if not test_ready then return end
 base_draw()
 test_scenes=test_scenes+1
 if test_step>1 then
  local cost=stat(1)
  if cost>test_peak then test_peak=cost test_worst=region*1000+test_step end
  if cost>1 then test_count=test_count+1 end
 end
 rectfill(0,111,127,127,1)
 print("test "..region..":"..test_step,2,113,7)
 print("peak "..tostr(test_peak),2,121,7)
 test_ready=false test_step=test_step+1
end
`;

const marker = '\n__gfx__\n';
if (!source.includes(marker)) throw new Error('Missing cartridge graphics section');
fs.mkdirSync(buildDir, { recursive: true });
fs.writeFileSync(path.join(buildDir, 'quiet_miles_sweep.p8'), source.replace(marker, diagnostic + marker));
console.log('Created build/quiet_miles_sweep.p8; load it in PICO-8 to measure native CPU use.');
