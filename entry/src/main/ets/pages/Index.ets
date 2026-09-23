import { router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, Course, defaultData, SectionTime, ThemeDef } from '../model/Types';
import { addDays, coursesOn, minutes, nextCourse, parseDate, sectionFor, semesterMessage, teachingWeek } from '../model/Schedule';
import { themeById } from '../model/Themes';
import { WidgetService } from '../form/WidgetService';

const DAYS: string[] = ['一', '二', '三', '四', '五', '六', '日'];

@Entry
@Component
struct Index {
  @State data: AppData = defaultData();
  @State shownWeek: number = 0;
  @State now: number = Date.now();
  @StorageProp('isDark') dark: boolean = false;
  @State showDetail: boolean = false;
  @State selectedCourse: Course = { id: 0, name: '', teacher: '', location: '', dayOfWeek: 1,
    startSection: 1, endSection: 1, weekPattern: 'all', weeksMask: '', colorIndex: 0 };
  private ticker: number = 0;

  aboutToAppear(): void {
    this.refresh();
    this.ticker = setInterval(() => { this.now = Date.now(); }, 60000);
  }

  aboutToDisappear(): void { clearInterval(this.ticker); }

  onPageShow(): void { this.refresh(); }

  private async refresh(): Promise<void> {
    await Repository.get().init(getContext(this));
    this.data = await Repository.get().load();
    let w = teachingWeek(this.data, new Date());
    if (this.shownWeek < 1 || this.shownWeek > this.data.semester.totalWeeks) {
      this.shownWeek = Math.max(1, Math.min(w, this.data.semester.totalWeeks));
    } else if (this.data.courses.length === 0) {
      this.shownWeek = Math.max(1, Math.min(w, this.data.semester.totalWeeks));
    }
  }

  private theme(): ThemeDef { return themeById(this.data.themeId, this.dark); }

  private dayDate(day: number): Date {
    return addDays(parseDate(this.data.semester.startDate), (this.shownWeek - 1) * 7 + day - 1);
  }

  private atStart(day: number, section: number): Course | undefined {
    return coursesOn(this.data, this.dayDate(day)).find((c: Course) => c.startSection === section);
  }

  private covered(day: number, section: number): boolean {
    return coursesOn(this.data, this.dayDate(day)).some((c: Course) => c.startSection < section && c.endSection >= section);
  }

  private isCurrentSection(no: number): boolean {
    if (this.shownWeek !== teachingWeek(this.data, new Date(this.now))) return false;
    let current = new Date(this.now);
    let clock = current.getHours() * 60 + current.getMinutes();
    let section = sectionFor(this.data, no);
    return clock >= minutes(section.startTime) && clock < minutes(section.endTime);
  }

  private openCourse(course: Course): void {
    this.selectedCourse = course;
    this.showDetail = true;
  }

