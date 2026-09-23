import { promptAction, router } from '@kit.ArkUI';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { formProvider } from '@kit.FormKit';
import { Repository } from '../data/Repository';
import { CalendarSync } from '../data/CalendarSync';
import { AppData, defaultData, ThemeDef } from '../model/Types';
import { themeById } from '../model/Themes';

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

  @Builder private SettingRow(title: string, caption: string, path: string) {
    Row() {
      Column({ space: 4 }) {
        Text(title).fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
        Text(caption).fontSize(12).fontColor(this.theme().textSecondary)
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Text('›').fontSize(24).fontColor(this.theme().textSecondary)
    }.width('100%').padding(17).backgroundColor(this.theme().cardBg).borderRadius(14)
      .onClick(() => router.pushUrl({ url: path }))
  }

  build() {
    Column({ space: 14 }) {
      Row() { Text('‹').fontSize(30).fontColor(this.theme().accent).onClick(() => router.back())
        Text('设置').fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 14 }) }.width('100%')
      Scroll() {
      Column({ space: 12 }) {
      this.SettingRow('学期设置', `${this.data.semester.name} · ${this.data.semester.totalWeeks} 周`, 'pages/SemesterSetting')
      this.SettingRow('作息时间', `每日 ${this.data.sections.length} 节`, 'pages/ScheduleSetting')
      this.SettingRow('主题外观', this.theme().name, 'pages/Theme')
      Row() {
        Column({ space: 4 }) {
          Text('桌面卡片').fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
          Text('选择下一节课、今日课程或周课表卡片').fontSize(12).fontColor(this.theme().textSecondary)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text('›').fontSize(24).fontColor(this.theme().textSecondary)
      }.padding(17).width('100%').backgroundColor(this.theme().cardBg).borderRadius(14)
        .onClick(() => formProvider.openFormManager({ bundleName: 'com.schoolcalendar.app',
          moduleName: 'entry', abilityName: 'SchoolFormAbility' }))
      Row() {
        Column({ space: 4 }) {
          Text('同步到系统日历').fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
          Text('由系统日历发送课前提醒').fontSize(12).fontColor(this.theme().textSecondary)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.data.calendarSyncEnabled })
          .selectedColor(this.theme().accent).onChange((value: boolean) => this.switchSync(value))
      }.padding(17).width('100%').backgroundColor(this.theme().cardBg).borderRadius(14)
      if (this.data.calendarSyncEnabled) {
        Column({ space: 10 }) {
          Text('课前提醒').fontSize(16).fontColor(this.theme().textPrimary).width('100%')
          Row({ space: 8 }) {
            ForEach([5, 10, 15, 30], (value: number) => {
              Text(`${value} 分`).fontSize(13)
                .fontColor(this.data.reminderMinutes === value ? Color.White : this.theme().textPrimary)
                .padding(9).backgroundColor(this.data.reminderMinutes === value ? this.theme().accent : this.theme().bg)
                .borderRadius(8).onClick(() => this.setReminder(value))
            }, (value: number) => `${value}`)
          }
          Button(this.syncing ? '正在同步…' : '立即同步课程').width('100%')
            .backgroundColor(this.theme().accent).onClick(() => this.syncNow())
        }.padding(17).width('100%').backgroundColor(this.theme().cardBg).borderRadius(14)
      }
      Text('课程数据只保存在本机。').fontSize(13).fontColor(this.theme().textSecondary).margin({ top: 16 })
      }.width('100%').alignItems(HorizontalAlign.Start).align(Alignment.TopStart)
      }.layoutWeight(1).align(Alignment.TopStart)
    }.padding(18).width('100%').height('100%').backgroundColor(this.theme().bg)
  }
}
