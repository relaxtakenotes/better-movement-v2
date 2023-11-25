local flags = {FCVAR_ARCHIVE, FCVAR_GAMEDLL, FCVAR_REPLICATED}

if SERVER then util.AddNetworkString("bm_footstep") end

bm_vars = {
    enabled = CreateConVar("sv_bm_enabled", 1, flags, "Mod Toggle"),
    speed = {
        run = CreateConVar("sv_bm_speed_run", 300, flags, "Run Speed"),
        walk = CreateConVar("sv_bm_speed_walk", 150, flags, "Normal Speed"),
        slowwalk = CreateConVar("sv_bm_speed_slowwalk", 100, flags, "Slow Walking Speed"),
        inside_multiplier = CreateConVar("sv_bm_speed_inside_multiplier", 0.8, flags, "Inside Speed Multiplier"),
        crouch = CreateConVar("sv_bm_speed_crouched", 0.5, flags, "Crouched Speed Multiplier"),
        duck = CreateConVar("sv_bm_speed_duck", 0.3, flags, "Duck Speed"),
        unduck = CreateConVar("sv_bm_speed_unduck", 0.3, flags, "Unduck Speed")
    },
    slowdown = {
        angle_enabled = CreateConVar("sv_bm_angle_slowdown", 1, flags, "Slope Slowdown Toggle"),
        angle_multiplier = CreateConVar("sv_bm_angle_slowdown_multiplier", 1, flags, "Slope Slowdown Multiplier"),
        turn_enabled = CreateConVar("sv_bm_turn_slowdown", 1, flags, "Turn Slowdown Toggle"),
        turn_multiplier = CreateConVar("sv_bm_turn_slowdown_multiplier", 1, flags, "Turn Slowdown Multiplier"),
        landing = CreateConVar("sv_bm_slowdown_on_landing", 1, flags, "Landing Slowdown Toggle"),
        after_jump = CreateConVar("sv_bm_slowdown_after_jump", 1, flags, "After Jump Slowdown Toggle"),
        in_air = CreateConVar("sv_bm_disable_in_air_movement", 1, flags, "Air Strafe Toggle"),
        non_forward = CreateConVar("sv_bm_slowdown_non_forward", 1, flags, "Non Forward Slowdown Toggle"),
        non_forward_multiplier = CreateConVar("sv_bm_slowdown_non_forward_multiplier", 1, flags, "Non Forward Slowdown Multiplier"),
        weakness_enabled = CreateConVar("sv_bm_slowdown_weakness", 1, flags, "General Weakness Toggle"),
        weakness_multiplier = CreateConVar("sv_bm_slowdown_weakness_multiplier", 1, flags, "General Weakness Multiplier"),
        weakness_rest_multiplier = CreateConVar("sv_bm_slowdown_weakness_rest_multiplier", 1, flags, "General Weakness Rest Multiplier")
    },
    steptime = {
        exponent = CreateConVar("sv_bm_step_time_exponent", 0.6, flags, "Exponent (Step Time)"),
        multiplier = CreateConVar("sv_bm_step_time_multiplier", 2600, flags, "Multiplier (Step Time)"),
        offset = CreateConVar("sv_bm_step_time_offset", 0, flags, "Offset (Step Time)"),
        max = CreateConVar("sv_bm_step_time_max", 500, flags, "Max (Step Time)"),
        min = CreateConVar("sv_bm_step_time_min", 10, flags, "Min (Step Time)")
    },
    interpolation_multiplier = CreateConVar("sv_bm_interpolation_multiplier", 1, flags, "Interpolation Multiplier"),
    interpolation_type = CreateConVar("sv_bm_interpolation_type", 0, flags, "Interpolation Type (FANCY = 0, LINEAR = 1)"),
    inside_checks_enabled = CreateConVar("sv_bm_inside_checks", 1, flags, "Inside Checks Toggle"),
    inside_checks_period = CreateConVar("sv_bm_inside_checks_period", 1, flags, "Inside Checks Time Period"),
    slow_footsteps = CreateConVar("sv_bm_slow_footsteps", 0, flags, "Force Slow Footsteps Toggle")
}

local SINGLEPLAYER = game.SinglePlayer()
local FANCY_INTERPOLATION = 0
local LINEAR_INTERPOLATION = 1

