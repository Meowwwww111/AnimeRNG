-- Pure functions shared by server boundary checks and client presentation tests.
local M={}
function M.finite(x) return type(x)=="number" and x==x and x>-math.huge and x<math.huge end
function M.alpha(rate,dt)
    if not M.finite(dt) or dt<=0 then return 0 end
    return 1-math.exp(-math.max(0,rate)*dt)
end
function M.canEnter(unlocked,destination,worlds)
    return M.finite(destination) and destination%1==0 and worlds[destination]~=nil
        and M.finite(unlocked) and destination<=math.floor(unlocked)
end
function M.inside(zone,position)
    if not zone or not position then return false end
    if not M.finite(position.X) or not M.finite(position.Y) or not M.finite(position.Z) then return false end
    local x,y,z=position.X-zone.Origin.X,position.Y-zone.Origin.Y,position.Z-zone.Origin.Z
    return x>=zone.MinX and x<=zone.MaxX and z>=zone.MinZ and z<=zone.MaxZ and y>=zone.MinY and y<=zone.MaxY
end
function M.segment(samples,time)
    if #samples<2 then return 1,1,0 end
    if time<=samples[1].Time then return 1,1,0 end
    for i=2,#samples do
        local a,b=samples[i-1],samples[i]
        if time<=b.Time then
            local span=b.Time-a.Time
            return i-1,i,span>0 and math.max(0,math.min(1,(time-a.Time)/span)) or 1
        end
    end
    return #samples,#samples,0 -- hold; never extrapolate indefinitely on packet loss
end
return M
