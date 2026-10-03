import { promptAction, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, defaultData, ThemeDef } from '../model/Types';
import { dateKey, parseDate } from '../model/Schedule';
import { themeById } from '../model/Themes';
import { AppIcon, FormField, PageHeader, PrimaryAction } from '../components/Design';
import { WidgetService } from '../form/WidgetService';

@Entry
@Component
struct SemesterSetting {
  @State data: AppData = defaultData();
  @State name: string = '';
  @State date: string = '';
  @State weeks: string = '20';
  @StorageProp('isDark') dark: boolean = false;
  aboutToAppear(): void { this.load(); }
  private async load(): Promise<void> {
    await Repository.get().init(getContext(this)); this.data = await Repository.get().load();
    this.name = this.data.semester.name; this.date = this.data.semester.startDate;
    this.weeks = `${this.data.semester.totalWeeks}`;
  }
  private theme(): ThemeDef { return themeById(this.data.themeId, this.dark); }
  private async save(): Promise<void> {
    let w = Number(this.weeks);
    let d = parseDate(this.date);
    let validDate = /^\d{4}-\d{2}-\d{2}$/.test(this.date) && !isNaN(d.getTime()) && dateKey(d) === this.date;
    if (!this.name.trim() || !validDate || d.getDay() !== 1 || !Number.isInteger(w) || w < 1 || w > 30) {
      promptAction.showToast({ message: '请填写学期名、第一周周一日期和 1-30 周' }); return;
    }
    await Repository.get().saveSemester({ name: this.name.trim(), startDate: this.date, totalWeeks: w });
    await WidgetService.notify(getContext(this), await Repository.get().load(), this.dark);
    router.back();
  }
  build() {
    Column({ space: 16 }) {
      PageHeader({ title: '学期设置', caption: '从第一周开始，安排整个学期', theme: this.theme() })
      Scroll() {
        Column({ space: 16 }) {
          Row({ space: 14 }) {
            AppIcon({ name: 'calendar', iconSize: 30, tint: this.theme().accent })
            Column({ space: 6 }) {
              Text('新学期，新的节奏').fontSize(21).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
              Text('学期日期决定每门课的教学周次').fontSize(12).fontColor(this.theme().textSecondary)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          }.padding(20).width('100%').backgroundColor(this.theme().accentSoft).borderRadius(22)
          Column({ space: 12 }) {
            FormField({ label: '学期名称', value: this.name, hint: '例如：2026 秋季学期',
              theme: this.theme(), changed: (v: string) => { this.name = v; } })
            FormField({ label: '第一周周一日期', value: this.date, hint: 'YYYY-MM-DD',
              theme: this.theme(), changed: (v: string) => { this.date = v; } })
            FormField({ label: '学期总周数 · 1 至 30 周', value: this.weeks, hint: '20', numeric: true,
              theme: this.theme(), changed: (v: string) => { this.weeks = v; } })
          }.padding(20).width('100%').backgroundColor(this.theme().cardBg).borderRadius(20)
            .border({ width: 1, color: this.theme().line }).borderRadius(20)
          Text('将开学第一周的周一设为起点，单双周课程会按此日期自动排列。')
            .fontSize(12).lineHeight(21).fontColor(this.theme().textSecondary).padding({ left: 4, right: 4 })
        }.width('100%')
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off).align(Alignment.TopStart)
      PrimaryAction({ label: '保存学期', theme: this.theme(), action: () => this.save() })
    }.padding({ left: 20, right: 20, top: 12, bottom: 16 }).width('100%').height('100%')
      .backgroundColor(this.theme().bg)
  }
  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut }).opacity(0).translate({ x: 14 })
    PageTransitionExit({ duration: 180, curve: Curve.EaseIn }).opacity(0).translate({ x: -8 })
  }
}