local function traceable_to_sky(pos, offset)
    local tr = util.TraceLine({start=pos + offset, endpos=pos + Vector(offset.x, offset.y, 100000000), mask=MASK_NPCWORLDSTATIC})
    local temp = util.TraceLine({start=tr.StartPos, endpos=pos, mask=MASK_NPCWORLDSTATIC})
    if temp.HitPos == pos and not temp.StartSolid and tr.HitSky then return true end
    return false
end

local function get_env_state(pos)
    local tr_1 = traceable_to_sky(pos, Vector(0,0,0))
    local tr_2 = traceable_to_sky(pos, Vector(120,0,0))
    local tr_3 = traceable_to_sky(pos, Vector(0,120,0))
    local tr_4 = traceable_to_sky(pos, Vector(-120,0,0))
    local tr_5 = traceable_to_sky(pos, Vector(0,-120,0))
    if (tr_1 or tr_2 or tr_3 or tr_4 or tr_5) then return "outdoors" else return "indoors" end
end

local function arse(ply, start, endd)
    if bm_vars.interpolation_type:GetInt() == LINEAR_INTERPOLATION then return 1 end

    start = ply:GetNW2Var(start, 0)
    local thing = math.abs(start - endd)

    if thing > 0 and thing < 0.1 then
        thing = 0
    end

    thing = thing / bm_vars.speed.run:GetFloat()

    if thing < 0.2 then
        thing = thing
    end

    thing = math.Clamp(thing, 0.4 + ply:GetNW2Var("mouse_slowdown", 0) * 0.3, 1)

    return math.ease.InOutExpo(thing * 0.75)
end

