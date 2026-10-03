import { curves, promptAction, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, Course, defaultData, SectionTime, ThemeDef } from '../model/Types';
import { conflict, validWeeksMask } from '../model/Schedule';
import { courseBackground, courseForeground, themeById } from '../model/Themes';
import { FormField, PageHeader, PrimaryAction } from '../components/Design';
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
    Text(value).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.theme().textSecondary)
      .margin({ top: 16, bottom: 9 })
  }
  @Builder private SectionPicker(isStart: boolean) {
    Scroll() {
      Row({ space: 6 }) {
        ForEach(this.data.sections, (s: SectionTime) => {
          Button(`${s.sectionNo}`, { type: ButtonType.Normal }).fontSize(14).width(40).height(40).borderRadius(20)
            .fontColor((isStart ? this.start : this.end) === s.sectionNo ? this.theme().cardBg : this.theme().textPrimary)
            .backgroundColor((isStart ? this.start : this.end) === s.sectionNo ? this.theme().accent : this.theme().surface)
            .animation({ curve: curves.responsiveSpringMotion() })
            .onClick(() => {
              if (isStart) { this.start = s.sectionNo; if (this.end < this.start) this.end = this.start; }
              else { this.end = s.sectionNo; if (this.start > this.end) this.start = this.end; }
            })
        }, (s: SectionTime) => `${s.sectionNo}`)
      }
    }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
  }
  build() {
    Column({ space: 14 }) {
      PageHeader({ title: this.courseId ? '编辑课程' : '添加课程', caption: '把下一段学习时光安排好', theme: this.theme() })
      Scroll() {
        Column({ space: 14 }) {
          Row({ space: 14 }) {
            Column().width(4).height(46).borderRadius(2)
              .backgroundColor(courseForeground(this.theme(), this.colorIndex, this.dark))
            Column({ space: 6 }) {
              Text(this.name || '你的课程名称').fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.theme().textPrimary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`${DAYS[this.day - 1]} · 第 ${this.start}-${this.end} 节 · ${this.location || '地点待补充'}`)
                .fontSize(12).fontColor(this.theme().textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          }.padding(18).width('100%').backgroundColor(courseBackground(this.theme(), this.colorIndex, this.dark))
            .borderRadius(20).animation({ duration: 180, curve: Curve.EaseOut })
          Column() {
            FormField({ label: '课程名称 *', value: this.name, hint: '例如：高等数学 A', limit: 20,
              theme: this.theme(), changed: (v: string) => { this.name = v; } }).margin({ bottom: 14 })
            FormField({ label: '授课教师', value: this.teacher, hint: '选填教师姓名',
              theme: this.theme(), changed: (v: string) => { this.teacher = v; } }).margin({ bottom: 14 })
            FormField({ label: '上课地点', value: this.location, hint: '教学楼与教室',
              theme: this.theme(), changed: (v: string) => { this.location = v; } }).margin({ bottom: 14 })
            Text('课程颜色').fontSize(14).fontColor(this.theme().textSecondary).margin({ bottom: 12 })
            Grid() {
              ForEach(this.theme().palette, (color: string, index: number) => {
                GridItem() {
                  Button({ type: ButtonType.Normal }) {
                    Stack() {
                      Circle().width(28).height(28).fill(color)
                      if (this.colorIndex === index) {
                        SymbolGlyph($r('sys.symbol.checkmark')).fontSize(16).fontColor([Color.White])
                      }
                    }.width(40).height(40)
                      .border({ width: this.colorIndex === index ? 2 : 0, color: color }).borderRadius(20)
                      .scale({ x: this.colorIndex === index ? 1 : 0.9, y: this.colorIndex === index ? 1 : 0.9 })
                      .animation({ curve: curves.responsiveSpringMotion() })
                  }.width(48).height(48).backgroundColor(Color.Transparent).borderRadius(24)
                    .onClick(() => { this.colorIndex = index; })
                    .accessibilityText(`课程颜色 ${index + 1}${this.colorIndex === index ? '，已选中' : ''}`)
                }
              }, (color: string, index: number) => `${index}`)
            }.columnsTemplate('1fr 1fr 1fr 1fr 1fr').rowsTemplate('1fr 1fr').rowsGap(8).height(104).width('100%')
          }.alignItems(HorizontalAlign.Start).padding(18).width('100%')
            .backgroundColor(this.theme().cardBg).borderRadius(20).border({ width: 1, color: this.theme().line }).borderRadius(20)
          Column() {
            Text('上课安排').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
            this.Label('星期')
            Scroll() {
              Row({ space: 3 }) {
                ForEach(DAYS, (label: string, index: number) => {
                  Button(label.replace('周', ''), { type: ButtonType.Normal }).fontSize(14).width(40).height(40)
                    .fontColor(this.day === index + 1 ? this.theme().cardBg : this.theme().textPrimary)
                    .backgroundColor(this.day === index + 1 ? this.theme().accent : this.theme().surface)
                    .borderRadius(20).animation({ curve: curves.responsiveSpringMotion() }).onClick(() => { this.day = index + 1; })
                    .accessibilityText(label)
                }, (label: string) => label)
              }
            }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
            this.Label('开始节次')
            this.SectionPicker(true)
            this.Label('结束节次')
            this.SectionPicker(false)
            this.Label('上课周次')
            Row({ space: 6 }) {
              ForEach(['all', 'odd', 'even', 'custom'], (value: string, index: number) => {
                Button(['每周', '单周', '双周', '自定义'][index], { type: ButtonType.Normal }).fontSize(14).height(40).layoutWeight(1)
                  .padding({ left: 8, right: 8 })
                  .fontColor(this.pattern === value ? this.theme().cardBg : this.theme().textPrimary)
                  .backgroundColor(this.pattern === value ? this.theme().accent : this.theme().surface)
                  .borderRadius(20).animation({ curve: curves.responsiveSpringMotion() }).onClick(() => { this.pattern = value; })
              }, (value: string) => value)
            }.width('100%')
            if (this.pattern === 'custom') {
              TextInput({ placeholder: '输入周次：1-8,11,13', text: this.weeks }).height(46).fontSize(14)
                .fontColor(this.theme().textPrimary).placeholderColor(this.theme().textSecondary)
                .backgroundColor(this.theme().surface).borderRadius(12).margin({ top: 12 })
                .onChange((v: string) => { this.weeks = v; })
              Button('快速选择第 1-8 周', { type: ButtonType.Normal }).fontSize(14).height(40)
                .backgroundColor(Color.Transparent).fontColor(this.theme().accent)
                .onClick(() => { this.weeks = '1-8'; })
            }
          }.alignItems(HorizontalAlign.Start).padding(18).width('100%')
            .backgroundColor(this.theme().cardBg).borderRadius(20).border({ width: 1, color: this.theme().line }).borderRadius(20)
          if (this.courseId > 0) {
            Button('删除这门课程', { type: ButtonType.Normal }).width('100%').height(46).borderRadius(14)
              .backgroundColor(this.theme().cardBg).fontColor(this.dark || this.data.themeId === 'deep_space' ? '#FFA6AF' : '#AD4E61')
              .onClick(() => this.remove())
          }
          Text('保存后会更新课表与桌面卡片').fontSize(12).fontColor(this.theme().textSecondary)
            .width('100%').textAlign(TextAlign.Center).margin({ bottom: 10 })
        }.alignItems(HorizontalAlign.Start).width('100%')
      }.layoutWeight(1).scrollBar(BarState.Off).width('100%')
      PrimaryAction({ label: '保存课程', theme: this.theme(), action: () => this.save() })
    }.padding({ left: 20, right: 20, top: 12, bottom: 16 }).width('100%').height('100%').backgroundColor(this.theme().bg)
  }
  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut }).opacity(0).translate({ x: 14 })
    PageTransitionExit({ duration: 180, curve: Curve.EaseIn }).opacity(0).translate({ x: -8 })
  }
}
