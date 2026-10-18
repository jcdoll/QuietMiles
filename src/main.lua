function _init()
 region=1 view=1 grip=1 road_mode=1 hills=true zoom_step=5
 sound=true panel=true row=1
 views={"rally low","high view"}
 make_regions()
 grips={"rally","assisted"}
 road_modes={"regional","dirt","pavement","snow","mud"}
 road_overrides={0,1,2,4,5}
 -- grip, lateral force, drive, brake, rolling drag
 surfaces={
  {name="dirt",k=0.10,force=0.009,drive=0.0085,brake=0.014,drag=0.007,col=6,edge=4},
  {name="pavement",k=0.20,force=0.022,drive=0.010,brake=0.022,drag=0.004,col=5,edge=6},
  {name="grass",k=0.065,force=0.006,drive=0.0065,brake=0.010,drag=0.024,col=3,edge=3},
  {name="snow",k=0.038,force=0.0042,drive=0.0058,brake=0.007,drag=0.011,col=6,edge=13},
  {name="mud",k=0.060,force=0.0054,drive=0.0095,brake=0.011,drag=0.025,col=4,edge=5}}
 tick=0 cpupeak=0
 make_sprites() make_audio() world()
 menuitem(1,"drive settings",function() panel=true end)
 menuitem(2,"return to road",function() recover() end)
 menuitem(3,"restart drive",function() start_drive() end)
end

function settings()
 if btnp(2) then row=(row-2)%9+1 end
 if btnp(3) then row=row%9+1 end
 local change=btnp(0) or btnp(1) or btnp(4)
 if change then
  if row==1 then panel=false end
  if row==2 then road_mode=road_mode%#road_modes+1 end
  if row==3 then hills=not hills make_terrain() recover() end
  if row==4 then view=3-view end
  if row==5 then
   if btnp(0) then zoom_step=max(1,zoom_step-1)
   elseif btnp(1) then zoom_step=min(6,zoom_step+1)
   else zoom_step=zoom_step%6+1 end
  end
  if row==6 then grip=3-grip end
  if row==7 then region=region%#regions+1 world() end
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

function center(s,y,c)
 print(s,64-#s*2,y,c)
end

function _draw()
 pal(3,131,1) pal(4,4,1) pal(11,3,1) pal(6,134,1)
 if area.style==2 then pal(6,6,1) end
 if area.style==3 then pal(3,3,1) pal(4,128,1) end
 cc=cos(ca) cs=sin(ca)
 back=90 eye_height=60 sp=0.46 cp=0.8879 focal=125
 if view==2 then back=65 eye_height=85 sp=0.72 cp=0.694 focal=125 end
 focal=focal*(1+(zoom_step-1)*0.1)
 -- Keep the car near the same screen height as the lens changes.
 screen_y=78+(back*sp-eye_height*cp)*focal/(back*cp+eye_height*sp)
 ground()
 if not panel then
  print(area.name,4,4,area.style==2 and 1 or 7)
  print(surfaces[current_surface].name,4,11,area.style==2 and 5 or 6)
  if help_frames>0 then print("z go x slide p settings",4,118,area.style==2 and 1 or 7) end
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
   "feel: "..grips[grip],"place: "..area.name,
   "sound: "..(sound and "on" or "off"),"restart drive"}
  for i=1,9 do
   local y=36+i*8
   if row==i then rectfill(11,y-1,116,y+5,5) end
   print(items[i],16,y,row==i and 7 or 6)
  end
  center("z choose x drive",119,area.style==2 and 1 or 7)
 end
 cpupeak=max(cpupeak,stat(1))
end
