GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local BUFF_INTENSITY = GetModConfigData("buff_intensity") or 1
local POWERFUL_MODE = GetModConfigData("powerful_mode")
local SHOW_MESSAGE = GetModConfigData("show_message")
local BUFF_COUNT = GetModConfigData("buff_count") or 2

if POWERFUL_MODE == nil then POWERFUL_MODE = true end
if SHOW_MESSAGE == nil then SHOW_MESSAGE = true end

local current_weather = nil
local last_phase = ""
local last_day = -1

-- 天气Buff配置
local WEATHER_BUFFS = {
    ["晴天"] = {
        {name = "移动速度提升", value = 10, apply = function(inst, value)
            if inst.components.locomotor then
                inst.components.locomotor:SetExternalSpeedMultiplier(inst, "weather_buff_speed", 1 + value / 100)
            end
        end},
        {name = "理智恢复加快", value = 20, apply = function(inst, value)
            if inst.components.sanity then
                inst.components.sanity.dapperness = (inst.components.sanity.dapperness or 0) + value / 100
            end
        end},
        {name = "工作效率提升", value = 15, apply = function(inst, value)
            if inst.components.workmultiplier then
                inst.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, 1 + value / 100, "weather_buff")
                inst.components.workmultiplier:AddMultiplier(ACTIONS.MINE, 1 + value / 100, "weather_buff")
            end
        end},
    },
    ["雨天"] = {
        {name = "移动速度降低", value = 10, apply = function(inst, value)
            if inst.components.locomotor then
                inst.components.locomotor:SetExternalSpeedMultiplier(inst, "weather_buff_speed", 1 - value / 100)
            end
        end},
        {name = "理智消耗增加", value = 15, apply = function(inst, value)
            if inst.components.sanity then
                inst.components.sanity.night_drain_mult = (inst.components.sanity.night_drain_mult or 1) + value / 100
            end
        end},
        {name = "饥饿消耗降低", value = 10, apply = function(inst, value)
            if inst.components.hunger then
                inst.components.hunger.burnrate = (inst.components.hunger.burnrate or 1) * (1 - value / 100)
            end
        end},
    },
    ["雪天"] = {
        {name = "移动速度降低", value = 15, apply = function(inst, value)
            if inst.components.locomotor then
                inst.components.locomotor:SetExternalSpeedMultiplier(inst, "weather_buff_speed", 1 - value / 100)
            end
        end},
        {name = "体温下降加快", value = 20, apply = function(inst, value)
            if inst.components.temperature then
                inst.components.temperature.inherentinsulation = (inst.components.temperature.inherentinsulation or 0) - value
            end
        end},
        {name = "攻击力降低", value = 10, apply = function(inst, value)
            if inst.components.combat then
                inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1 - value / 100, "weather_buff")
            end
        end},
    },
}

local function ClearWeatherBuff(inst)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "weather_buff_speed")
    end
    if inst.components.sanity then
        inst.components.sanity.dapperness = 0
        inst.components.sanity.night_drain_mult = 1
    end
    if inst.components.temperature then
        inst.components.temperature.inherentinsulation = 0
    end
    if inst.components.combat then
        inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "weather_buff")
    end
    if inst.components.hunger then
        inst.components.hunger.burnrate = 1
    end
    if inst.components.workmultiplier then
        inst.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, "weather_buff")
        inst.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, "weather_buff")
    end
end

local function ApplyWeatherBuffToPlayer(player, weather_name, buff_list)
    if not player or not player:IsValid() then return end
    
    ClearWeatherBuff(player)
    
    if buff_list then
        for i, buff in ipairs(buff_list) do
            if buff.apply then
                local actual_value = buff.value * BUFF_INTENSITY
                buff.apply(player, actual_value)
            end
        end
    end
end

local function ApplyWeatherBuffToAllPlayers(weather_name, buff_list)
    for i, player in ipairs(AllPlayers) do
        if player and player:IsValid() then
            ApplyWeatherBuffToPlayer(player, weather_name, buff_list)
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

local function GetTemperatureDesc()
    local temp = TheWorld.state.temperature
    if temp >= 70 then
        return "炎热(" .. math.floor(temp) .. "°)"
    elseif temp >= 35 then
        return "温暖(" .. math.floor(temp) .. "°)"
    elseif temp >= 15 then
        return "适中(" .. math.floor(temp) .. "°)"
    elseif temp >= 0 then
        return "寒冷(" .. math.floor(temp) .. "°)"
    else
        return "极寒(" .. math.floor(temp) .. "°)"
    end
end

local function AnnounceWeather(phase_name)
    local weather_name = DetectCurrentWeather()
    current_weather = weather_name
    
    -- 获取该天气的所有buff
    local all_buffs = WEATHER_BUFFS[weather_name] or {}
    
    -- 根据配置选择buff数量
    local selected_buffs = {}
    local buff_count = math.min(BUFF_COUNT, #all_buffs)
    for i = 1, buff_count do
        table.insert(selected_buffs, all_buffs[i])
    end
    
    -- 应用buff到所有玩家
    ApplyWeatherBuffToAllPlayers(weather_name, selected_buffs)
    
    -- 播报消息
    if SHOW_MESSAGE then
        local temp_desc = GetTemperatureDesc()
        local buff_desc = ""
        
        for i, buff in ipairs(selected_buffs) do
            local actual_value = buff.value * BUFF_INTENSITY
            if i > 1 then
                buff_desc = buff_desc .. "，"
            end
            buff_desc = buff_desc .. buff.name .. actual_value .. "%"
        end
        
        TheNet:Announce("【每日天气】" .. phase_name .. "天气：" .. weather_name .. "，温度：" .. temp_desc)
        TheNet:Announce("【Buff效果】" .. buff_desc)
    end
end

local function CheckDailyWeather()
    if not TheWorld.ismastersim then return end
    
    if POWERFUL_MODE then
        -- 强大模式：检查每个时间段
        local current_phase = GetCurrentPhase()
        
        if current_phase ~= last_phase and current_phase ~= "未知" then
            last_phase = current_phase
            TheWorld:DoTaskInTime(3, function()
                AnnounceWeather(current_phase)
            end)
        end
    else
        -- 普通模式：只在每天白天检查一次
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
            local all_buffs = WEATHER_BUFFS[current_weather] or {}
            local selected_buffs = {}
            local buff_count = math.min(BUFF_COUNT, #all_buffs)
            for i = 1, buff_count do
                table.insert(selected_buffs, all_buffs[i])
            end
            ApplyWeatherBuffToPlayer(inst, current_weather, selected_buffs)
        end
    end)
end)
