import { promptAction, router } from '@kit.ArkUI';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { formProvider } from '@kit.FormKit';
import { Repository } from '../data/Repository';
import { CalendarSync } from '../data/CalendarSync';
import { AppData, defaultData, ThemeDef } from '../model/Types';
import { themeById } from '../model/Themes';
import { AppIcon, PageHeader, PrimaryAction } from '../components/Design';

@Entry
@Component
struct Settings {
  @State data: AppData = defaultData();
  @State syncing: boolean = false;
  @StorageProp('isDark') dark: boolean = false;
  aboutToAppear(): void { this.load(); }
  onPageShow(): void { this.loadAndSync(); }
  private async load(): Promise<void> {
    await Repository.get().init(getContext(this)); this.data = await Repository.get().load();
  }
  private async loadAndSync(): Promise<void> {
    await this.load();
    if (this.data.calendarSyncEnabled) await this.syncNow();
  }
  private theme(): ThemeDef { return themeById(this.data.themeId, this.dark); }

  private async switchSync(enabled: boolean): Promise<void> {
    if (this.syncing) return;
    this.syncing = true;
    try {
      if (enabled) {
        let permissions: Permissions[] = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
        let result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(getContext(this), permissions);
        if (result.authResults.some((status: number) => status !== 0)) {
          promptAction.showToast({ message: '需要日历权限才能同步课程' }); return;
        }
        let count = await CalendarSync.rebuild(getContext(this), this.data);
        await Repository.get().saveSetting('calendarSyncEnabled', true);
        promptAction.showToast({ message: `已同步 ${count} 节课程到系统日历` });
      } else {
        await CalendarSync.remove(getContext(this));
        await Repository.get().saveSetting('calendarSyncEnabled', false);
        promptAction.showToast({ message: '已移除专属课程日历' });
      }
      this.data = await Repository.get().load();
    } catch (_) {
      promptAction.showToast({ message: '日历操作失败，请确认权限后重试' });
    } finally { this.syncing = false; }
  }

  private async setReminder(value: number): Promise<void> {
    await Repository.get().saveSetting('reminderMinutes', value);
    this.data = await Repository.get().load();
    if (this.data.calendarSyncEnabled) await this.syncNow();
  }

  private async syncNow(): Promise<void> {
    if (this.syncing) return;
    this.syncing = true;
    try {
      let count = await CalendarSync.rebuild(getContext(this), this.data);
      promptAction.showToast({ message: `已同步 ${count} 节课程` });
    } catch (_) { promptAction.showToast({ message: '同步失败，请检查日历权限' }); }
    finally { this.syncing = false; }
  }

