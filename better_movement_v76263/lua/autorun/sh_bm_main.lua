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
        unduck = CreateConVar("sv_bm_speed_unduck", 0.3, flags, "Unduck Speed"),
        ladder = CreateConVar("sv_bm_speed_ladder", 100, flags, "Ladder Speed"),
        water = CreateConVar("sv_bm_speed_water", 1, flags, "Water Speed Multiplier"),
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
    slow_footsteps = CreateConVar("sv_bm_slow_footsteps", 0, flags, "Force Slow Footsteps Toggle"),
    animevent_footsteps = CreateConVar("sv_bm_animevent_footsteps", 0, flags, "Animation Based Footsteps Toggle"),
    animevent_footsteps_type = CreateConVar("sv_bm_animevent_footsteps_type", 1, flags, "0 - regular traces, 1 - obb interesction test against player origin (basically works better on slopes)"),
    animevent_footsteps_offset = CreateConVar("sv_bm_animevent_footsteps_offset", 8, flags, "Foot offset if the type is 1"),
    remove_weapon_hooks = CreateConVar("sv_bm_remove_weapon_hooks", 0, flags, "Remove weapon hooks that affect your speed."),
    controller_support = CreateConVar("sv_bm_controller_support", 0, flags, "Controller support. Breaks some mods."),
}

local bm_vars = bm_vars

local SINGLEPLAYER = game.SinglePlayer()
local FANCY_INTERPOLATION = 0
local LINEAR_INTERPOLATION = 1

local ANIMEVENT_TRACE = 0
local ANIMEVENT_INTERSECT = 1

// I'm fairly sure NW2 lets you have way more variables than traditional datatables, even though
// nw2 is networked through datatables itself, i could be very wrong though

function NW2AccessorFunc(tab, varname, name, iForce)
    if (!tab) then debug.Trace() end

    if (iForce == FORCE_STRING) then
        tab["Set" .. name] = function(self, v)
            self:SetNW2String(varname, v)
        end

        tab["Get" .. name] = function(self, v) 
            return self:GetNW2String(varname)
        end

        return 
    end

    if (iForce == FORCE_NUMBER) then
        tab["Set" .. name] = function(self, v)
            self:SetNW2Float(varname, v)
        end

        tab["Get" .. name] = function(self, v) 
            return self:GetNW2Float(varname)
        end

        return 
    end

    if (iForce == FORCE_BOOL) then
        tab["Set" .. name] = function(self, v) 
            self:SetNW2Bool(varname, v)
        end

        tab["Get" .. name] = function(self, v) 
            return self:GetNW2Bool(varname)
        end

        return 
    end

    if (iForce == FORCE_ANGLE) then
        tab["Set" .. name] = function(self, v) 
            self:SetNW2Angle(varname, v)
        end

        tab["Get" .. name] = function(self, v) 
            return self:GetNW2Angle(varname)
        end

        return 
    end

    if (iForce == FORCE_VECTOR) then
        tab["Set" .. name] = function(self, v)
            self:SetNW2Vector(varname, v)
        end

        tab["Get" .. name] = function(self, v)
            return self:GetNW2Vector(varname)
        end

        return 
    end
end

local player_meta = FindMetaTable("Player")

NW2AccessorFunc(player_meta, "bm_in_speed_count", "BmInSpeedCount", FORCE_NUMBER)

NW2AccessorFunc(player_meta, "bm_mouse_slowdown", "BmMouseSlowdown", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_weakness", "BmWeakness", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_slowdown_on_hit", "BmSlowdownOnHit", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_in_speed_time", "BmInSpeedTime", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_env_check_timeout", "BmEnvCheckTimeout", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_env_slowdown", "BmEnvSlowdown", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_lerped_forwardmove", "BmLerpedForwardMove", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_lerped_sidemove", "BmLerpedSideMove", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_new_maxspeed", "BmNewMaxSpeed", FORCE_NUMBER)
NW2AccessorFunc(player_meta, "bm_fraction", "BmFraction", FORCE_NUMBER)

