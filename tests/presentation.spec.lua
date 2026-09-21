local M=dofile('src/shared/PresentationMath.luau')
local W=dofile('src/shared/WorldConfig.luau')
local count=0
local function check(v,msg) assert(v,msg); count=count+1 end
check(M.canEnter(1,1,W),'starter world')
check(not M.canEnter(1,2,W),'world 2 is locked')
check(M.canEnter(2,2,W),'unlocked travel')
for _,x in ipairs({0,-1,1.5,3,math.huge,'2',false}) do check(not M.canEnter(2,x,W),'invalid destination') end
check(not M.canEnter(0/0,2,W),'NaN unlock')
check(not M.canEnter(2,0/0,W),'NaN destination')
for zone=1,2 do
    local origin=W[zone].Origin
    check(M.inside(W[zone],{X=origin.X,Y=4,Z=85}),'own spawn inside')
    check(not M.inside(W[zone],{X=origin.X+151,Y=4,Z=85}),'east boundary')
    check(not M.inside(W[zone],{X=origin.X-151,Y=4,Z=85}),'west boundary')
    check(not M.inside(W[zone],{X=origin.X,Y=4,Z=146}),'north boundary')
    check(not M.inside(W[zone],{X=origin.X,Y=4,Z=-216}),'south boundary')
    check(not M.inside(W[zone],{X=origin.X,Y=-20,Z=85}),'void return')
    check(not M.inside(W[zone],{X=origin.X,Y=121,Z=85}),'height boundary')
    check(not M.inside(W[zone],{X=origin.X,Y=0/0,Z=85}),'NaN coordinate')
    check(not M.inside(W[zone],{X=origin.X,Y=4,Z=math.huge}),'infinite coordinate')
end
check(not M.inside(W[1],{X=6000,Y=4,Z=85}),'world 2 cannot be walked into as world 1')
check(not M.inside(W[2],{X=0,Y=4,Z=85}),'world 1 is not world 2')
check(not M.inside(W[1],{X=500,Y=4,Z=85}),'old adjoining world coordinates rejected')
check(W[2].Origin.X-W[1].Origin.X>5000,'separate locations')
for _,key in ipairs({'Slime','Bandit','Ogre','Demon','Titan','WorldBoss'}) do
    check(W[1].EnemyNames[key]~=W[2].EnemyNames[key],'distinct enemy identity')
end
local art=dofile('src/shared/ArtDirection.luau')
for id,style in pairs(art.Enemies[1]) do check(style~=art.Enemies[2][id],'different enemy silhouette') end
check(W[1].Theme~=W[2].Theme,'distinct scenery')
check(W[1].ClockTime~=W[2].ClockTime,'distinct lighting')
local function advance(fps)
    local value=0
    for _=1,fps do value=value+(1-value)*M.alpha(16,1/fps) end
    return value
end
check(math.abs(advance(30)-advance(60))<1e-12,'30/60 FPS smoothing agreement')
check(math.abs(advance(60)-advance(144))<1e-12,'60/144 FPS smoothing agreement')
check(M.alpha(16,0)==0,'zero dt')
check(M.alpha(16,-1)==0,'negative dt')
check(M.alpha(16,0/0)==0,'bad dt')
local samples={{Time=1},{Time=1.12},{Time=1.24}}
local a,b,t=M.segment(samples,1.06)
check(a==1 and b==2 and math.abs(t-0.5)<1e-10,'interpolates between network snapshots')
a,b,t=M.segment(samples,0); check(a==1 and b==1 and t==0,'holds before first snapshot')
a,b,t=M.segment(samples,99); check(a==3 and b==3 and t==0,'holds after last snapshot without runaway')
a,b,t=M.segment({{Time=1}},2); check(a==1 and b==1 and t==0,'single snapshot safe')
print('Presentation/access rules: '..count..' checks pass')
