import { promptAction, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, defaultData, DEFAULT_SECTIONS, SectionTime, ThemeDef } from '../model/Types';
import { minutes, pad } from '../model/Schedule';
import { themeById } from '../model/Themes';
import { WidgetService } from '../form/WidgetService';

@Entry
@Component
struct ScheduleSetting {
  @State data: AppData = defaultData();
  @State sections: SectionTime[] = DEFAULT_SECTIONS;
  @StorageProp('isDark') dark: boolean = false;
  aboutToAppear(): void { this.load(); }
  private async load(): Promise<void> {
    await Repository.get().init(getContext(this)); this.data = await Repository.get().load();
    this.sections = this.data.sections.map((s: SectionTime): SectionTime => ({ sectionNo: s.sectionNo, startTime: s.startTime, endTime: s.endTime }));
  }
  private theme(): ThemeDef { return themeById(this.data.themeId, this.dark); }
  private editTime(index: number, start: boolean, value: string): void {
    let changed = this.sections.slice(); let old = changed[index];
    changed[index] = { sectionNo: old.sectionNo, startTime: start ? value : old.startTime,
      endTime: start ? old.endTime : value };
    this.sections = changed;
  }
  private addSection(): void {
    if (this.sections.length >= 15) return;
    let last = this.sections[this.sections.length - 1];
    let start = minutes(last.endTime) + 10;
    let end = start + 45;
    this.sections = [...this.sections, { sectionNo: this.sections.length + 1,
      startTime: `${pad(Math.floor(start / 60))}:${pad(start % 60)}`,
      endTime: `${pad(Math.floor(end / 60))}:${pad(end % 60)}` }];
  }
  private reduceSection(): void {
    if (this.sections.length <= 1) return;
    if (this.data.courses.some((c) => c.endSection >= this.sections.length)) {
      promptAction.showToast({ message: '末节已有课程，请先修改或删除对应课程' }); return;
    }
    this.sections = this.sections.slice(0, this.sections.length - 1);
  }
  private async save(): Promise<void> {
    for (let s of this.sections) {
      if (!/^\d{2}:\d{2}$/.test(s.startTime) || !/^\d{2}:\d{2}$/.test(s.endTime) ||
        minutes(s.startTime) >= minutes(s.endTime) || minutes(s.endTime) > 1439) {
        promptAction.showToast({ message: `第 ${s.sectionNo} 节时间无效` }); return;
      }
    }
    await Repository.get().saveSections(this.sections);
    await WidgetService.notify(getContext(this), await Repository.get().load(), this.dark);
    router.back();
  }
  build() {
    Column({ space: 12 }) {
      Row() { Text('‹').fontSize(30).fontColor(this.theme().accent).onClick(() => router.back())
        Text('作息时间').fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 14 }) }.width('100%')
      Row({ space: 12 }) {
        Button('− 减少').onClick(() => this.reduceSection())
        Text(`每日 ${this.sections.length} 节`).fontSize(15)
        Button('＋ 增加').onClick(() => this.addSection())
      }.width('100%')
      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.sections, (s: SectionTime, index: number) => {
            Row({ space: 8 }) {
              Text(`${s.sectionNo}`).width(26).fontWeight(FontWeight.Bold)
              TextInput({ text: s.startTime }).width(100).onChange((v: string) => this.editTime(index, true, v))
              Text('—')
              TextInput({ text: s.endTime }).width(100).onChange((v: string) => this.editTime(index, false, v))
            }.padding(8).width('100%').backgroundColor(this.theme().cardBg).borderRadius(10)
          }, (s: SectionTime) => `${s.sectionNo}`)
        }.width('100%')
      }.layoutWeight(1)
      Row({ space: 12 }) {
        Button('恢复默认').backgroundColor(this.theme().textSecondary).onClick(() => {
          if (this.data.courses.some((c) => c.endSection > 12)) {
            promptAction.showToast({ message: '第 13 节以后已有课程，无法恢复默认' }); return;
          }
          this.sections = DEFAULT_SECTIONS.map((s: SectionTime): SectionTime => ({ sectionNo: s.sectionNo, startTime: s.startTime, endTime: s.endTime }));
        })
        Button('保存').backgroundColor(this.theme().accent).onClick(() => this.save())
      }.width('100%').justifyContent(FlexAlign.End)
    }.padding(18).width('100%').height('100%').backgroundColor(this.theme().bg)
  }
}