hook.Add("SetupMove", "bm_setupmove", function(ply, mv, cmd)
    if not bm_vars.enabled:GetBool() then return end

    local maxspeed = ply:GetMaxSpeed()
    
    local forwardmove = cmd:GetForwardMove() / 10000 * maxspeed
    local sidemove = cmd:GetSideMove() / 10000 * maxspeed
    
    if bm_vars.slowdown.non_forward:GetBool() then
        local nf_mult = bm_vars.slowdown.non_forward_multiplier:GetFloat()
        sidemove = sidemove * 0.75 * nf_mult
        if forwardmove < 0 then 
            forwardmove = forwardmove * 0.75 * nf_mult
            maxspeed = math.abs(forwardmove)
        end

    end

    local origin = mv:GetOrigin()
    local onground = ply:OnGround()
    local waterlevel = ply:WaterLevel()

    // handle weakness
    if bm_vars.slowdown.weakness_enabled:GetBool() then
        ply:SetNW2Var("previous_origin", ply:GetNW2Var("current_origin", origin))
        ply:SetNW2Var("current_origin", origin)

        local diff = ply:GetNW2Var("current_origin") - ply:GetNW2Var("previous_origin")

        local weakness = ply:GetNW2Var("weakness", 0)

        if diff.z > 0 and onground then
            weakness = weakness + diff.z / 20 * bm_vars.slowdown.weakness_multiplier:GetFloat()
        end

        if math.abs(forwardmove) + math.abs(sidemove) > 0.1 then
            weakness = weakness + FrameTime() * 10.1 * bm_vars.slowdown.weakness_multiplier:GetFloat() * (maxspeed / bm_vars.speed.run:GetFloat())
        end

        weakness = math.Clamp(weakness - FrameTime() * 9 * bm_vars.slowdown.weakness_rest_multiplier:GetFloat(), 0, 128)

        ply:SetNW2Var("weakness", weakness)

        local cw_thing = (1 - ply:GetNW2Var("weakness", 0) / 128 * 0.5)

        forwardmove = forwardmove * cw_thing
        sidemove = sidemove * cw_thing
        maxspeed = maxspeed * cw_thing
    end

    // handle slowdown on landing
    if bm_vars.slowdown.landing:GetBool() then
        if ply:GetNW2Var("slowdown_on_hit", 1) < 0.999 then
            ply:SetNW2Var("slowdown_on_hit", Lerp(FrameTime() + math.abs(ply:GetNW2Var("slowdown_on_hit", 1) - 1) * FrameTime() * 50, 
                                                ply:GetNW2Var("slowdown_on_hit", 1), 1))
        else
            ply:SetNW2Var("slowdown_on_hit", 1)
        end
    end

    // slowdown on slopes
    if bm_vars.slowdown.angle_enabled:GetBool() and ply:OnGround() then
        local move_dir = mv:GetVelocity()

        local maxs = ply:OBBMaxs()
        local mins = ply:OBBMins()
        local offset = vector_up * (ply:GetStepSize() + 2)

        maxs:Sub(offset)

        local first_tr = util.TraceHull({
            start = origin + offset,
            endpos = origin + move_dir * FrameTime() * offset.z + offset,
            filter = ply,
            maxs = maxs,
            mins = mins
        })

        local second_tr = util.TraceHull({
            start = first_tr.HitPos,
            endpos = first_tr.HitPos - vector_up * 100,
            filter = ply,
            maxs = maxs,
            mins = mins
        })

        local first = -(origin - second_tr.HitPos):GetNormalized()
        local second = move_dir:GetNormalized()

        local angle = math.deg(math.acos(first:Dot(second) / (first:Length() * second:Length())))

        if angle != angle then
            angle = 0
        end

        if origin.z > second_tr.HitPos.z then
            angle = angle * -1
        end
        
        local am_mult = bm_vars.slowdown.angle_multiplier:GetFloat()

        local thing = (1 - math.min(angle * am_mult, 90) / 90 * 0.5)

        if angle > 0 then
            forwardmove = forwardmove * thing
            sidemove = sidemove * thing
            maxspeed = maxspeed * thing
        end
    end

    // handle the "boosted" state
    if mv:KeyPressed(IN_SPEED) then
        ply:SetNW2Var("in_speed_time", 0.3)
        ply:SetNW2Var("in_speed_count", ply:GetNW2Var("in_speed_count", 0) + 1)
    end

    if ply:GetNW2Var("in_speed_count", 0) >= 2 then
        ply:SetNW2Var("in_boosted_run", true)
    else
        ply:SetNW2Var("in_boosted_run", false)
    end

    if not mv:KeyDown(IN_SPEED) and ply:GetNW2Var("in_speed_time", 0) <= 0 then
        ply:SetNW2Var("in_speed_count", 0)
    end

    ply:SetNW2Var("in_speed_time", math.max(ply:GetNW2Var("in_speed_time", 0) - FrameTime(), 0))

    // handle being inside
    if bm_vars.inside_checks_enabled:GetBool() then
        ply:SetNW2Var("env_check_timeout", math.max(ply:GetNW2Var("env_check_timeout", 0) - FrameTime(), 0))

        if ply:GetNW2Var("env_check_timeout", 0) <= 0 and mv:GetVelocity():Length() > 0 then
            if get_env_state(mv:GetOrigin() + Vector(0,0,40)) == "indoors" then
                ply:SetNW2Var("env_is_inside", true)
            else
                ply:SetNW2Var("env_is_inside", false)
            end
            ply:SetNW2Var("env_check_timeout", bm_vars.inside_checks_period:GetFloat())
        end

        if ply:GetNW2Var("env_is_inside") and not ply:GetNW2Var("in_boosted_run") then
            ply:SetNW2Var("env_slowdown", Lerp(FrameTime() * 3, ply:GetNW2Var("env_slowdown", 1), bm_vars.speed.inside_multiplier:GetFloat()))
        else
            ply:SetNW2Var("env_slowdown", Lerp(FrameTime() * 3, ply:GetNW2Var("env_slowdown", 1), 1))
        end

        local slowdown = ply:GetNW2Var("env_slowdown", 1)
        
        forwardmove = forwardmove * slowdown
        sidemove = sidemove * slowdown
        maxspeed = maxspeed * slowdown
    end

    // handle turn slowdown
    if bm_vars.slowdown.turn_enabled:GetBool() then
        local mult = math.max(bm_vars.slowdown.turn_multiplier:GetFloat(), 0.05)
        local factor = math.Remap(math.Clamp(math.abs(cmd:GetMouseX() / 20 * mult), 0, 100 * mult / 2), 0, 100 * mult / 2, 1, 0)
        ply:SetNW2Var("mouse_slowdown", Lerp(FrameTime() * 50 / mult, ply:GetNW2Var("mouse_slowdown", 0), factor))
    end

    // handle being in air
    if not onground and bm_vars.slowdown.in_air:GetBool() and waterlevel < 2 then
        forwardmove = forwardmove * 0.1
        sidemove = sidemove * 0.1
    end

    // drowning!! wow
    if not onground and waterlevel >= 2 then
		mv:SetUpSpeed(-100)
		cmd:SetUpMove(-100)
	end

    if ply:Crouching() then
        local mult = 1

        if cmd:KeyDown(IN_SPEED) then
            mult = math.min(1, bm_vars.speed.crouch:GetFloat() * 2)
        else
            mult = bm_vars.speed.crouch:GetFloat()
        end

        forwardmove = forwardmove * mult
        sidemove = sidemove * mult
    end

    // lerp everything
    local mult = bm_vars.interpolation_multiplier:GetFloat()
    local more_slowdown = ply:GetNW2Var("mouse_slowdown", 0) * ply:GetNW2Var("slowdown_on_hit", 1)

    maxspeed = maxspeed * more_slowdown

    local early_speed = math.sqrt(math.abs(forwardmove)^2 + math.abs(sidemove)^2)
    if early_speed > maxspeed then
        forwardmove = forwardmove * maxspeed / early_speed
        sidemove = sidemove * maxspeed / early_speed
    end

    ply:SetNW2Var("lerped_forwardmove", Lerp(FrameTime() * arse(ply, "lerped_forwardmove", forwardmove) * 10 * mult, 
                                            ply:GetNW2Var("lerped_forwardmove", 0), 
                                            forwardmove) * more_slowdown)
    ply:SetNW2Var("lerped_sidemove", Lerp(FrameTime() * arse(ply, "lerped_sidemove", sidemove) * 10 * mult, 
                                        ply:GetNW2Var("lerped_sidemove", 0), 
                                        sidemove) * more_slowdown)

    local _forward = ply:GetNW2Var("lerped_forwardmove", 0)
    local _side = ply:GetNW2Var("lerped_sidemove", 0)

    local maxspeed_raw = math.sqrt(_side^2 + _forward^2)

    ply:SetNW2Var("new_maxspeed", maxspeed_raw, 30)
    
    // apply it all
    local walktype = "walk"
    if mv:KeyDown(IN_SPEED) then walktype = "run" end
    if mv:KeyDown(IN_WALK) then walktype = "slowwalk" end
    
    local fraction = math.Clamp(maxspeed_raw / maxspeed, 1, 2)
    ply:SetNW2Var("bmfraction", Lerp(FrameTime() * 20, ply:GetNW2Var("bmfraction", 1), fraction))
    
    local _bmfraction = ply:GetNW2Var("bmfraction", 1)
    
    ply:SetWalkSpeed(bm_vars.speed.walk:GetFloat() * _bmfraction)
    ply:SetRunSpeed(bm_vars.speed.run:GetFloat() * _bmfraction)
    ply:SetSlowWalkSpeed(bm_vars.speed.slowwalk:GetFloat() * _bmfraction)
    
    if ply:GetMoveType() == MOVETYPE_WALK then
        mv:SetForwardSpeed(_forward)
        mv:SetSideSpeed(_side)
        cmd:SetForwardMove(_forward)
        cmd:SetSideMove(_side)
    end
    
    // reduce air velocity to prevent bhopping
    ply:SetNW2Bool("bm_was_on_ground", ply:GetNW2Bool("bm_on_ground", true))
    ply:SetNW2Bool("bm_on_ground", ply:OnGround())

    local _bm_on_ground = ply:GetNW2Bool("bm_on_ground")
    if ply:GetNW2Bool("bm_was_on_ground") != ply:GetNW2Bool("bm_on_ground") and mv:KeyDown(IN_JUMP) and !ply:GetNW2Bool("bm_on_ground") and ply:WaterLevel() < 3 then
        local vel = mv:GetVelocity()
        vel.x = vel.x / 1.5
        vel.y = vel.y / 1.5
        mv:SetVelocity(vel)
    end

    // crouch speed wow
    ply:SetDuckSpeed(bm_vars.speed.duck:GetFloat())
    ply:SetUnDuckSpeed(bm_vars.speed.unduck:GetFloat())
end)