NW2AccessorFunc(player_meta, "bm_previous_origin", "BmPreviousOrigin", FORCE_VECTOR)
NW2AccessorFunc(player_meta, "bm_current_origin", "BmCurrentOrigin", FORCE_VECTOR)

NW2AccessorFunc(player_meta, "bm_in_boosted_run", "BmInBoostedRun", FORCE_BOOL)
NW2AccessorFunc(player_meta, "bm_env_is_inside", "BmEnvIsInside", FORCE_BOOL)
NW2AccessorFunc(player_meta, "bm_was_on_ground", "BmWasOnGround", FORCE_BOOL)
NW2AccessorFunc(player_meta, "bm_on_ground", "BmOnGround", FORCE_BOOL)

local function traceable_to_sky(pos, offset)
    local tr = util.TraceLine({start=pos + offset, endpos=pos + offset + vector_up * 56688, mask=MASK_NPCWORLDSTATIC})
    local temp = util.TraceLine({start=tr.StartPos, endpos=pos, mask=MASK_NPCWORLDSTATIC})
    if temp.HitPos == pos and not temp.StartSolid and tr.HitSky then return true end
    return false
end

local __v1 = Vector(0, 0, 0)
local __v2 = Vector(120, 0, 0)
local __v3 = Vector(0, 120, 0)
local __v4 = Vector(-120, 0, 0)
local __v5 = Vector(0, -120, 0)

local function get_env_state(pos)
    local tr_1 = traceable_to_sky(pos, __v1)
    local tr_2 = traceable_to_sky(pos, __v2)
    local tr_3 = traceable_to_sky(pos, __v3)
    local tr_4 = traceable_to_sky(pos, __v4)
    local tr_5 = traceable_to_sky(pos, __v5)
    if (tr_1 or tr_2 or tr_3 or tr_4 or tr_5) then return false else return true end
end

local function arse(ply, start, endd)
    if bm_vars.interpolation_type:GetInt() == LINEAR_INTERPOLATION then return 1 end

    local thing = math.abs(start - endd)

    if thing > 0 and thing < 0.1 then
        thing = 0
    end

    thing = thing / bm_vars.speed.run:GetFloat()

    if thing < 0.2 then
        thing = thing
    end

    thing = math.Clamp(thing, 0.4 + ply:GetBmMouseSlowdown() * 0.3, 1)

    return math.ease.InOutExpo(thing * 0.75)
end

local function initialize_bm(ply)
    ply:SetBmMouseSlowdown(1)
    ply:SetBmPreviousOrigin(ply:GetPos())
    ply:SetBmCurrentOrigin(ply:GetPos())
    ply:SetBmWeakness(0)
    ply:SetBmSlowdownOnHit(1)
    ply:SetBmInSpeedTime(0)
    ply:SetBmInSpeedCount(0)
    ply:SetBmInBoostedRun(false)
    ply:SetBmEnvCheckTimeout(0)
    ply:SetBmEnvIsInside(get_env_state(ply:GetPos() + vector_up * 40))
    ply:SetBmEnvSlowdown(1)
    ply:SetBmMouseSlowdown(1)
    ply:SetBmLerpedForwardMove(0)
    ply:SetBmLerpedSideMove(0)
    ply:SetBmNewMaxSpeed(ply:GetMaxSpeed())
    ply:SetBmWasOnGround(ply:OnGround())
    ply:SetBmOnGround(ply:OnGround())
    ply:SetBmFraction(0)
end

if SERVER then
    hook.Add("PlayerSpawn", "bm_init", function(ply, transition)
        initialize_bm(ply)
    end)
end

if CLIENT then
    hook.Add("InitPostEntity", "bm_init", function()
        initialize_bm(LocalPlayer())
    end)
end

