-- spread
--
-- string quartet
-- v0.3 entropybound

mxsamples=include("mx.samples/lib/mx.samples")
engine.name="MxSamples"
skeys=mxsamples:new()

MusicUtil = require "musicutil"
math.randomseed(os.time())

g = grid.connect()

instruments = {"alto sax choir","ghost piano","ash harmonium","india ashberry dry","tatak piano","glockenspiel","bedroom clarinet sustained","gentle vibes","cello","sweep bassoon","sweep celli","sweep clarinet","sweep euphonium","sweep flute","sweep horns","sweep oboe","sweep trombone","sweep trumpet","sweep violins","string spurs","string spurs swells","steinway model b","kawai felt","strat 62","telecaster","epiphone guitar","fender strato vib","steel string","trembling radiator"}

voice = {0,0,0,0}
--scale = {2,2,1,2,2,2,1} -- major
scale = {2,2,2,1,2,1,2} -- jazzy
notes = {}
root = 24 -- C1 for now
status = {0,0,0,0} -- voice on or off
note_shift = {0,0,0,0}
active_note = {0,0,0,0}
insts = {1,1,1,1}
attacks = {0,0,0,0}
positions = {8,8,8,8} -- within 15 position array, 8 is "zero"
velocities = {80,80,80,80}

p = {0,0,0}

probs={
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  }

-- p[1] = prob to step down
-- p[2] = prob to stay put
-- p[3] = prob to step up

function note_index(v)
  return (params:get("oct_"..v)-1)*7+params:get("note_"..v)
end

function evolve(n)

  while status[n] do
    if (active_note[n]==-1) then
      active_note[n] = notes[note_index(n)+(positions[n]-8)]
      -- print("starting note ",n, "=", active_note[n])
      skeys:on({name=instruments[insts[n]],midi=active_note[n],velocity=2})
      skeys:on({name=instruments[insts[n]],midi=active_note[n],velocity=velocities[n]+(math.random()-0.5)*10,attack=attacks[n]})
    else
      p[2] = probs[n][positions[n]]
      p[3] = 0
      if (positions[n]<15) then
        p[3] = probs[n][positions[n]+1]
      end

      p[1] = 0
      if (positions[n]>1) then
        p[1] = probs[n][positions[n]-1]
      end
  
      total = p[1]+p[2]+p[3]
      for i=1,3 do
        p[i] = p[i] / total
      end
  
      r = math.random()
      if (r<p[1]) then -- step down
        skeys:off({name=instruments[insts[n]],midi=active_note[n]})
        positions[n] = positions[n] - 1 
        active_note[n] = notes[note_index(n)+(positions[n]-8)]
        skeys:on({name=instruments[insts[n]],midi=active_note[n],velocity=velocities[n]+(math.random()-0.5)*10,attack=attacks[n]})
        grid_dirty = true
      end
      if (r>p[1]+p[2]) then 
        skeys:off({name=instruments[insts[n]],midi=active_note[n]})
        positions[n] = positions[n] + 1 
        active_note[n] = notes[note_index(n)+(positions[n]-8)]
        skeys:on({name=instruments[insts[n]],midi=active_note[n],velocity=velocities[n]+(math.random()-0.5)*10,attack=attacks[n]})
        grid_dirty = true
      end
    end 
  
    clock.sync(4./params:get("rate_"..n))
  end
end

function setup_scale()
  note = root
  pos = 1
  for i=1,42 do
    notes[i]=note
    -- print("note ",i," = ",notes[i])
    note = note + scale[pos]
    pos = pos+1
    if (pos>7) then pos=1 end
  end 
end

function gaus (x,width)
  return math.exp(- (x*x)/(2*(width*width)) )
end

function setup_prob(n)
  w = params:get("width_"..n)
  print("setting up voice ",n," width=",w)
  for i=1,15 do
    index = i-8 -- 8 is zero
    probs[n][i] = gaus(index,w)
  end
end

g.key = function(x,y,z)
  -- print("grid key ",x," ",y," ",z)
  -- grid key process
  if (y % 2 == 0) then -- even
    v = math.floor(y/2)

    if (x==1 and z==1) then
      note_shift[v]=1
    end
    if (x==1 and z==0) then
      note_shift[v]=0
    end

    if ((x>=2 and x<=7) and z==1 and note_shift[v]==1) then
      params:set("oct_"..v,x-1)
    end

    if ((x>=9 and x<=15) and z==1 and note_shift[v]==1) then
      params:set("note_"..v,x-8)
    end
  
  else -- odd
    v = math.ceil(y/2)
    if (x==1 and z==1) then
      if (status[v]==0) then
        start_voice(v)
      else
        stop_voice(v)
      end
    end
    if (z==1 and (x>=2 and x<=5)) then -- width
      params:set("width_"..v,x-1)
      setup_prob(v)
    end
    if (z==1 and x==7) then -- decrement instrument
      ic = params:get("inst_"..v)
      if (ic>1) then
        ic = ic-1
      end
      params:set("inst_"..v,ic)
    end
    if (z==1 and x==8) then -- increment instrument
      ic = params:get("inst_"..v)
      if (ic<#instruments) then
        ic = ic+1
      end
      params:set("inst_"..v,ic)
    end
    if (z==1 and x>8) then -- rate
      params:set("rate_"..v,x-8)
    end
  end
  grid_dirty = true
end

function grid_redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/15) -- refresh at 30fps.
    if grid_dirty then -- if a redraw is needed...
      grid_redraw() -- redraw...
      grid_dirty = false -- then redraw is no longer needed.
    end
  end
