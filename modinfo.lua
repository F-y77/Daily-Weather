name = "每日天气"
description = "每天白天检测今日天气，如果晴天提升10%的移速，如果雨天降低10%的移速，如果下雪降低15%的移速。"
author = "橙小幸"
version = "0.3"
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
