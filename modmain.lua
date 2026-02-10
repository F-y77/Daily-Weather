GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

print("[每日天气预报] 模组开始加载")

-- 获取配置
local BUFF_INTENSITY = GetModConfigData("buff_intensity") or 1

local current_weather = nil
local last_day = -1

-- 清除玩家buff
local function ClearWeatherBuff(inst)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "weather_buff")
    end
end

-- 应用天气buff到玩家
local function ApplyWeatherBuffToPlayer(player, weather_name)
    if not player or not player:IsValid() then return end
    
    ClearWeatherBuff(player)
    
    if weather_name == "晴天" then
        -- 晴天：移动速度提升
        if player.components.locomotor then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "weather_buff", 1 + 0.1 * BUFF_INTENSITY)
        end
    elseif weather_name == "雨天" then
        -- 雨天：移动减慢
        if player.components.locomotor then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "weather_buff", 1 - 0.1 * BUFF_INTENSITY)
        end
    elseif weather_name == "雪天" then
        -- 雪天：移动减慢更多
        if player.components.locomotor then
            player.components.locomotor:SetExternalSpeedMultiplier(player, "weather_buff", 1 - 0.15 * BUFF_INTENSITY)
        end
    end
    
    print("[每日天气] 已为玩家应用buff：" .. weather_name)
end

-- 应用天气buff到所有玩家
local function ApplyWeatherBuffToAllPlayers(weather_name)
    for i, player in ipairs(AllPlayers) do
        if player and player:IsValid() then
            ApplyWeatherBuffToPlayer(player, weather_name)
        end
    end
end

-- 检测当前真实天气
local function DetectCurrentWeather()
    local weather_name = "晴天"
    
    if TheWorld.state.israining then
        weather_name = "雨天"
        print("[每日天气] 检测到下雨，降水率：" .. tostring(TheWorld.state.precipitationrate))
    elseif TheWorld.state.issnowing then
        weather_name = "雪天"
        print("[每日天气] 检测到下雪")
    else
        print("[每日天气] 检测到晴天")
    end
    
    return weather_name
end

-- 播报天气
local function AnnounceWeather()
    -- 检测当前真实天气
    local weather_name = DetectCurrentWeather()
    current_weather = weather_name
    
    print("[每日天气] 当前天气：" .. weather_name)
    
    -- 应用玩家buff
    ApplyWeatherBuffToAllPlayers(weather_name)
    
    -- 通知玩家
    TheNet:Announce("================   每日天气预报   ================")
    TheNet:Announce("【今日天气】" .. weather_name)
    TheNet:Announce("====================================================")
end

-- 检查并触发每日天气
local function CheckDailyWeather()
    if not TheWorld.ismastersim then return end
    
    local current_day = TheWorld.state.cycles
    
    -- 新的一天开始，并且是白天
    if current_day ~= last_day and TheWorld.state.isday then
        last_day = current_day
        
        print("[每日天气] 检测到新的一天：第" .. current_day .. "天")
        
        -- 延迟3秒后播报天气
        TheWorld:DoTaskInTime(3, function()
            AnnounceWeather()
        end)
    end
end

-- 添加世界组件监听
AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end
    
    print("[每日天气] 世界初始化完成")
    
    -- 每30秒检查一次
    inst:DoPeriodicTask(30, CheckDailyWeather)
    
    -- 立即检查一次
    inst:DoTaskInTime(5, CheckDailyWeather)
end)

-- 玩家加入时应用当前天气buff
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(1, function()
        if current_weather then
            print("[每日天气] 新玩家加入，应用天气buff：" .. current_weather)
            ApplyWeatherBuffToPlayer(inst, current_weather)
        end
    end)
end)

print("[每日天气预报] 模组加载完成！")
