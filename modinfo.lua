local MOD_VERSION = "1.0.0"

name = "每日天气"
description = [[每天检测天气并给予多种Buff效果。

版本: ]]..MOD_VERSION..[[

3种天气 × 3种Buff = 9种效果组合
支持强大模式，每个时间段都检测天气
可自定义Buff数量和强度

推荐开荒使用]]

author = "橙小幸"
version = MOD_VERSION
forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
client_only_mod = false
server_only_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"daily_weather", "每日天气", "橙小幸"}

local function Title(title)
    return {
        name = title,
        hover = "",
        options = {{description = "", data = 0}},
        default = 0,
    }
end

configuration_options = {
    Title("========== 基础设置 =========="),
    {
        name = "powerful_mode",
        label = "强大模式",
        hover = "开启后会在白天、黄昏、夜晚每个时间段都检查天气",
        options = {
            {description = "开启", data = true},
            {description = "关闭", data = false},
        },
        default = true,
    },
    {
        name = "show_message",
        label = "显示消息",
        hover = "是否在聊天框显示天气播报",
        options = {
            {description = "显示", data = true},
            {description = "隐藏", data = false},
        },
        default = true,
    },
    Title(""),
    Title("========== Buff设置 =========="),
    {
        name = "buff_count",
        label = "Buff数量",
        hover = "每次天气给予的Buff效果数量",
        options = {
            {description = "1个", data = 1},
            {description = "2个", data = 2},
            {description = "3个", data = 3},
        },
        default = 2,
    },
    {
        name = "buff_intensity",
        label = "Buff强度",
        hover = "Buff效果的强度倍率",
        options = {
            {description = "弱 (0.5倍)", data = 0.5},
            {description = "正常 (1倍)", data = 1},
            {description = "强 (1.5倍)", data = 1.5},
            {description = "很强 (2倍)", data = 2},
        },
        default = 1,
    },
    Title(""),
    Title("========== 天气效果 =========="),
    Title("晴天: 移速↑ 理智↑ 工作效率↑"),
    Title("雨天: 移速↓ 理智↓ 饥饿↓"),
    Title("雪天: 移速↓ 体温↓ 攻击↓"),
    Title(""),
    Title("========== 模组信息 =========="),
    Title("版本: "..MOD_VERSION.." | 天气: 3种"),
    Title("Buff效果: 9种组合"),
    Title("祝大家新年快乐，恭喜发财。"),
    Title("作者：橙小幸"),
    Title("Q群:1042944194 欢迎联机交流。"),
    Title("感谢您的大力支持！")
}