hook.Add("OnPlayerHitGround", "bm_playerhitground", function(ply, in_water, on_floater, speed) 
    if not bm_vars.enabled:GetBool() then return end

    ply:SetNW2Var("slowdown_on_hit", 0)
end)


hook.Add("PlayerStepSoundTime", "bm_stepsoundtime_slow", function(ply, iType, bWalking) 
    if not bm_vars.enabled:GetBool() or not bm_vars.slow_footsteps:GetBool() then return end

    return math.huge
end)

hook.Add("PlayerStepSoundTime", "bm_stepsoundtime_normal", function(ply, iType, bWalking)
    if bm_vars.slow_footsteps:GetBool() then return end

    if not bm_vars.enabled:GetBool() then return end

    if ply:InVehicle() then return end

    local fmaxspeed = ply:GetNW2Var("new_maxspeed", ply:GetMaxSpeed())
    local exp = bm_vars.steptime.exponent:GetFloat()
    local mult = bm_vars.steptime.multiplier:GetFloat()
    local offset = bm_vars.steptime.offset:GetFloat()
    local fsteptime = (fmaxspeed^exp/fmaxspeed)*mult + offset
    
    if not fsteptime then return end
    if fsteptime != fsteptime then return end

    fsteptime = math.Clamp(fsteptime, bm_vars.steptime.min:GetFloat(), bm_vars.steptime.max:GetFloat())

    if (iType == STEPSOUNDTIME_ON_LADDER) then
        fsteptime = fsteptime + 100
    elseif (iType == STEPSOUNDTIME_WATER_KNEE) then
        fsteptime = fsteptime + 200
    end

    if (ply:Crouching()) then
        fsteptime = fsteptime * ply:GetCrouchedWalkSpeed() + 400
    end
    
    return fsteptime
end)

