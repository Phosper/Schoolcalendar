# SchoolCalendar（鸿蒙课程表）

基于 HarmonyOS 6.1.0 / API 23 的 ArkTS 原生工程。设计依据是仓库中的《SchoolCalendar 产品设计文档》。

## 已实现

- 本地 RDB 存储课程、节次时间和学期；Preferences 保存主题与提醒设置。
- 课程添加、编辑、删除、冲突提示；全周、单双周、自定义周次；周视图、课程详情半模态、学期与作息设置。
- 10 套主题、跟随系统深色模式。
- 六个页面统一使用柔和配色、HarmonyOS Symbol 系统图标、圆角卡片与清晰的文字层级；课程使用浅色底与彩色边线。
- 全周视图保持完整的七天结构，窄屏可横向浏览，可切换展开视图阅读更宽的课程卡片；节次区域支持纵向滚动。今日日期、当前节次与下一节课状态自动突出显示。
- 页面进入与主题切换使用短过渡；切周、按钮按压和课程选项使用 ArkUI 原生弹簧曲线；课程详情使用内容自适应的原生半模态。
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

## HarmonyOS 官方设计依据

通过华为开发者知识 MCP 检索、读取官方文档，并在 API 23 SDK 中核对系统图标和动画接口。本工程采用以下规则：

- [标题栏](https://developer.huawei.com/consumer/cn/doc/design-guides/titlebar-0000001929628982)：首页以课表图形内容为主，采用 56 vp 普通双行标题区；二级页采用 56 vp 标题栏，说明文字放在栏下，返回入口保持一致。
- [HarmonyOS Symbol](https://developer.huawei.com/consumer/cn/doc/design-guides/system-icons-0000001929854962)：通过 `SymbolGlyph` 使用系统图标，颜色随主题变化，装饰图标不单独进入无障碍焦点。
- [应用 UX 体验检查](https://developer.huawei.com/consumer/cn/doc/guidebook/solution7-0000002601693441)：按点击热区至少 40 × 40 vp 的要求调整颜色、星期、节次、视图切换与关闭按钮；颜色选择采用两行布局，课表课程列宽至少 44 vp。
- [鸿蒙黑体](https://developer.huawei.com/consumer/cn/doc/design-guides/font-0000001828772001)：保留系统字体，以字重和字号区分信息层级。项目自定辅助文字下限为 12 fp，输入及主要操作为 16 fp；这里的 12 fp 是本项目的设计选择。
- [动效属性](https://developer.huawei.com/consumer/cn/doc/design-guides/animation-attributes-0000001797117229)与[插值计算](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-curve)：按压使用 `responsiveSpringMotion()`，切周采用 `springMotion(0.35, 0.9)`。弹簧动画时长由物理参数决定，普通渐变仍使用短时长曲线。

上述是本次界面实现的依据，未覆盖官方全部 UX 验收条目。导航暂沿用现有页面路由，尚未迁移到 `Navigation` / `NavDestination`。

## 验证范围

本工程已使用本机 DevEco Studio 6.1 / API 23 SDK 完成 `assembleHap` 编译，并在 API 23 的 Mate 70 RS 模拟器中安装、启动，实际添加课程后在周视图中显示；日历权限申请、同步开关开启与关闭也已走通。画面见 [课表首页](docs/final-preview.jpeg) 与 [设置页](docs/settings-preview.jpeg)。纯课程逻辑可通过 `node tests/schedule.test.cjs` 验证，运行前同样需要设置 `DEVECO_HOME`。

2026-10-03 的界面改版已完成编译和模拟器安装，检查了切周、返回今天、全周/展开视图、课表纵向滚动、课程详情、编辑表单与主题切换。10 套主题的浅色/深色组合中，课程文字、卡片辅助文字与主按钮文字的颜色对比度检查通过 4.5:1。新版截图：[首页](docs/ui-home.png)、[展开课表](docs/ui-expanded.png)、[深色主题](docs/ui-dark.png)、[设置](docs/ui-settings.png)、[主题选择](docs/ui-theme.png)、[课程编辑](docs/ui-course-edit.png)。模拟器输入法的首次使用协议尚未配置，本次没有新增保存课程或复测输入法操作；课程保存逻辑保持原有实现。

同日按官方资料进一步调整标题栏、系统图标、文字大小、点击区域与弹簧动效，API 23 编译、课程逻辑测试及主题对比度检查通过。模拟器检查了切周、返回今天、展开视图、课表双向滚动、课程详情、颜色草稿选择及已有课程和学期值加载；未保存测试草稿，恢复了测试前的主题。当前截图：[首页](docs/harmony-home.png)、[展开课表](docs/harmony-expanded.png)、[深色](docs/harmony-dark.png)、[设置](docs/harmony-settings.png)、[课程编辑](docs/harmony-course-edit.png)、[课程选项](docs/harmony-course-options.png)、[课程详情](docs/harmony-detail.png)。

桌面卡片入口在该模拟器中会跳转桌面，但未能在模拟器里完成卡片摆放和分钟刷新验证；实际提醒通知的送达也需在目标设备上验收。
