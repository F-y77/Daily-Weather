name = "每日天气预报"
description = "每日天气系统，频繁改变世界天气并提供不同的buff效果"
author = "橙小幸"
version = "0.1"

forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"每日天气", "daily_weather"}

configuration_options = {
    {
        name = "weather_change_frequency",
        label = "天气变化频率",
        options = {
            {description = "很快", data = 1},
            {description = "快", data = 2},
            {description = "正常", data = 4},
            {description = "慢", data = 8},
        },
        default = 2,
    },
    {
        name = "buff_intensity",
        label = "Buff强度",
        options = {
            {description = "弱", data = 0.5},
            {description = "正常", data = 1},
            {description = "强", data = 1.5},
            {description = "很强", data = 2},
        },
        default = 1,
    },
}