local sv_footsteps = GetConVar("sv_footsteps")

local function GetFootstepSurface(surfacename)
    return util.GetSurfaceData(util.GetSurfaceIndex(surfacename))
end

local function GetStepSoundVelocities(ply)
    local velwalk = 90
    local velrun = 220

	if ply:Crouching() or ply:GetMoveType() == MOVETYPE_LADDER then
		velwalk = 60
		velrun = 80
    end

    return velwalk, velrun
end

local function GetStepSoundTime(ply, iType, bWalking)
    local fmaxspeed = ply:GetNW2Var("new_maxspeed", ply:GetMaxSpeed())
    local exp = bm_vars.steptime.exponent:GetFloat()
    local mult = bm_vars.steptime.multiplier:GetFloat()
    local offset = bm_vars.steptime.offset:GetFloat()
    local fsteptime = (fmaxspeed^exp/fmaxspeed)*mult + offset
    
    if not fsteptime then return 100 end
    if fsteptime != fsteptime then return 100 end

    fsteptime = math.Clamp(fsteptime, bm_vars.steptime.min:GetFloat(), bm_vars.steptime.max:GetFloat())

    if (iType == STEPSOUNDTIME_ON_LADDER) then
        fsteptime = fsteptime + 100
    elseif (iType == STEPSOUNDTIME_WATER_KNEE) then
        fsteptime = fsteptime + 200
    end

    if (ply:Crouching()) then
        fsteptime = fsteptime * ply:GetCrouchedWalkSpeed() + 400
    end
    
    return fsteptime
end

local function GetGroundSurface(ply)
    local vecOrigin = ply:GetPos()

    local _data = {
        start = vecOrigin,
        endpos = vecOrigin - vector_up * 64,
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        filter = ply,
        mask = MASK_PLAYERSOLID_BRUSHONLY,
        collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
    }

    _data.mins.x = _data.mins.x * 0.5 
    _data.mins.y = _data.mins.y * 0.5 
    _data.maxs.x = _data.maxs.x * 0.5 
    _data.maxs.y = _data.maxs.y * 0.5 

    local ang = ply:EyeAngles()
    ang.z = 0
    local right = ang:Right() * 10
    if ply.m_nStepside == 0 then
        _data.start:Sub(right)
    else
        _data.start:Add(right)
    end

    local tr = util.TraceHull(_data)

    if tr.Fraction >= 1 then
        return nil
    end

    return util.GetSurfaceData(tr.SurfaceProps)
