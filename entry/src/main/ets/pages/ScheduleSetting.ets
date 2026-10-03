import { promptAction, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, defaultData, DEFAULT_SECTIONS, SectionTime, ThemeDef } from '../model/Types';
import { minutes, pad } from '../model/Schedule';
import { themeById } from '../model/Themes';
import { PageHeader, PrimaryAction } from '../components/Design';
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
    Column({ space: 14 }) {
      PageHeader({ title: '作息时间', caption: '按学校的节奏，设置每一节课', theme: this.theme() })
      Row({ space: 10 }) {
        Column({ space: 5 }) {
          Text(`每日 ${this.sections.length} 节`).fontSize(21).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
          Text('时间格式为 HH:mm').fontSize(12).fontColor(this.theme().textSecondary)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button('−', { type: ButtonType.Normal }).width(40).height(40).borderRadius(12)
          .backgroundColor(this.theme().cardBg).fontColor(this.theme().accent).enabled(this.sections.length > 1)
          .onClick(() => this.reduceSection()).accessibilityText('减少一节课')
        Button('＋', { type: ButtonType.Normal }).width(40).height(40).borderRadius(12)
          .backgroundColor(this.theme().accent).fontColor(this.theme().cardBg).enabled(this.sections.length < 15)
          .onClick(() => this.addSection()).accessibilityText('增加一节课')
      }.width('100%').padding(18).backgroundColor(this.theme().accentSoft).borderRadius(20)
      Row() {
        Text('节次').width(44).fontSize(12).fontColor(this.theme().textSecondary)
        Text('开始时间').layoutWeight(1).fontSize(12).fontColor(this.theme().textSecondary)
        Text('结束时间').layoutWeight(1).fontSize(12).fontColor(this.theme().textSecondary)
      }.width('100%').padding({ left: 16, right: 16 })
      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.sections, (s: SectionTime, index: number) => {
            Row({ space: 8 }) {
              Text(`${s.sectionNo}`).width(28).height(32).fontSize(14).fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Center).fontColor(this.theme().accent)
              TextInput({ text: this.sections[index].startTime }).layoutWeight(1).height(42).fontSize(14).borderRadius(11)
                .fontColor(this.theme().textPrimary).backgroundColor(this.theme().surface)
                .onChange((v: string) => this.editTime(index, true, v))
              Text('—').fontSize(12).fontColor(this.theme().textSecondary)
              TextInput({ text: this.sections[index].endTime }).layoutWeight(1).height(42).fontSize(14).borderRadius(11)
                .fontColor(this.theme().textPrimary).backgroundColor(this.theme().surface)
                .onChange((v: string) => this.editTime(index, false, v))
            }.padding(12).width('100%').backgroundColor(this.theme().cardBg).borderRadius(16)
              .border({ width: 1, color: this.theme().line }).borderRadius(16)
              .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 8 })).animation({ duration: 180 }))
          }, (s: SectionTime) => `${s.sectionNo}`)
        }.width('100%')
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
      Button('恢复默认作息', { type: ButtonType.Normal }).height(40).fontSize(12)
        .backgroundColor(Color.Transparent).fontColor(this.theme().textSecondary).onClick(() => {
          if (this.data.courses.some((c) => c.endSection > 12)) {
            promptAction.showToast({ message: '第 13 节以后已有课程，无法恢复默认' }); return;
          }
          this.sections = DEFAULT_SECTIONS.map((s: SectionTime): SectionTime => ({ sectionNo: s.sectionNo, startTime: s.startTime, endTime: s.endTime }));
        })
      PrimaryAction({ label: '保存作息时间', theme: this.theme(), action: () => this.save() })
    }.padding({ left: 20, right: 20, top: 12, bottom: 16 }).width('100%').height('100%').backgroundColor(this.theme().bg)
  }
  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut }).opacity(0).translate({ x: 14 })
    PageTransitionExit({ duration: 180, curve: Curve.EaseIn }).opacity(0).translate({ x: -8 })
  }
}