hook.Add("SetupMove", "bm_setupmove", function(ply, mv, cmd)
    if not bm_vars.enabled:GetBool() then return end

    local maxspeed = ply:GetMaxSpeed()

    local forwardmove = cmd:GetForwardMove()
    local sidemove = cmd:GetSideMove()

    if bm_vars.controller_support:GetBool() then
        forwardmove = forwardmove / 10000 * maxspeed
        sidemove = sidemove / 10000 * maxspeed
    else
        forwardmove = math.Clamp(forwardmove, -maxspeed, maxspeed)
        sidemove = math.Clamp(sidemove, -maxspeed, maxspeed)
    end

    if bm_vars.slowdown.non_forward:GetBool() then
        local nf_mult = bm_vars.slowdown.non_forward_multiplier:GetFloat()

        sidemove = sidemove * 0.75 * nf_mult

        if forwardmove < 0 then
            forwardmove = forwardmove * 0.75 * nf_mult
            maxspeed = maxspeed * 0.75 * nf_mult
        end
    end

    local origin = mv:GetOrigin()
    local onground = ply:OnGround()
    local waterlevel = ply:WaterLevel()

    // handle weakness
    if bm_vars.slowdown.weakness_enabled:GetBool() then
        ply:SetBmPreviousOrigin(ply:GetBmCurrentOrigin())
        ply:SetBmCurrentOrigin(origin)

        local diff = ply:GetBmCurrentOrigin() - ply:GetBmPreviousOrigin()

        local weakness = ply:GetBmWeakness()

        if diff.z > 0 and onground then
            weakness = weakness + diff.z / 20 * bm_vars.slowdown.weakness_multiplier:GetFloat()
        end

        if math.abs(forwardmove) + math.abs(sidemove) > 0.1 then
            weakness = weakness + FrameTime() * 10.1 * bm_vars.slowdown.weakness_multiplier:GetFloat() * (maxspeed / bm_vars.speed.run:GetFloat())
        end

        weakness = math.Clamp(weakness - FrameTime() * 9 * bm_vars.slowdown.weakness_rest_multiplier:GetFloat(), 0, 128)

        ply:SetBmWeakness(weakness)

        local cw_thing = (1 - ply:GetBmWeakness() / 128 * 0.5)

        forwardmove = forwardmove * cw_thing
        sidemove = sidemove * cw_thing
        maxspeed = maxspeed * cw_thing
    end

    // handle slowdown on landing
    if bm_vars.slowdown.landing:GetBool() then
        if ply:GetBmSlowdownOnHit() < 0.999 then
            ply:SetBmSlowdownOnHit(
                Lerp(FrameTime() + math.abs(ply:GetBmSlowdownOnHit() - 1) * FrameTime() * 50,
                    ply:GetBmSlowdownOnHit(),
                    1
               )
           )
        else
            ply:SetBmSlowdownOnHit(1)
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
        ply:SetBmInSpeedTime(0.3)
        ply:SetBmInSpeedCount(ply:GetBmInSpeedCount() + 1)
    end

    if ply:GetBmInSpeedCount() >= 2 then
        ply:SetBmInBoostedRun(true)
    else
        ply:SetBmInBoostedRun(false)
    end

    if not mv:KeyDown(IN_SPEED) and ply:GetBmInSpeedTime() <= 0 then
        ply:SetBmInSpeedCount(0)
    end

    ply:SetBmInSpeedTime(math.max(ply:GetBmInSpeedTime() - FrameTime(), 0))

    // handle being inside
    if bm_vars.inside_checks_enabled:GetBool() then
        ply:SetBmEnvCheckTimeout(math.max(ply:GetBmEnvCheckTimeout() - FrameTime(), 0))

        if ply:GetBmEnvCheckTimeout() <= 0 and mv:GetVelocity():Length() > 0 then
            ply:SetBmEnvIsInside(get_env_state(mv:GetOrigin() + vector_up * 40))
            ply:SetBmEnvCheckTimeout(bm_vars.inside_checks_period:GetFloat() + math.random(-0.5, 0.5))
        end

        if ply:GetBmEnvIsInside() and not ply:GetBmInBoostedRun() then
            ply:SetBmEnvSlowdown(Lerp(FrameTime() * 3, ply:GetBmEnvSlowdown(), bm_vars.speed.inside_multiplier:GetFloat()))
        else
            ply:SetBmEnvSlowdown(Lerp(FrameTime() * 3, ply:GetBmEnvSlowdown(), 1))
        end

        local slowdown = ply:GetBmEnvSlowdown()

        forwardmove = forwardmove * slowdown
        sidemove = sidemove * slowdown
        maxspeed = maxspeed * slowdown
    end

    // handle turn slowdown
    if bm_vars.slowdown.turn_enabled:GetBool() then
        local mult = math.max(bm_vars.slowdown.turn_multiplier:GetFloat(), 0.05)
        local factor = math.Remap(math.Clamp(math.abs(cmd:GetMouseX() / 20), 0, 50), 0, 50, 1, (1-mult))
        ply:SetBmMouseSlowdown(Lerp(FrameTime() * 50, ply:GetBmMouseSlowdown(), factor))
    end

    // handle being in air
    if not onground and bm_vars.slowdown.in_air:GetBool() and waterlevel < 2 then
        forwardmove = forwardmove * 0.1
        sidemove = sidemove * 0.1
    end

    // water speed
    if waterlevel >= 2 then
        forwardmove = forwardmove * bm_vars.speed.water:GetFloat()
        sidemove = sidemove * bm_vars.speed.water:GetFloat()
        mv:SetUpSpeed(mv:GetUpSpeed() * bm_vars.speed.water:GetFloat())
        cmd:SetUpMove(cmd:GetUpMove() * bm_vars.speed.water:GetFloat())
    end

    // lerp everything
    local mult = bm_vars.interpolation_multiplier:GetFloat()
    local more_slowdown = ply:GetBmMouseSlowdown() * ply:GetBmSlowdownOnHit()

    maxspeed = maxspeed * more_slowdown

    local early_speed = math.sqrt(math.abs(forwardmove)^2 + math.abs(sidemove)^2)
    if early_speed > maxspeed then
        forwardmove = forwardmove * maxspeed / early_speed
        sidemove = sidemove * maxspeed / early_speed
    end

    ply:SetBmLerpedForwardMove(Lerp(FrameTime() * 10 * mult * arse(ply, ply:GetBmLerpedForwardMove(), forwardmove), ply:GetBmLerpedForwardMove(), forwardmove) * more_slowdown)
    ply:SetBmLerpedSideMove(Lerp(FrameTime() * 10 * mult * arse(ply, ply:GetBmLerpedSideMove(), sidemove), ply:GetBmLerpedSideMove(), sidemove) * more_slowdown)

    if math.abs(ply:GetBmLerpedForwardMove()) < 0.01 then
        ply:SetBmLerpedForwardMove(0)
    end

    if math.abs(ply:GetBmLerpedSideMove()) < 0.01 then
        ply:SetBmLerpedSideMove(0)
    end

    local _forward = ply:GetBmLerpedForwardMove()
    local _side = ply:GetBmLerpedSideMove()

    local maxspeed_raw = math.sqrt(_side^2 + _forward^2)

    ply:SetBmNewMaxSpeed(maxspeed_raw)

    // apply it all
    local walktype = "walk"
    if mv:KeyDown(IN_SPEED) then walktype = "run" end
    if mv:KeyDown(IN_WALK) then walktype = "slowwalk" end

    local fraction = math.Clamp(maxspeed_raw / maxspeed, 1, 2)
    ply:SetBmFraction(Lerp(FrameTime() * 20, ply:GetBmFraction(), fraction))

    local _bmfraction = ply:GetBmFraction()

    ply:SetWalkSpeed(bm_vars.speed.walk:GetFloat() * _bmfraction)
    ply:SetRunSpeed(bm_vars.speed.run:GetFloat() * _bmfraction)
    ply:SetSlowWalkSpeed(bm_vars.speed.slowwalk:GetFloat() * _bmfraction)
    ply:SetLadderClimbSpeed(bm_vars.speed.ladder:GetFloat())
    ply:SetCrouchedWalkSpeed(bm_vars.speed.crouch:GetFloat())

    if ply:GetMoveType() == MOVETYPE_WALK then
        mv:SetForwardSpeed(_forward)
        mv:SetSideSpeed(_side)
        cmd:SetForwardMove(_forward)
        cmd:SetSideMove(_side)
    end

    // reduce air velocity to prevent bhopping
    ply:SetBmWasOnGround(ply:GetBmOnGround())
    ply:SetBmOnGround(ply:OnGround())

    if ply:GetBmWasOnGround() != ply:GetBmOnGround() and mv:KeyDown(IN_JUMP) and !ply:GetBmOnGround() and ply:WaterLevel() < 3 then
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
    if not bm_vars.enabled:GetBool() or not bm_vars.slowdown.landing:GetBool() then return end

    ply:SetBmSlowdownOnHit(0)
end)