end

local function PlayStepSound(ply, vecOrigin, psurface, fvol, force)
    if game.MaxPlayers() > 1 and not sv_footsteps:GetBool() then return end
    
    if not psurface then return end

    if ply.m_nStepside == 0 then stepSoundName = psurface.stepLeftSound else stepSoundName = psurface.stepRightSound end

	if !stepSoundName then return end

    if ply.m_nStepside == 0 then ply.m_nStepside = 1 else ply.m_nStepside = 0 end

    local props = sound.GetProperties(stepSoundName)

    if props then
        local path = props["sound"]

        if type(path) == "table" then
            path = path[math.random(1, table.Count(path))]
        end

        if SERVER then
            local result = hook.Run("PlayerFootstep", ply, vecOrigin, ply.m_nStepside, path, fvol, nil)
            if game.SinglePlayer() and result == nil then
                ply:EmitSound(path, 75, 100, fvol, CHAN_BODY, 0, 0)
                //EmitSound(path, vecOrigin, ply:EntIndex(), CHAN_BODY, fvol, 75, SND_NOFLAGS, 100, 0)
            end
            net.Start("bm_footstep")
                net.WriteEntity(ply)
                net.WriteVector(vecOrigin)
                net.WriteFloat(ply.m_nStepside)
                net.WriteString(path)
                net.WriteFloat(fvol)
            //net.Broadcast()
            net.SendPAS(vecOrigin)
        end

        // can be here only if it's multiplayer and we are a client
        // otherwise we let the server do the work
        if CLIENT then
            if hook.Run("PlayerFootstep", ply, vecOrigin, ply.m_nStepside, path, fvol, nil) == nil then
                ply:EmitSound(path, 75, 100, fvol, CHAN_BODY, 0, 0)
                //EmitSound(path, vecOrigin, ply:EntIndex(), CHAN_BODY, fvol, 75, SND_NOFLAGS, 100, 0)
            end
        end
    end
end

local function UpdateStepSound(ply, psurface, vecOrigin, vecVelocity)
	local bWalking
	local fvol
	local speed
	local velrun
	local velwalk
	local fLadder
    local movetype = ply:GetMoveType()
    local flags = ply:GetFlags()
    local waterlevel = ply:WaterLevel()
    
    if (ply.m_flStepSoundTime or 0) > 0 then
		ply.m_flStepSoundTime = ply.m_flStepSoundTime - 1000 * FrameTime()
		if ply.m_flStepSoundTime < 0 then
			ply.m_flStepSoundTime = 0
        end
    end

    if (ply.m_flStepSoundTime or 0) > 0 then return end

    if bit.band(flags, FL_FROZEN) == FL_FROZEN or bit.band(flags, FL_ATCONTROLS) == FL_ATCONTROLS then
        return
    end

    if movetype == MOVETYPE_NOCLIP or movetype == MOVETYPE_OBSERVER then return end

    if not sv_footsteps:GetBool() then return end

    speed = vecVelocity:Length()
	local groundspeed = vecVelocity:Length2D()

	// determine if we are on a ladder
	fLadder = movetype == MOVETYPE_LADDER

	velwalk, velrun = GetStepSoundVelocities(ply)

	local onground = ply:OnGround()

	local movingalongground = groundspeed > 0.0001
	local moving_fast_enough = true //speed >= velwalk

    if not moving_fast_enough or not (fLadder or (onground and movingalongground)) then
        return
    end

    if fLadder and speed <= 0.0001 then return end

    bWalking = speed < velrun;		

    // find out what we're stepping in or on...
	if fLadder and speed > 0.0001 then
		psurface = GetFootstepSurface("ladder")
		fvol = 0.5;
        ply.m_flStepSoundTime = GetStepSoundTime(ply, STEPSOUNDTIME_ON_LADDER, bWalking) / 1.6
    elseif waterlevel == 2 then
		if ply.iSkipStep == 0 then
			ply.iSkipStep = ply.iSkipStep + 1
			return
        end

        ply.iSkipStep = (ply.iSkipStep or 0) + 1

		if ply.iSkipStep == 3 then
			ply.iSkipStep = 0
        end
        
		psurface = GetFootstepSurface("wade")
		fvol = 0.65
        ply.m_flStepSoundTime = GetStepSoundTime(ply, STEPSOUNDTIME_WATER_KNEE, bWalking)
	elseif waterlevel == 1 then
		psurface = GetFootstepSurface("water")
        if bWalking then fvol = 0.2 else fvol = 0.5 end

        ply.m_flStepSoundTime = GetStepSoundTime(ply, STEPSOUNDTIME_WATER_FOOT, bWalking)
	else
		if not psurface then return end

        ply.m_flStepSoundTime = GetStepSoundTime(ply, STEPSOUNDTIME_NORMAL, bWalking)

        if psurface.material == MAT_CONCRETE then
            if bWalking then fvol = 0.2 else fvol = 0.5 end
        elseif psurface.material == MAT_METAL then
            if bWalking then fvol = 0.2 else fvol = 0.5 end
        elseif psurface.material == MAT_DIRT then
            if bWalking then fvol = 0.25 else fvol = 0.55 end
        elseif psurface.material == MAT_VENT then
            if bWalking then fvol = 0.4 else fvol = 0.7 end
        elseif psurface.material == MAT_GRATE then
            if bWalking then fvol = 0.2 else fvol = 0.5 end
        elseif psurface.material == MAT_TILE then
            if bWalking then fvol = 0.2 else fvol = 0.5 end
        elseif psurface.material == MAT_SLOSH then
            if bWalking then fvol = 0.2 else fvol = 0.5 end
        else
            if bWalking then fvol = 0.2 else fvol = 0.5 end
        end
    end

	// play the sound
	// 65% volume if ducking
	if ply:Crouching() then
		fvol = fvol * 0.65
    end
    

	PlayStepSound(ply, vecOrigin, psurface, fvol, false)
