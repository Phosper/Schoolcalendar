# SchoolCalendar（鸿蒙课程表）

基于 HarmonyOS 6.1.0 / API 23 的 ArkTS 原生工程。设计依据是仓库中的《SchoolCalendar 产品设计文档》。

## 已实现

- 本地 RDB 存储课程、节次时间和学期；Preferences 保存主题与提醒设置。
- 课程添加、编辑、删除、冲突提示；全周、单双周、自定义周次；周视图、课程详情半模态、学期与作息设置。
- 10 套主题、跟随系统深色模式。
- 下一节课、今日课程、完整周课表三类桌面卡片，各支持两种尺寸；TextClock 分钟级状态重算，数据变更时主动推送，跨天定点刷新。
- 可选系统日历同步：申请日历权限、使用独立日历账户、按有效教学周展开日程、提供 5/10/15/30 分钟课前提醒、关闭时移除专属日历。

## 打开与运行

1. 使用 **DevEco Studio 6.1** 打开此目录，确认已安装 **HarmonyOS API 23 SDK**。
2. 在 DevEco Studio 的设备管理器启动 API 23 模拟器，选择 `entry` 模块并运行。模拟器调试通常无需额外配置签名。
3. 在真机运行时，在 DevEco Studio 的 **Project Structure → Signing Configs** 中为 `com.schoolcalendar.app` 配置自动调试签名，再运行。签名资料属于开发者账号，未放入工程。
4. 首次打开先在设置中填写学期第一周周一的日期，再添加课程。桌面卡片可从设置中的“桌面卡片”入口添加。

也可设置 `DEVECO_HOME` 为 DevEco Studio 安装目录，再在 PowerShell 运行 `./build.ps1`。HAP 输出到 `entry/build/default/outputs/default/`；未配置签名时文件名包含 `unsigned`，该包可在模拟器安装，真机安装需签名。

## 工程结构

- `entry/src/main/ets/model/`：课程、学期、主题与纯时间计算。
- `entry/src/main/ets/data/`：RDB、Preferences、系统日历同步。
- `entry/src/main/ets/pages/`：应用页面。
- `entry/src/main/ets/form/`：卡片扩展、实例刷新与三类卡片页面。

## 验证范围

本工程已使用本机 DevEco Studio 6.1 / API 23 SDK 完成 `assembleHap` 编译，并在 API 23 的 Mate 70 RS 模拟器中安装、启动，实际添加课程后在周视图中显示；日历权限申请、同步开关开启与关闭也已走通。画面见 [课表首页](docs/final-preview.jpeg) 与 [设置页](docs/settings-preview.jpeg)。纯课程逻辑可通过 `node tests/schedule.test.cjs` 验证，运行前同样需要设置 `DEVECO_HOME`。

桌面卡片入口在该模拟器中会跳转桌面，但未能在模拟器里完成卡片摆放和分钟刷新验证；实际提醒通知的送达也需在目标设备上验收。
