GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local BUFF_INTENSITY = GetModConfigData("buff_intensity") or 1
local POWERFUL_MODE = GetModConfigData("powerful_mode")
if POWERFUL_MODE == nil then POWERFUL_MODE = true end

local current_weather = nil
local last_phase = ""
local last_day = -1

local function ClearWeatherBuff(inst)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "weather_buff")
    end
end

local function ApplyWeatherBuffToPlayer(player, weather_name)
    if not player or not player:IsValid() then return end
    
    ClearWeatherBuff(player)
    
    if weather_name == "晴天" then
        if player.components.locomotor then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "weather_buff", 1 + 0.1 * BUFF_INTENSITY)
        end
    elseif weather_name == "雨天" then
        if player.components.locomotor then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "weather_buff", 1 - 0.1 * BUFF_INTENSITY)
        end
    elseif weather_name == "雪天" then
        if player.components.locomotor then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "weather_buff", 1 - 0.15 * BUFF_INTENSITY)
        end
    end
end

local function ApplyWeatherBuffToAllPlayers(weather_name)
    for i, player in ipairs(AllPlayers) do
        if player and player:IsValid() then
            ApplyWeatherBuffToPlayer(player, weather_name)
        end
    end
end

local function DetectCurrentWeather()
    if TheWorld.state.israining then
        return "雨天"
    elseif TheWorld.state.issnowing then
        return "雪天"
    else
        return "晴天"
    end
end

local function GetCurrentPhase()
    if TheWorld.state.isday then
        return "白天"
    elseif TheWorld.state.isdusk then
        return "黄昏"
    elseif TheWorld.state.isnight then
        return "夜晚"
    else
        return "未知"
    end
end

local function AnnounceWeather(phase_name)
    local weather_name = DetectCurrentWeather()
    current_weather = weather_name
    ApplyWeatherBuffToAllPlayers(weather_name)
    
    local buff_desc = ""
    if weather_name == "晴天" then
        local buff_value = 10 * BUFF_INTENSITY
        buff_desc = "移动速度提升" .. buff_value .. "%"
    elseif weather_name == "雨天" then
        local buff_value = 10 * BUFF_INTENSITY
        buff_desc = "移动速度降低" .. buff_value .. "%"
    elseif weather_name == "雪天" then
        local buff_value = 15 * BUFF_INTENSITY
        buff_desc = "移动速度降低" .. buff_value .. "%"
    end
    
    TheNet:Announce("【每日天气】" .. phase_name .. "天气：" .. weather_name .. "，给予Buff：" .. buff_desc)
end

local function CheckDailyWeather()
    if not TheWorld.ismastersim then return end
    
    if POWERFUL_MODE then

        local current_phase = GetCurrentPhase()
        
        if current_phase ~= last_phase and current_phase ~= "未知" then
            last_phase = current_phase
            TheWorld:DoTaskInTime(3, function()
                AnnounceWeather(current_phase)
            end)
        end
    else

        local current_day = TheWorld.state.cycles
        
        if current_day ~= last_day and TheWorld.state.isday then
            last_day = current_day
            TheWorld:DoTaskInTime(3, function()
                AnnounceWeather("今日")
            end)
        end
    end
end

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoPeriodicTask(30, CheckDailyWeather)
    inst:DoTaskInTime(5, CheckDailyWeather)
end)

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(1, function()
        if current_weather then
            ApplyWeatherBuffToPlayer(inst, current_weather)
        end
    end)
end)