end

function redraw_clock()
  while true do
    clock.sleep(1/30)
    redraw()
  end
end

function grid_redraw()

  g:all(0) -- turn off all the LEDs
  
  for i=1,4 do
    g:led(1,2*i,note_shift[i]*6+3) -- voice shift
    if (note_shift[i]==0) then -- no shift
      g:led(positions[i]+1,2*i,15) -- note relative position
    else -- yes shift
      for x=2,7 do
        level = 6
        if (params:get("oct_"..i)==x-1) then
          level = 14
        end
        g:led(x,2*i,level)
      end
      for x=9,15 do
        level = 6
        if (params:get("note_"..i)==x-8) then
          level = 14
        end
        g:led(x,2*i,level) -- notes
      end
    end

    g:led(1,2*i-1,status[i]*6+3) -- voice status
    for x=2,5 do
      level = 3
      if (params:get("width_"..i)==(x-1)) then
        level = 12
      end
      g:led(x,2*i-1,level)
    end
    g:led(7,2*i-1,11) -- inst down
    g:led(8,2*i-1,11) -- inst up
    for x=9,16 do
      level = 6
      if (params:get("rate_"..i)==(x-8)) then
        level = 15
      end
      g:led(x,2*i-1,level)
    end
  end
  g:refresh() -- refresh the hardware to display the new LED selection
end  
  
function redraw()
  screen.clear()
  for i=1,4 do
    screen.level(1)
    for j=1,14 do
      if probs[i][j]>.05 then
        screen.move(80+(j-8)*4,16*(i)-8*probs[i][j]+2)
        screen.line(80+(j+1-8)*4,16*(i)-8*probs[i][j+1]+2)
      end
    end
    screen.stroke()
    screen.move(0,16*i-8)
    screen.level(1)
    screen.text(instruments[insts[i]])
    screen.move(80+(positions[i]-8)*4,16*i)
    screen.level(15)
    screen.text(MusicUtil.note_num_to_name(active_note[i], true))
  end
  screen.update()
end

function stop()
  if running then
    running = false
    all_notes_off()
  end
end

function start_voice(n)
  print("start voice ",n)
  if (status[n]==0) then 
    voice[n] = clock.run(evolve,n)
    status[n] = 1
    active_note[n] = -1
  end 
end

function stop_voice(n)
  print("stop voice ",n)
  if (status[n]==1) then 
    clock.cancel(voice[n])
    status[n] = 0
  end 
end

function start()
  if not running then
    for i=1,4 do
      start_voice(i)
      print("voice ",i, " is ID ", voice[i]) 
    end
    running = true
  end
end

function all_notes_off()
  for i=1,4 do
    stop_voice(i)
  end
  running = false
end

function reset_instrument(n,i)
  skeys:off({name=instruments[insts[n]],midi=active_note[n]})
  insts[n] = i
  active_note[n] = -1
end

function init()
  setup_scale()

  grid_dirty = false
  running = false
  
  clock.run(redraw_clock) 
  clock.run(grid_redraw_clock) 
  
  --counter = metro.init(count,1,-1)
  --counter:start()
  params:add{type = "trigger", id = "stop", name = "stop",
    action = function() stop() reset() end}
  params:add{type = "trigger", id = "start", name = "start",
    action = function() start() end}
  for i=1,4 do
    params:add{ type="number",id="width_"..i,name="width "..i,min=1,max=4,default=1,
      action = function(value)
        setup_prob(i)
      end
      }
    params:add{ type="number",id="rate_"..i,name="rate "..i,min=1,max=8,default=2}
    params:add{ type="number",id="oct_"..i,name="octave "..i,min=1,max=6,default=3}
    params:add{ type="number",id="note_"..i,name="note "..i,min=1,max=7,default=1}
    params:add{type = "option", id = "inst_"..i, name = "instrument "..i, options = instruments, default = i, 
      action = function(value) 
        reset_instrument(i,value) 
      end
      }
    
  end

  for i=1,4 do
    setup_prob(i)
    reset_instrument(i,i)
    insts[i] = i
    params:set("oct_"..i,i+1)
  end
  
  start()
end
