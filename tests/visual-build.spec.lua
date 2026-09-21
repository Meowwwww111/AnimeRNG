-- Structural mock only. Does not simulate Roblox rendering, physics or replication.
local count=0
local function check(v,msg) assert(v,msg); count=count+1 end
local vm={}
vm.__index=function(v,k)
    if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=='Unit' then return v/v.Magnitude end
end
vm.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul=function(a,b) if type(a)=='number' then a,b=b,a end; return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vm.__div=function(a,b) return a*(1/b) end
Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm) end}
Vector3.zero=Vector3.new()
local cm={}; local identity={1,0,0,0,1,0,0,0,1}
local function cf(p,r) return setmetatable({p=p,r=r or identity},cm) end
local function rotate(r,v) return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z) end
cm.__mul=function(a,b)
    local r={}
    for i=0,2 do for j=0,2 do r[i*3+j+1]=0; for k=0,2 do r[i*3+j+1]=r[i*3+j+1]+a.r[i*3+k+1]*b.r[k*3+j+1] end end end
    return cf(a.p+rotate(a.r,b.p),r)
end
local cmMethods={}
function cmMethods:Inverse() local r={self.r[1],self.r[4],self.r[7],self.r[2],self.r[5],self.r[8],self.r[3],self.r[6],self.r[9]}; return cf(rotate(r,self.p*-1),r) end
function cmMethods:Lerp(b,t) return cf(self.p+(b.p-self.p)*t,self.r) end
cm.__index=function(v,k) if k=='Position' then return v.p elseif k=='Rotation' then return cf(Vector3.zero,v.r) else return cmMethods[k] end end
CFrame={}
function CFrame.new(x,y,z) return cf(type(x)=='table' and x or Vector3.new(x,y,z)) end
function CFrame.Angles(x,y,z)
    local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
    return cf(Vector3.zero,{1,0,0,0,cx,-sx,0,sx,cx})*cf(Vector3.zero,{cy,0,sy,0,1,0,-sy,0,cy})*cf(Vector3.zero,{cz,-sz,0,sz,cz,0,0,0,1})
end
function CFrame.lookAt(pos) return CFrame.new(pos) end
local color={}; color.__index=color
function color:Lerp(b,t) return Color3.new(self.R+(b.R-self.R)*t,self.G+(b.G-self.G)*t,self.B+(b.B-self.B)*t) end
Color3={new=function(r,g,b) return setmetatable({R=r or 0,G=g or 0,B=b or 0},color) end}
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
local methods={}; local instance={}
local function signal() return {Connect=function() return {Disconnect=function() end} end,Fire=function() end} end
instance.__index=function(o,k)
    if methods[k] then return methods[k] end
    if k=='Position' then return o.CFrame.Position end
    if o._p[k]~=nil then return o._p[k] end
    for _,v in ipairs(o._children) do if v.Name==k then return v end end
end
instance.__newindex=function(o,k,v)
    if k=='Parent' then
        local old=o._p.Parent
        if old then for i,c in ipairs(old._children) do if c==o then table.remove(old._children,i); break end end end
        if v then table.insert(v._children,o) end
    end
    o._p[k]=v
