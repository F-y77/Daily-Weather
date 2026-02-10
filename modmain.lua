-- 设置全局环境
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 获取配置
local WEATHER_CHANGE_FREQ = GetModConfigData("weather_change_frequency")
local BUFF_INTENSITY = GetModConfigData("buff_intensity")

-- 天气类型定义（只包含游戏中真实存在的天气效果）
local WEATHER_TYPES = {
    SUNNY = {
        name = "晴天",
        weather = "clear",
        buff = function(inst)
            -- 晴天：移动速度提升
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "weather_buff", 1 + 0.1 * BUFF_INTENSITY)
        end,
        color = {1, 1, 0.8}
    },
    RAINY = {
        name = "雨天",
        weather = "rain",
        precipitation_rate = 0.5,
        buff = function(inst)
            -- 雨天：移动减慢，理智消耗增加
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "weather_buff", 1 - 0.05 * BUFF_INTENSITY)
            if inst.components.sanity then
                inst.components.sanity.night_drain_mult = 1 + 0.2 * BUFF_INTENSITY
            end
        end,
        color = {0.5, 0.5, 0.8}
    },
    STORMY = {
        name = "暴风雨",
        weather = "storm",
        precipitation_rate = 1.0,
        has_lightning = true,
        buff = function(inst)
            -- 暴风雨：攻击力提升但理智下降快
            if inst.components.combat then
                inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1 + 0.2 * BUFF_INTENSITY, "weather_buff")
            end
            if inst.components.sanity then
                inst.components.sanity.night_drain_mult = 1 + 0.5 * BUFF_INTENSITY
            end
        end,
        color = {0.3, 0.3, 0.5}
    },
    SNOWY = {
        name = "下雪",
        weather = "snow",
        precipitation_rate = 0.5,
        buff = function(inst)
            -- 下雪：体温下降快，但食物保鲜时间延长
            if inst.components.temperature then
                inst.components.temperature.inherentinsulation = -20 * BUFF_INTENSITY
            end
            if inst.components.hunger then
                inst.components.hunger.burnrate = 1 - 0.1 * BUFF_INTENSITY
            end
        end,
        color = {0.7, 0.8, 1}
    },
}

-- 当前天气
local current_weather = nil
local weather_timer = 0

-- 清除buff
local function ClearWeatherBuff(inst)
    if inst.components.locomotor then
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "weather_buff")
    end
    if inst.components.combat then
        inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "weather_buff")
        inst.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "weather_buff")
    end
    if inst.components.sanity then
        inst.components.sanity.night_drain_mult = 1
    end
    if inst.components.temperature then
        inst.components.temperature.inherentinsulation = 0
    end
end

-- 应用天气buff
local function ApplyWeatherBuff(inst, weather_data)
    ClearWeatherBuff(inst)
    if weather_data and weather_data.buff then
        weather_data.buff(inst)
    end
end

-- 改变天气
local function ChangeWeather()
    local world = TheWorld
    if not world then return end
    
    -- 随机选择新天气
    local weather_keys = {}
    for k, v in pairs(WEATHER_TYPES) do
        table.insert(weather_keys, k)
    end
    
    local new_weather_key = weather_keys[math.random(#weather_keys)]
    current_weather = WEATHER_TYPES[new_weather_key]
    
    -- 改变世界天气
    if world.net and world.net.components.weather then
        local weather_component = world.net.components.weather
        
        -- 先停止所有天气效果
        weather_component:SetPrecipitationRate(0)
        if world.components.worldlightning then
            world.components.worldlightning:StopLightningStorm()
        end
        
        -- 根据天气类型设置对应效果
        if current_weather.weather == "clear" then
            -- 晴天：停止降水
            world:PushEvent("ms_forceprecipitation", false)
            
        elseif current_weather.weather == "rain" then
            -- 雨天：开始下雨
            world:PushEvent("ms_forceprecipitation", true)
            weather_component:SetPrecipitationRate(current_weather.precipitation_rate or 0.5)
            
        elseif current_weather.weather == "storm" then
            -- 暴风雨：下雨 + 闪电
            world:PushEvent("ms_forceprecipitation", true)
            weather_component:SetPrecipitationRate(current_weather.precipitation_rate or 1.0)
            if current_weather.has_lightning and world.components.worldlightning then
                world.components.worldlightning:StartLightningStorm()
            end
            
        elseif current_weather.weather == "snow" then
            -- 下雪
            world:PushEvent("ms_forceprecipitation", true)
            weather_component:SetPrecipitationRate(current_weather.precipitation_rate or 0.5)
        end
    end
    
    -- 通知所有玩家并应用buff
    for i, player in ipairs(AllPlayers) do
        if player and player:IsValid() then
            ApplyWeatherBuff(player, current_weather)
            if player.components.talker then
                player.components.talker:Say("天气变为：" .. current_weather.name)
            end
        end
    end
    
    print("[每日天气] 天气改变为：" .. current_weather.name .. " (类型: " .. current_weather.weather .. ")")
end

-- 玩家生成时应用buff
AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoPeriodicTask(TUNING.TOTAL_DAY_TIME / WEATHER_CHANGE_FREQ, function()
        ChangeWeather()
    end)
    
    -- 初始天气
    inst:DoTaskInTime(1, ChangeWeather)
end)

-- 玩家加入时应用当前天气buff
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if current_weather then
            ApplyWeatherBuff(inst, current_weather)
        end
    end)
end)

-- 添加天气显示UI（可选）
AddClassPostConstruct("widgets/controls", function(self)
    if not self.weather_text then
        self.weather_text = self:AddChild(Text(BUTTONFONT, 30))
        self.weather_text:SetPosition(0, -200, 0)
        self.weather_text:SetRegionSize(400, 50)
        self.weather_text:SetHAlign(ANCHOR_MIDDLE)
        
        self.inst:DoPeriodicTask(1, function()
            if current_weather then
                self.weather_text:SetString("当前天气：" .. current_weather.name)
                self.weather_text:SetColour(unpack(current_weather.color))
            end
        end)
    end
end)