end

hook.Add("Think", "bm_footstep_think", function()
    if not bm_vars.enabled:GetBool() or not bm_vars.slow_footsteps:GetBool() then return end

    if not game.SinglePlayer() and CLIENT then
        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        //lp:SetKeyValue("m_flStepSoundTime", 9999)
        UpdateStepSound(lp, GetGroundSurface(lp), lp:GetPos(), lp:GetVelocity())
    end

    if SERVER then
        for i, ply in ipairs(player.GetAll()) do 
            //ply:SetKeyValue("m_flStepSoundTime", 9999)
            UpdateStepSound(ply, GetGroundSurface(ply), ply:GetPos(), ply:GetVelocity())
        end
    end
end)

hook.Add("OnPlayerHitGround", "bm_fix_weirdness", function(ply, inwater, onfloater, speed) 
    local fmaxspeed = math.abs(ply:GetVelocity().z)
    local exp = bm_vars.steptime.exponent:GetFloat()
    local mult = bm_vars.steptime.multiplier:GetFloat()
    local offset = bm_vars.steptime.offset:GetFloat()
    local fsteptime = (fmaxspeed^exp/fmaxspeed)*mult + offset
    
    if not fsteptime then fsteptime = 100 end
    if fsteptime != fsteptime then fsteptime = 100 end

    fsteptime = math.Clamp(fsteptime, bm_vars.steptime.min:GetFloat(), bm_vars.steptime.max:GetFloat())

    ply.m_flStepSoundTime = (ply.m_flStepSoundTime or 0) + fsteptime
end)

if not game.SinglePlayer() and CLIENT then
    net.Receive("bm_footstep", function(len)
        local ply = net.ReadEntity()
        local vecOrigin = net.ReadVector()
        local foot = net.ReadFloat()
        local path = net.ReadString()
        local fvol = net.ReadFloat()

        if ply == LocalPlayer() then return end // we're calculating our own footsteps #swag

        if hook.Run("PlayerFootstep", ply, vecOrigin, path, foot, fvol, nil) == nil then
            ply:EmitSound(path, 75, 100, fvol, CHAN_BODY, 0, 0)
            //EmitSound(path, vecOrigin, ply:EntIndex(), CHAN_BODY, fvol, 75, SND_NOFLAGS, 100, 0)
        end
    end)
end

hook.Add("PlayerFootstep", "bm_sync_foot", function(ply, pos, foot, ...) 
    ply.m_nStepside = foot
end)