hook.Add("PlayerStepSoundTime", "bm_stepsoundtime_slow", function(ply, iType, bWalking)
    if not bm_vars.enabled:GetBool() or not bm_vars.slow_footsteps:GetBool() then return end

    return math.huge
end)

function BmGetStepSoundTime(ply, iType, bWalking)
    local fmaxspeed = ply:GetBmNewMaxSpeed()

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

hook.Add("PlayerStepSoundTime", "bm_stepsoundtime_normal", function(ply, iType, bWalking)
    if bm_vars.slow_footsteps:GetBool() then return end

    if not bm_vars.enabled:GetBool() then return end

    if ply:InVehicle() then return end

    return BmGetStepSoundTime(ply, iType, bWalking)
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

local material_types = {
	[65] = "ANTLION",
	[66] = "BLOODYFLESH",
	[67] = "CONCRETE",
	[68] = "DIRT",
	[69] = "EGGSHELL",
	[70] = "FLESH",
	[71] = "GRATE",
	[72] = "ALIENFLESH",
	[73] = "CLIP",
	[74] = "SNOW",
	[76] = "PLASTIC",
	[77] = "METAL",
	[78] = "SAND",
	[79] = "FOLIAGE",
	[80] = "COMPUTER",
	[83] = "SLOSH",
	[84] = "TILE",
	[85] = "GRASS",
	[86] = "VENT",
	[87] = "WOOD",
	[88] = "DEFAULT",
	[89] = "GLASS",
	[90] = "WARPSHIELD"
}

local function GetGroundSurface(ply, isAnimEvent)
    local vecOrigin = ply:GetPos()

    local _data = {
        start = vecOrigin,
        endpos = vecOrigin - vector_up * 64,
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        filter = ply,
        mask = MASK_PLAYERSOLID,
        collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
    }

    if not isAnimEvent then
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
    end

    local tr = util.TraceHull(_data)

    if tr.Fraction >= 1 then
        return nil
    end

    if tr.SurfaceProps == -1 then
        local typee = material_types[tr.MatType]

        if not typee then return nil end

        return util.GetSurfaceData(util.GetSurfaceIndex(string.lower(typee)))
    end

    return util.GetSurfaceData(tr.SurfaceProps)
end

local function PlayStepSound(ply, vecOrigin, psurface, fvol, force, isAnimEvent, animStepSide)
    if not SINGLEPLAYER and not sv_footsteps:GetBool() then return end

    if not psurface then return end

    if not isAnimEvent and ply.m_nStepside == 0 then stepSoundName = psurface.stepLeftSound else stepSoundName = psurface.stepRightSound end

	if !stepSoundName then return end

    if not isAnimEvent and ply.m_nStepside == 0 then ply.m_nStepside = 1 else ply.m_nStepside = 0 end

    if isAnimEvent then
        ply.m_nStepside = animStepSide
    end

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
            end
            net.Start("bm_footstep")
                net.WriteEntity(ply)
                net.WriteVector(vecOrigin)
                net.WriteFloat(ply.m_nStepside)
                net.WriteString(path)
                net.WriteFloat(fvol)
            net.SendPAS(vecOrigin)
        end

        // can be here only if it's multiplayer and we are a client
        // otherwise we let the server do the work
        if CLIENT then
            if hook.Run("PlayerFootstep", ply, vecOrigin, ply.m_nStepside, path, fvol, nil) == nil then
                ply:EmitSound(path, 75, 100, fvol, CHAN_BODY, 0, 0)
            end
        end
    end
end

local function UpdateStepSound(ply, psurface, vecOrigin, vecVelocity, isAnimEvent, animStepSide)
	local bWalking
	local fvol
	local speed
	local velrun
	local velwalk
	local fLadder
    local movetype = ply:GetMoveType()
    local flags = ply:GetFlags()
    local waterlevel = ply:WaterLevel()

    if not isAnimEvent then
        if (ply.m_flStepSoundTime or 0) > 0 then
            ply.m_flStepSoundTime = ply.m_flStepSoundTime - 1000 * engine.TickInterval()
            if ply.m_flStepSoundTime < 0 then
                ply.m_flStepSoundTime = 0
            end
        end

        if (ply.m_flStepSoundTime or 0) > 0 then return end
    end

    if bit.band(flags, FL_FROZEN) == FL_FROZEN or bit.band(flags, FL_ATCONTROLS) == FL_ATCONTROLS then
        return
    end

    if movetype == MOVETYPE_NOCLIP or movetype == MOVETYPE_OBSERVER then return end

    if ply:InVehicle() then return end

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
        ply.m_flStepSoundTime = BmGetStepSoundTime(ply, STEPSOUNDTIME_ON_LADDER, bWalking) / 1.6
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
        ply.m_flStepSoundTime = BmGetStepSoundTime(ply, STEPSOUNDTIME_WATER_KNEE, bWalking)
	elseif waterlevel == 1 then
		psurface = GetFootstepSurface("water")
        if bWalking then fvol = 0.2 else fvol = 0.5 end

        ply.m_flStepSoundTime = BmGetStepSoundTime(ply, STEPSOUNDTIME_WATER_FOOT, bWalking)
	else
		if not psurface then return end

        ply.m_flStepSoundTime = BmGetStepSoundTime(ply, STEPSOUNDTIME_NORMAL, bWalking)

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

	PlayStepSound(ply, vecOrigin, psurface, fvol, false, isAnimEvent, animStepSide)
end

hook.Add("Tick", "bm_footstep_think", function()
    if not bm_vars.enabled:GetBool() or not bm_vars.slow_footsteps:GetBool() or bm_vars.animevent_footsteps:GetBool() then return end

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
        end
    end)
end

hook.Add("PlayerFootstep", "bm_sync_foot", function(ply, pos, foot, ...)
    ply.m_nStepside = foot
end)

local feet = {
    "ValveBiped.Bip01_L_Foot",
    "ValveBiped.Bip01_R_Foot"
}

local function UpdateStepSoundAnim(ply)
    if ply:GetMoveType() == MOVETYPE_LADDER then
        UpdateStepSound(ply, GetGroundSurface(ply, true), ply:GetPos(), ply:GetVelocity())
        return
    end

    for i, name in ipairs(feet) do
        local player_origin = ply:GetPos()

        local side = i == 1 and "left" or "right"

        local bone = ply:LookupBone(name)

        if not bone then continue end

        local matrix = ply:GetBoneMatrix(bone)

        if not matrix then continue end

        local foot_origin = matrix:GetTranslation()

        local maxs = Vector(2, 2, 2)
        local mins = maxs * -1

        local hit = false

        if bm_vars.animevent_footsteps_type:GetInt() == ANIMEVENT_TRACE then
            local distance_tr = util.TraceLine({
                start = player_origin,
                endpos = player_origin - vector_up * 8,
                filter = ply,
                mask = MASK_PLAYERSOLID,
                collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
            })

            local tr = util.TraceHull({
                start = foot_origin,
                endpos = foot_origin - vector_up * 4 - vector_up * distance_tr.StartPos:Distance(distance_tr.HitPos),
                maxs = maxs,
                mins = mins,
                filter = ply,
                mask = MASK_PLAYERSOLID,
                collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
            })

            hit = tr.Hit
        elseif bm_vars.animevent_footsteps_type:GetInt() == ANIMEVENT_INTERSECT then
            foot_origin.z = foot_origin.z - bm_vars.animevent_footsteps_offset:GetFloat()

            local intersection = util.IsOBBIntersectingOBB(foot_origin, angle_zero, maxs, mins, player_origin, angle_zero, Vector(-100, -100, -100), Vector(100, 100, 0), 0)

            debugoverlay.Box(player_origin, Vector(100, 100, 0), Vector(-100, -100, -100), FrameTime() * 2, Color(255, 0, 0, 10))
            debugoverlay.Box(foot_origin, maxs, mins, FrameTime() * 2, Color(255, 0, 0, 10))

            hit = intersection
        end

        if foot_origin.z - player_origin.z > 7.5 then
            hit = false
        end

        if not ply.bmsteps then
            ply.bmsteps = {}
        end

        if not ply.bmstepsdelay then
            ply.bmstepsdelay = {}
        end

        ply.bmstepsdelay[side] = math.max((ply.bmstepsdelay[side] or 0) - FrameTime(), 0)

        if hit and not ply.bmsteps[side] and ply.bmstepsdelay[side] <= 0 then
            ply.bmsteps[side] = true
            ply.bmstepsdelay[side] = 0.1

            UpdateStepSound(ply, GetGroundSurface(ply, true), ply:GetPos(), ply:GetVelocity(), true, i - 1)
        end

        if not hit then
            ply.bmsteps[side] = false
        end
    end
end

hook.Add("Tick", "bm_detect_step_anim", function()
    if not bm_vars.enabled:GetBool() or not bm_vars.animevent_footsteps:GetBool() or not bm_vars.slow_footsteps:GetBool() then return end

    if not game.SinglePlayer() and CLIENT then
        local lp = LocalPlayer()
        if not IsValid(lp) then return end

        lp:SetupBones()

        UpdateStepSoundAnim(lp)
    end

    if SERVER then
        for i, ply in ipairs(player.GetAll()) do
            UpdateStepSoundAnim(ply)
        end
    end
end)

// this, ironically, does not fix weirdness.
//hook.Add("OnPlayerHitGround", "bm_fix_weirdness", function(ply, inwater, onfloater, speed)
//    local fmaxspeed = math.abs(ply:GetVelocity().z)
//    local exp = bm_vars.steptime.exponent:GetFloat()
//    local mult = bm_vars.steptime.multiplier:GetFloat()
//    local offset = bm_vars.steptime.offset:GetFloat()
//    local fsteptime = (fmaxspeed^exp/fmaxspeed)*mult + offset
//
//    if not fsteptime then fsteptime = 100 end
//    if fsteptime != fsteptime then fsteptime = 100 end
//
//    fsteptime = math.Clamp(fsteptime, bm_vars.steptime.min:GetFloat(), bm_vars.steptime.max:GetFloat())
//
//    ply.m_flStepSoundTime = (ply.m_flStepSoundTime or 0) + fsteptime
//end)

timer.Simple(5, function()
    hook.Add("Think", "bm_remove_setupmove", function()
        if not bm_vars.remove_weapon_hooks:GetBool() or not bm_vars.enabled:GetBool() then return end
        hook.Remove("SetupMove", "ArcCW_SetupMove")
        hook.Remove("SetupMove", "tfa_setupmove")
        hook.Remove("SetupMove", "ArcticTacRP.SetupMove")
        hook.Remove("SetupMove", "ARC9.SetupMove")
        hook.Remove("Think", "bm_remove_setupmove")
    end)
end)