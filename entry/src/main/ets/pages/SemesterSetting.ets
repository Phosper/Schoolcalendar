import { promptAction, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, defaultData, ThemeDef } from '../model/Types';
import { dateKey, parseDate } from '../model/Schedule';
import { themeById } from '../model/Themes';
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
    Column({ space: 14 }) {
      Row() { Text('‹').fontSize(30).fontColor(this.theme().accent).onClick(() => router.back())
        Text('学期设置').fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 14 }) }.width('100%')
      Text('学期名称').fontSize(15).width('100%')
      TextInput({ text: this.name, placeholder: '例如 2026 秋季学期' }).onChange((v: string) => { this.name = v; })
      Text('第一周周一日期').fontSize(15).width('100%')
      TextInput({ text: this.date, placeholder: 'YYYY-MM-DD' }).onChange((v: string) => { this.date = v; })
      Text('学期总周数（1-30）').fontSize(15).width('100%')
      TextInput({ text: this.weeks, placeholder: '20' }).type(InputType.Number).onChange((v: string) => { this.weeks = v; })
      Text('日期是教学第一周的周一；课程单双周按此日期计算。').fontSize(13).fontColor(this.theme().textSecondary)
      Button('保存学期').width('100%').backgroundColor(this.theme().accent).onClick(() => this.save())
    }.padding(18).width('100%').height('100%').alignItems(HorizontalAlign.Start)
      .backgroundColor(this.theme().bg)
  }
}
