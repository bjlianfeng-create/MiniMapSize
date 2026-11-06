# 小地图尺寸 · MiniMapSize

一个给《魔兽世界》用的轻量小地图尺寸调节插件：在「界面设置 → 插件」里拖滑块就能改大小，不需要记命令。

> **直接下载**：[最新安装包（zip）](https://github.com/bjlianfeng-create/MiniMapSize/releases/latest)
> 解压后把 `MiniMapSize` 文件夹放进 `World of Warcraft\_<版本目录>_\Interface\AddOns\` 即可。

## 功能

- **滑块调节** 80 – 320（默认 140），拖动即时生效，登出后保留
- **整体等比缩放**：缩的是整个 `MinimapCluster`，圆形边框、追踪按钮、时钟、周边插件图标会一起变化，不会出现「地图变大了但金属边框还在原尺寸」的错位
- **与 NDui 共存**：检测到 NDui 正在接管小地图时自动让位（避免两层缩放叠加），也可以在设置里勾选强制使用本插件
- **零依赖**，不修改任何游戏文件，卸载即恢复

## 安装

1. 下载本仓库，把整个 `MiniMapSize` 文件夹放进：
   ```
   World of Warcraft\_<版本目录>_\Interface\AddOns\
   ```
2. 重启游戏（不是 `/reload`）
3. 角色选择界面左下角「插件」→ 勾选 **小地图尺寸**
4. 进游戏后：**界面设置 → 插件 → 小地图尺寸**

## 命令

| 命令 | 作用 |
|---|---|
| `/mms` | 查看当前尺寸、生效方式、用法 |
| `/mms 180` | 设为 180（范围 80–320） |
| `/mms reset` | 恢复默认 140 |
| `/mms status` | 尺寸 / 生效方式 / 缩放倍率 / NDui 接管状态 |
| `/mms force` | 切换「强制使用本插件（忽略 NDui）」 |
| `/mms version` | 查看版本与作者 |

## 兼容性

| 项目 | 情况 |
|---|---|
| 测试客户端 | 《魔兽世界：无限》（flavor `Camelot`，`## Interface: 16001`） |
| 其它经典版本 | 未测试，理论上 `MinimapCluster` 存在的版本都可用 |
| 设置界面 | 使用新版 `Settings.*` API；老客户端会自动退回命令方式 |

## 实现说明

游戏里的小地图不是单一帧：圆形边框、指针、缩放按钮、时钟都是独立子对象。只改 `Minimap:SetSize` 会让它们错位，所以本插件缩放的是它们的共同父级 `MinimapCluster`（`size / 140`），一步到位。

检测到 NDui 时（`NDuiADB["Map"]["DisableMinimap"] ~= true`）自动让位，因为 NDui 自己会对 `Minimap` 执行 `SetSize` + `SetScale`，两者同时生效会变成双重放大。

## 作者

**火药** · v1.1.0

## 许可

MIT
