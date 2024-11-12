ENT.Type = "point"
ENT.Base = "base_point"

ENT.Items 		= { "ph_luckyball", "ph_devilball", "ph_ultpointball" }
ENT.MsgPrefix 	= "[PH:X Item Spawner] "

local cvEnableTeamSpawner --temp cvar because we dont want to mess sh_convars.lua due to new upcoming PHX update
if !ConVarExists( "ph_enable_team_itemspawner" ) then
	cvEnableTeamSpawner = CreateConVar( "ph_enable_team_itemspawner", "1", FCVAR_SERVER_CAN_EXECUTE+FCVAR_ARCHIVE+FCVAR_REPLICATED, "Enable or Disable Team Item Spawner, this is where Lucky Balls and Devil Crystals are spawned.", 0, 1 )
end

if SERVER then
	ENT.RemoveAfterSpawn = false
end

function ENT:Initialize()
	if not cvEnableTeamSpawner:GetBool() then
		if SERVER then self:Remove(); end
		return
	end
	
	if SERVER then
		self.RemoveAfterSpawn = self:HasSpawnFlags(128)
	end
	self:SetSilent( self:HasSpawnFlags(64) )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "SpawnEntity" )
    self:NetworkVar( "Int", 1, "Amount" )
    self:NetworkVar( "String", 0, "EntityName" )
	self:NetworkVar( "Bool", 0, "Silent" )
end

function ENT:KeyValue( key, value )
	if key == "spawnent" then
		local id = tonumber(value)
		id = math.Clamp(id, 1, #self.Items)
		self:SetSpawnEntity( id )
	elseif key == "amount" then
		self:SetAmount( value )
	elseif key == "spawnontarget" then
        self:SetEntityName( value )
    else
		self:SetNetworkKeyValue(key, value)
	end
end

function ENT:CreateBall( entToSpawn, amt, targEnt, pos, ang )
    if SERVER then
	
		if amt > 0 then
		
			if entToSpawn == "ph_ultpointball" then
				print(self.MsgPrefix .. "Sorry, the entity " .. entToSpawn .. " is unavailable yet!")
				return
			end
		
			-- Don't spawn entity nearby 16-units if they're exist in that radius.
			local findEnt = ents.FindInSphere( pos, 16 )
			for _,v in pairs(findEnt) do
				if IsValid(v) and v:GetClass() == entToSpawn then
					MsgC(Color(240,72,86), self.MsgPrefix .. "I was trying to spawn item but I Found item(s) " .. entToSpawn .. " near ".. tostring(v:GetPos())..", Surpressing!\n")
					return
				end
			end
		
			-- Only spawn 1 devil crystal, ignore the ammount.
			if amt > 1 and entToSpawn == "ph_devilball" then 
				MsgC(Color(240,72,86), self.MsgPrefix .. "Devil Crystal must be spawned with only 1 amount! (Amount KV: "..amt.." !!)\n")
				amt = 1
			end
			
			if not self:GetSilent() then
				local targ = self
				if (targEnt) and IsValid(targEnt) then targ = targEnt end
				targ:EmitSound( Sound("WeaponDissolve.Dissolve") )
			end
			
			for i=1,amt do
				local e = ents.Create( entToSpawn )
				e:SetPos(pos)
				e:SetAngles(ang)
				e:Spawn()
				e:Activate()
			end
			
			if (self.RemoveAfterSpawn) then
				timer.Simple(0, function() self:Remove() end)
			end
		end
	
    end
end

function ENT:makeEntity()

	if not GetGlobalBool("InRound", false) then
		MsgC(Color(240,72,86), self.MsgPrefix .. "Cannot spawn PH:X Item because round isn't properly started!\n")
		return 
	end

    local entToSpawn = self.Items[ self:GetSpawnEntity() ]
    local amount = math.Clamp(self:GetAmount(), 1, 5) -- Clamp Amount to 5.
    local SpawnOn = self:GetEntityName()
    
    local pos = self:GetPos()
    local ang = angle_zero
    
	local on
    if SpawnOn and SpawnOn ~= nil and SpawnOn ~= "" then
        local ent = ents.FindByName(SpawnOn)		
        on = ent[math.random(1, #ent)]
		
		local findEnt = ents.FindInSphere( on:GetPos(), 16 )
		for _,v in pairs(findEnt) do
			-- don't spawn if an entity is there.
			if IsValid(v) and v:GetClass() == entToSpawn then
				MsgC(Color(240,72,86), self.MsgPrefix .. "Attempting to spawn an item on position ("..tostring(on:GetPos())..") but there was an existing item(s) near me. Surpressing!\n")
				return
			end
		end
        
        pos = on:GetPos()
        ang = on:GetAngles()            
    end
    
    self:CreateBall( entToSpawn, amount, on, pos, ang )
    
end

function ENT:AcceptInput(name, act, cal, data)
    if name == "Spawn" then
        self:makeEntity()
        return true
    elseif name == "SetAmount" then
        self:SetAmount(tonumber(data))
        return true
    elseif name == "ChangeTarget" then
        self:SetEntityName(tostring(data))
        return true
    elseif name == "SetType" then
		local id = tonumber(data)
		id = math.Clamp(id, 1, #self.Items)
		self:SetSpawnEntity( id )
        return true
    end
end
