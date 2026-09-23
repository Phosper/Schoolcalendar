import { promptAction, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, Course, defaultData, SectionTime, ThemeDef } from '../model/Types';
import { conflict, validWeeksMask } from '../model/Schedule';
import { themeById } from '../model/Themes';
import { WidgetService } from '../form/WidgetService';

interface CourseParams { id?: number; }
const DAYS: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

@Entry
@Component
struct CourseEdit {
  @State data: AppData = defaultData();
  @State courseId: number = 0;
  @State name: string = '';
  @State teacher: string = '';
  @State location: string = '';
  @State day: number = 1;
  @State start: number = 1;
  @State end: number = 2;
  @State pattern: string = 'all';
  @State weeks: string = '';
  @State colorIndex: number = 3;
  @StorageProp('isDark') dark: boolean = false;

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    await Repository.get().init(getContext(this));
    this.data = await Repository.get().load();
    let p = router.getParams() as CourseParams;
    this.courseId = p?.id ?? 0;
    let c = this.data.courses.find((item: Course) => item.id === this.courseId);
    if (c) {
      this.name = c.name; this.teacher = c.teacher; this.location = c.location;
      this.day = c.dayOfWeek; this.start = c.startSection; this.end = c.endSection;
      this.pattern = c.weekPattern; this.weeks = c.weeksMask; this.colorIndex = c.colorIndex;
    } else {
      let usage: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      this.data.courses.forEach((item: Course) => usage[item.colorIndex]++);
      this.colorIndex = usage.indexOf(Math.min(...usage));
    }
  }

  private theme(): ThemeDef { return themeById(this.data.themeId, this.dark); }

  private draft(): Course {
    return { id: this.courseId, name: this.name.trim(), teacher: this.teacher.trim(),
      location: this.location.trim(), dayOfWeek: this.day, startSection: this.start,
      endSection: this.end, weekPattern: this.pattern, weeksMask: this.weeks.trim(), colorIndex: this.colorIndex };
  }

  private save(): void {
    if (!this.name.trim() || this.name.trim().length > 20) {
      promptAction.showToast({ message: '课程名需为 1-20 字' }); return;
    }
    if (this.start > this.end) { promptAction.showToast({ message: '结束节次不能早于开始节次' }); return; }
    if (this.pattern === 'custom' && !validWeeksMask(this.weeks, this.data.semester.totalWeeks)) {
      promptAction.showToast({ message: `周次格式应为 1-8,11,13，范围为 1-${this.data.semester.totalWeeks} 周` }); return;
    }
    let c = this.draft();
    let existing = conflict(this.data, c);
    if (existing) {
      AlertDialog.show({ title: '课程时间冲突', message: `与「${existing.name}」重叠，仍要保存吗？`,
        primaryButton: { value: '返回修改', action: () => {} },
        secondaryButton: { value: '仍要保存', action: () => { this.commit(c); } } });
    } else this.commit(c);
  }

  private async commit(course: Course): Promise<void> {
    await Repository.get().saveCourse(course);
    await WidgetService.notify(getContext(this), await Repository.get().load(), this.dark);
    router.back();
  }

  private remove(): void {
    AlertDialog.show({ title: '删除课程', message: `确定删除「${this.name}」吗？`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.deleteConfirmed(); } } });
  }

  private async deleteConfirmed(): Promise<void> {
    await Repository.get().deleteCourse(this.courseId);
    await WidgetService.notify(getContext(this), await Repository.get().load(), this.dark);
    router.back();
  }

  @Builder private Label(value: string) {
    Text(value).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
      .margin({ top: 12, bottom: 8 })
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(30).fontColor(this.theme().accent).onClick(() => router.back())
        Text(this.courseId ? '编辑课程' : '添加课程').fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().textPrimary).margin({ left: 14 })
      }.width('100%').height(50)
      Scroll() {
        Column() {
          this.Label('课程名 *')
          TextInput({ placeholder: '例如 高等数学 A', text: this.name })
            .maxLength(20).onChange((v: string) => { this.name = v; })
          this.Label('教师')
          TextInput({ placeholder: '选填', text: this.teacher }).onChange((v: string) => { this.teacher = v; })
          this.Label('地点')
          TextInput({ placeholder: '教学楼与教室', text: this.location }).onChange((v: string) => { this.location = v; })
          this.Label('课程颜色')
          Row({ space: 7 }) {
            ForEach(this.theme().palette, (color: string, index: number) => {
              Column().width(26).height(26).borderRadius(13).backgroundColor(color)
                .border({ width: this.colorIndex === index ? 3 : 0, color: this.theme().textPrimary })
                .onClick(() => { this.colorIndex = index; })
            }, (color: string, index: number) => `${index}`)
          }.width('100%')
          this.Label('星期')
          Row({ space: 6 }) {
            ForEach(DAYS, (label: string, index: number) => {
              Text(label).fontSize(11).fontColor(this.day === index + 1 ? Color.White : this.theme().textPrimary)
                .padding(6).backgroundColor(this.day === index + 1 ? this.theme().accent : this.theme().cardBg)
                .borderRadius(8).onClick(() => { this.day = index + 1; })
            }, (label: string) => label)
          }.width('100%')
          this.Label('开始节次')
          Scroll() {
            Row({ space: 6 }) {
              ForEach(this.data.sections, (s: SectionTime) => {
                Text(`${s.sectionNo}`).fontSize(14).fontColor(this.start === s.sectionNo ? Color.White : this.theme().textPrimary)
                  .width(36).height(36).textAlign(TextAlign.Center)
                  .backgroundColor(this.start === s.sectionNo ? this.theme().accent : this.theme().cardBg)
                  .borderRadius(8).onClick(() => { this.start = s.sectionNo; if (this.end < this.start) this.end = this.start; })
              }, (s: SectionTime) => `${s.sectionNo}`)
            }
          }.scrollable(ScrollDirection.Horizontal)
          this.Label('结束节次')
          Scroll() {
            Row({ space: 6 }) {
              ForEach(this.data.sections, (s: SectionTime) => {
                Text(`${s.sectionNo}`).fontSize(14).fontColor(this.end === s.sectionNo ? Color.White : this.theme().textPrimary)
                  .width(36).height(36).textAlign(TextAlign.Center)
                  .backgroundColor(this.end === s.sectionNo ? this.theme().accent : this.theme().cardBg)
                  .borderRadius(8).onClick(() => { this.end = s.sectionNo; if (this.start > this.end) this.start = this.end; })
              }, (s: SectionTime) => `${s.sectionNo}`)
            }
          }.scrollable(ScrollDirection.Horizontal)
          this.Label('上课周次')
          Row({ space: 7 }) {
            ForEach(['all', 'odd', 'even', 'custom'], (value: string, index: number) => {
              Text(['每周', '单周', '双周', '自定义'][index]).fontSize(13)
                .fontColor(this.pattern === value ? Color.White : this.theme().textPrimary)
                .padding(9).backgroundColor(this.pattern === value ? this.theme().accent : this.theme().cardBg)
                .borderRadius(8).onClick(() => { this.pattern = value; })
            }, (value: string) => value)
          }
          if (this.pattern === 'custom') {
            TextInput({ placeholder: '输入周次：1-8,11,13', text: this.weeks })
              .margin({ top: 8 }).onChange((v: string) => { this.weeks = v; })
            Text('快速选择第 1-8 周').fontSize(12).fontColor(this.theme().accent)
              .onClick(() => { this.weeks = '1-8'; })
          }
          Button('保存课程').width('100%').height(50).margin({ top: 28 })
            .backgroundColor(this.theme().accent).onClick(() => this.save())
          if (this.courseId > 0) {
            Button('删除课程').width('100%').height(48).margin({ top: 10, bottom: 24 })
              .backgroundColor('#E87272').onClick(() => this.remove())
          }
        }.alignItems(HorizontalAlign.Start).width('100%')
      }.layoutWeight(1)
    }.padding(18).width('100%').height('100%').backgroundColor(this.theme().bg)
  }
}