  private deleteSelected(): void {
    AlertDialog.show({
      title: '删除课程', message: `确定删除「${this.selectedCourse.name}」吗？`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.confirmDelete(); } }
    });
  }

  private async confirmDelete(): Promise<void> {
    await Repository.get().deleteCourse(this.selectedCourse.id);
    this.data = await Repository.get().load();
    await WidgetService.notify(getContext(this), this.data, this.dark);
    this.showDetail = false;
  }

  @Builder private CourseSheet() {
    Column({ space: 15 }) {
      Column().width(48).height(5).borderRadius(3).backgroundColor(this.theme().textSecondary)
      Text(this.selectedCourse.name).fontSize(24).fontWeight(FontWeight.Bold)
        .fontColor(this.theme().textPrimary).width('100%')
      Text(`${this.selectedCourse.location || '地点未填写'} · ${this.selectedCourse.teacher || '教师未填写'}`)
        .fontSize(15).fontColor(this.theme().textSecondary).width('100%')
      Text(`周${DAYS[this.selectedCourse.dayOfWeek - 1]} · 第 ${this.selectedCourse.startSection}-${this.selectedCourse.endSection} 节`)
        .fontSize(16).fontColor(this.theme().textPrimary).width('100%')
      Text(`${sectionFor(this.data, this.selectedCourse.startSection).startTime} — ${sectionFor(this.data, this.selectedCourse.endSection).endTime}`)
        .fontSize(16).fontColor(this.theme().accent).width('100%')
      Text(`周次：${this.selectedCourse.weekPattern === 'all' ? '每周' : this.selectedCourse.weekPattern === 'odd' ? '单周' : this.selectedCourse.weekPattern === 'even' ? '双周' : this.selectedCourse.weeksMask}`)
        .fontSize(14).fontColor(this.theme().textSecondary).width('100%')
      Text(this.shownWeek <= this.data.semester.totalWeeks && coursesOn(this.data, this.dayDate(this.selectedCourse.dayOfWeek)).some((c: Course) => c.id === this.selectedCourse.id) ? '本周有课' : '本周无课')
        .fontSize(14).fontColor(this.theme().accent).width('100%')
      Row({ space: 10 }) {
        Button('编辑').layoutWeight(1).backgroundColor(this.theme().accent)
          .onClick(() => { this.showDetail = false; router.pushUrl({ url: 'pages/CourseEdit', params: { id: this.selectedCourse.id } }); })
        Button('删除').layoutWeight(1).backgroundColor('#D96363').onClick(() => this.deleteSelected())
      }.width('100%')
    }.padding(22).width('100%').backgroundColor(this.theme().cardBg)
  }

  @Builder private Upcoming() {
    Column({ space: 8 }) {
      Row() {
        Text('接下来').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.theme().textSecondary)
        Blank()
        Text('课程提醒').fontSize(12).fontColor(this.theme().accent)
      }.width('100%')
      if (semesterMessage(this.data, new Date(this.now))) {
        Text(semesterMessage(this.data, new Date(this.now))).fontSize(19).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().textPrimary)
      } else if (nextCourse(this.data, new Date(this.now))) {
        Text(nextCourse(this.data, new Date(this.now))!.course.name)
          .fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
        Text(`${nextCourse(this.data, new Date(this.now))!.date.getMonth() + 1}/${nextCourse(this.data, new Date(this.now))!.date.getDate()} · ${nextCourse(this.data, new Date(this.now))!.course.location || '地点未填写'} · ${sectionFor(this.data, nextCourse(this.data, new Date(this.now))!.course.startSection).startTime}`)
          .fontSize(14).fontColor(this.theme().textSecondary)
      } else {
        Text(this.data.courses.length === 0 ? '添加第一门课，开始安排你的学期' : '未来两周没有课程')
          .fontSize(17).fontColor(this.theme().textPrimary)
      }
    }.alignItems(HorizontalAlign.Start).padding(18).width('100%').backgroundColor(this.theme().cardBg).borderRadius(18)
  }

  @Builder private DayColumn(day: number) {
    Column() {
      Column({ space: 3 }) {
        Text(DAYS[day - 1]).fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.dayDate(day).toDateString() === new Date(this.now).toDateString() ? this.theme().accent : this.theme().textSecondary)
        Text(`${this.dayDate(day).getMonth() + 1}/${this.dayDate(day).getDate()}`).fontSize(11)
          .fontColor(this.theme().textSecondary)
      }.height(46).width(86)
      ForEach(this.data.sections, (s: SectionTime) => {
        if (this.atStart(day, s.sectionNo)) {
          Column({ space: 4 }) {
            Text(this.atStart(day, s.sectionNo)!.name).fontSize(12).fontWeight(FontWeight.Bold)
              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).fontColor(Color.White)
            Text(this.atStart(day, s.sectionNo)!.location).fontSize(10).maxLines(1).fontColor(Color.White)
          }.alignItems(HorizontalAlign.Start).padding(7).width(82)
            .height(70 * (this.atStart(day, s.sectionNo)!.endSection - s.sectionNo + 1) - 4)
            .backgroundColor(this.theme().palette[this.atStart(day, s.sectionNo)!.colorIndex])
            .borderRadius(8).margin({ top: 2, bottom: 2 })
            .onClick(() => this.openCourse(this.atStart(day, s.sectionNo)!))
        } else if (!this.covered(day, s.sectionNo)) {
          Column().width(82).height(70).border({ width: 0.5, color: '#E1EAE4' })
        }
      }, (s: SectionTime) => `${s.sectionNo}`)
    }.width(86)
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Column() {
          Text('SchoolCalendar').fontSize(13).fontColor(this.theme().accent)
          Text(this.data.semester.name).fontSize(25).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text('⚙').fontSize(25).fontColor(this.theme().textPrimary)
          .onClick(() => router.pushUrl({ url: 'pages/Settings' }))
      }.width('100%')
      this.Upcoming()
      Row({ space: 16 }) {
        Text('‹').fontSize(29).fontColor(this.theme().accent).onClick(() => { this.shownWeek = Math.max(1, this.shownWeek - 1); })
        Text(`第 ${this.shownWeek} 周`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
        Text('›').fontSize(29).fontColor(this.theme().accent).onClick(() => { this.shownWeek = Math.min(this.data.semester.totalWeeks, this.shownWeek + 1); })
        Blank()
        Text('今天').fontSize(14).fontColor(this.theme().accent).onClick(() => { this.shownWeek = Math.max(1, Math.min(teachingWeek(this.data, new Date()), this.data.semester.totalWeeks)); })
      }.width('100%')
      Scroll() {
        Row().alignItems(VerticalAlign.Top) {
          Column() {
            Text('节').height(46).fontSize(12).fontColor(this.theme().textSecondary)
            ForEach(this.data.sections, (s: SectionTime) => {
              Column() {
                Text(`${s.sectionNo}${this.isCurrentSection(s.sectionNo) ? ' ●' : ''}`).fontSize(12).fontWeight(FontWeight.Bold)
                  .fontColor(this.isCurrentSection(s.sectionNo) ? '#E65B5B' : this.theme().textSecondary)
                Text(s.startTime).fontSize(9).fontColor(this.theme().textSecondary)
              }.width(46).height(70)
            }, (s: SectionTime) => `${s.sectionNo}`)
          }.width(46)
          ForEach([1, 2, 3, 4, 5, 6, 7], (d: number) => { this.DayColumn(d) }, (d: number) => `${d}`)
        }
      }.scrollable(ScrollDirection.Horizontal).width('100%').layoutWeight(1)
      Button('+ 添加课程').backgroundColor(this.theme().accent).fontColor(Color.White)
        .width('100%').height(52).borderRadius(15)
        .onClick(() => router.pushUrl({ url: 'pages/CourseEdit' }))
    }.padding(18).width('100%').height('100%').backgroundColor(this.theme().bg)
      .bindSheet(this.showDetail, this.CourseSheet(), { height: 390 })
  }
}