end
Instance={new=function(class)
    return setmetatable({_p={ClassName=class,Name=class,CFrame=CFrame.new(),Size=Vector3.new(1,1,1),Anchored=false,
        Triggered=signal(),AncestryChanged=signal(),Destroying=signal()},_children={},_attrs={}},instance)
end}
function methods:IsA(class) return self.ClassName==class or (class=='BasePart' and ({Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true})[self.ClassName]) end
function methods:GetChildren() local a={}; for i,v in ipairs(self._children) do a[i]=v end; return a end
function methods:GetDescendants()
    local a={}; local function walk(o) for _,v in ipairs(o._children) do a[#a+1]=v; walk(v) end end
    walk(self); return a
end
function methods:FindFirstChild(n,recurse)
    for _,v in ipairs(self._children) do if v.Name==n then return v end end
    if recurse then for _,v in ipairs(self._children) do local r=v:FindFirstChild(n,true); if r then return r end end end
end
function methods:FindFirstChildOfClass(class) for _,v in ipairs(self._children) do if v:IsA(class) then return v end end end
function methods:SetAttribute(k,v) self._attrs[k]=v end
function methods:GetAttribute(k) return self._attrs[k] end
function methods:Destroy() self.Parent=nil; for _,v in ipairs(self:GetChildren()) do v:Destroy() end end
function methods:ScaleTo(scale)
    for _,v in ipairs(self:GetDescendants()) do
        if v:IsA('BasePart') then v.Size=v.Size*scale; v.CFrame=cf(v.CFrame.p*scale,v.CFrame.r) end
        if v:IsA('Motor6D') then v.C0=cf(v.C0.p*scale,v.C0.r); v.C1=cf(v.C1.p*scale,v.C1.r) end
    end
end
function methods:GetPivot() return self.PrimaryPart and self.PrimaryPart.CFrame or CFrame.new() end
function methods:PivotTo(c)
    local delta=c*self:GetPivot():Inverse()
    for _,p in ipairs(self:GetDescendants()) do if p:IsA('BasePart') then p.CFrame=delta*p.CFrame end end
end
function methods:Clone()
    local map={}
    local function clone(o)
        local n=Instance.new(o.ClassName); map[o]=n
        for k,v in pairs(o._p) do if k~='Parent' then n[k]=v end end
        for k,v in pairs(o._attrs) do n:SetAttribute(k,v) end
        for _,c in ipairs(o:GetChildren()) do local copy=clone(c); copy.Parent=n end
        return n
    end
    local result=clone(self)
    for old,new in pairs(map) do for _,key in ipairs({'PrimaryPart','Part0','Part1'}) do if old[key] then new[key]=map[old[key]] or old[key] end end end
    return result
end
Enum=setmetatable({},{__index=function(t,k) local e=setmetatable({},{__index=function(_,v) return k..'.'..v end}); rawset(t,k,e); return e end})
UDim2={fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end}
local RS=Instance.new('Folder'); RS.Name='ReplicatedStorage'
local collection={AddTag=function() end}
local profiles={}
local Data={Get=function(_,p) return profiles[p] end}
local players={PlayerRemoving=signal()}
workspace=Instance.new('Folder'); workspace.Name='Workspace'
game={GetService=function(_,n) return ({ReplicatedStorage=RS,CollectionService=collection,Players=players})[n] end}
local paths={CharacterDatabase='src/shared/CharacterDatabase.luau',MonsterDatabase='src/shared/MonsterDatabase.luau',
    ArtDirection='src/shared/ArtDirection.luau',WorldConfig='src/shared/WorldConfig.luau',PresentationMath='src/shared/PresentationMath.luau',
    ModelFactory='src/server/Services/ModelFactory.luau'}
local cache={DataService=Data}; local tokens=setmetatable({},{__index=function(_,k) return k end})
RS.Shared=tokens
require=function(id)
    if not cache[id] then cache[id]=assert(loadfile(assert(paths[id],id),'t',setmetatable({script={Parent=tokens}},{__index=_G})))() end
    return cache[id]
end
local env=setmetatable({script={Parent=tokens}},{__index=_G})
local V=assert(loadfile('src/shared/VisualFactory.luau','t',env))()
local characters=require('CharacterDatabase'); local monsters=require('MonsterDatabase')
local built=0
local function audit(model)
    check(model~=nil,'factory returned a model'); check(model.PrimaryPart~=nil,'model has root')
    local parts,joints=0,0
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA('BasePart') then
            parts=parts+1
            check(obj.Size.X>0 and obj.Size.Y>0 and obj.Size.Z>0,'positive dimensions')
            check(not obj.CanCollide and not obj.CanTouch and not obj.CanQuery,'cosmetics cannot change gameplay')
            check(obj.Anchored==(obj==model.PrimaryPart),'only root anchored')
        elseif obj:IsA('Motor6D') then
            joints=joints+1
            check(obj.Part0 and obj.Part1,'joint is connected')
            check(((obj.Part0.CFrame*obj.C0).Position-(obj.Part1.CFrame*obj.C1).Position).Magnitude<1e-7,'joint rest frames match')
        end
    end
    check(parts>=5 and parts<200,'model part budget')
    V.Animate(V.Joints(model),1,1,0.8)
    built=built+1; model:Destroy()
end
for id in pairs(characters) do audit(V.Build('Unit',id,1)) end
for w=1,2 do for id in pairs(monsters) do audit(V.Build('Monster',id,w)) end end
-- Optional model import remains inert until explicitly reviewed, and strips executable content.
local bank=Instance.new('Folder'); bank.Name='ArtAssets'; bank.Parent=RS
local units=Instance.new('Folder'); units.Name='Units'; units.Parent=bank
local template=Instance.new('Model'); template.Name='StreetFighter'; template.Parent=units
local root=Instance.new('Part'); root.Name='Root'; root.Parent=template; template.PrimaryPart=root
local accessory=Instance.new('Part'); accessory.Name='LooseAccessory'; accessory.Parent=template
local bad=Instance.new('Script'); bad.Parent=template
local nested=Instance.new('Folder'); nested.Parent=template
local module=Instance.new('ModuleScript'); module.Parent=nested
local sound=Instance.new('Sound'); sound.Parent=template
local notReviewed=V.Build('Unit','StreetFighter',1)
check(not notReviewed:GetAttribute('ImportedArt'),'unreviewed art not selected'); notReviewed:Destroy()
template:SetAttribute('ArtReviewed',true)
local safe=V.Build('Unit','StreetFighter',1)
check(safe:GetAttribute('ImportedArt'),'reviewed template selected')
check(safe.LooseAccessory:FindFirstChildOfClass('WeldConstraint')~=nil,'loose art is welded before display')
for _,o in ipairs(safe:GetDescendants()) do check(o.ClassName~='Script' and o.ClassName~='ModuleScript' and o.ClassName~='Sound','import sanitizer removes code/audio') end
safe:Destroy()
-- World service authorization is checked at teleport AND at physical position validation.
local World=assert(loadfile('src/server/Services/WorldService.luau','t',env))()
World:Build(function() end)
check(#World.Markers==20,'20 monster spawns remain')
local p=Instance.new('Player'); p.Name='Tester'
local char=Instance.new('Model'); char.Parent=workspace; p.Character=char
local hrp=Instance.new('Part'); hrp.Name='HumanoidRootPart'; hrp.Parent=char; char.PrimaryPart=hrp
local hum=Instance.new('Humanoid'); hum.Health=100; hum.Parent=char
profiles[p]={UnlockedWorld=1}
check(World:Teleport(p,1),'initial spawn')
check(not World:Teleport(p,2),'locked teleport refused at service layer')
hrp.CFrame=CFrame.new(6000,4,85)
check(not World:Enforce(p),'unauthorized physical crossing corrected')
check(hrp.Position.X==0 and p:GetAttribute('World')==1,'returns to world 1')
check(not World:Near(p,World.Stations[2].Portal,10000),'cannot use other world station even at extended range')
profiles[p].UnlockedWorld=2
check(World:Teleport(p,2),'authorized portal entry')
check(hrp.Position.X==6000 and p:GetAttribute('World')==2,'arrives at distinct world 2')
hrp.CFrame=CFrame.new(6500,4,85)
check(not World:Enforce(p),'out of bounds corrected for unlocked player too')
check(hrp.Position.X==6000,'returns to assigned world 2')
check(not World:Teleport(p,3),'invalid world rejected')
print('Structural mock: '..built..' original models built; '..count..' assertions pass (not a Studio rendering test)')