  @Builder private SettingRow(icon: string, title: string, path: string) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 13 }) {
        Column() { AppIcon({ name: icon, iconSize: 24, tint: this.theme().accent }) }.width(42).height(42)
          .justifyContent(FlexAlign.Center).backgroundColor(this.theme().surface).borderRadius(13)
        Column({ space: 5 }) {
          Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
          Text(path === 'pages/SemesterSetting' ? `${this.data.semester.name} · ${this.data.semester.totalWeeks} 周` :
            path === 'pages/ScheduleSetting' ? `每日 ${this.data.sections.length} 节 · 自定义上课时间` : `${this.theme().name} · 10 种配色`)
            .fontSize(14).fontColor(this.theme().textSecondary).maxLines(2)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        AppIcon({ name: 'next', iconSize: 16, tint: this.theme().textSecondary })
      }.width('100%').padding(16)
    }.width('100%').backgroundColor(this.theme().cardBg).borderRadius(18)
      .border({ width: 1, color: this.theme().line }).borderRadius(18).onClick(() => router.pushUrl({ url: path }))
  }
  @Builder private GroupLabel(title: string) {
    Text(title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.theme().textSecondary)
      .width('100%').margin({ top: 10, bottom: 2, left: 4 })
  }
  build() {
    Column({ space: 14 }) {
      PageHeader({ title: '设置', caption: '让课表适合你的节奏', theme: this.theme() })
      Scroll() {
        Column({ space: 10 }) {
          Column({ space: 8 }) {
            Text('安排有序，生活从容。').fontSize(21).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
            Text(`${this.data.semester.name} · ${this.data.courses.length} 门课程`)
              .fontSize(14).fontColor(this.theme().textSecondary)
          }.width('100%').alignItems(HorizontalAlign.Start).padding(20)
            .backgroundColor(this.theme().accentSoft).borderRadius(22)
          this.GroupLabel('学习安排')
          this.SettingRow('calendar', '学期设置', 'pages/SemesterSetting')
          this.SettingRow('clock', '作息时间', 'pages/ScheduleSetting')
          this.GroupLabel('个性化')
          this.SettingRow('palette', '主题外观', 'pages/Theme')
          Button({ type: ButtonType.Normal }) {
            Row({ space: 13 }) {
              Column() { AppIcon({ name: 'widget', iconSize: 24, tint: this.theme().accent }) }.width(42).height(42)
                .justifyContent(FlexAlign.Center).backgroundColor(this.theme().surface).borderRadius(13)
              Column({ space: 5 }) {
                Text('桌面卡片').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
                Text('把下一节课、今日课程放在桌面').fontSize(14).fontColor(this.theme().textSecondary)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              AppIcon({ name: 'next', iconSize: 16, tint: this.theme().textSecondary })
            }.padding(16).width('100%')
          }.width('100%').backgroundColor(this.theme().cardBg).borderRadius(18)
            .border({ width: 1, color: this.theme().line }).borderRadius(18)
            .onClick(() => formProvider.openFormManager({ bundleName: 'com.schoolcalendar.app', moduleName: 'entry', abilityName: 'SchoolFormAbility' }))
          this.GroupLabel('提醒与同步')
          Row({ space: 13 }) {
            Column() { AppIcon({ name: 'sync', iconSize: 24, tint: this.theme().accent }) }.width(42).height(42)
              .justifyContent(FlexAlign.Center).backgroundColor(this.theme().surface).borderRadius(13)
            Column({ space: 5 }) {
              Text('同步到系统日历').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
              Text(this.syncing ? '正在同步课程…' : '由系统日历发送课前提醒').fontSize(14).fontColor(this.theme().textSecondary)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.data.calendarSyncEnabled })
              .width(56).height(40).selectedColor(this.theme().accent).enabled(!this.syncing)
              .onChange((value: boolean) => this.switchSync(value))
          }.padding(16).width('100%').backgroundColor(this.theme().cardBg).borderRadius(18)
            .border({ width: 1, color: this.theme().line }).borderRadius(18)
          if (this.data.calendarSyncEnabled) {
            Column({ space: 14 }) {
              Text('提前多久提醒？').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary).width('100%')
              Row({ space: 8 }) {
                ForEach([5, 10, 15, 30], (value: number) => {
                  Button(`${value} 分`, { type: ButtonType.Normal }).fontSize(14).height(40).layoutWeight(1)
                    .fontColor(this.data.reminderMinutes === value ? this.theme().cardBg : this.theme().textPrimary)
                    .backgroundColor(this.data.reminderMinutes === value ? this.theme().accent : this.theme().surface)
                    .borderRadius(11).animation({ duration: 180, curve: Curve.EaseOut })
                    .enabled(!this.syncing).onClick(() => this.setReminder(value))
                }, (value: number) => `${value}`)
              }.width('100%')
              PrimaryAction({ label: this.syncing ? '正在同步…' : '立即同步课程', theme: this.theme(), action: () => this.syncNow() })
            }.padding(16).width('100%').backgroundColor(this.theme().cardBg).borderRadius(18)
              .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 })).animation({ duration: 200 }))
          }
          Text('SchoolCalendar · 课程数据保存在本机').fontSize(14).fontColor(this.theme().textSecondary)
            .width('100%').textAlign(TextAlign.Center).margin({ top: 18, bottom: 20 })
        }.width('100%').alignItems(HorizontalAlign.Start)
      }.layoutWeight(1).scrollBar(BarState.Off).width('100%')
    }.padding({ left: 20, right: 20, top: 12, bottom: 12 }).width('100%').height('100%').backgroundColor(this.theme().bg)
  }
  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut }).opacity(0).translate({ x: 14 })
    PageTransitionExit({ duration: 180, curve: Curve.EaseIn }).opacity(0).translate({ x: -8 })
  }
}
