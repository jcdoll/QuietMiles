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
