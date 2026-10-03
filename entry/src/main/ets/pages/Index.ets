import { curves, router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, Course, defaultData, SectionTime, ThemeDef } from '../model/Types';
import { addDays, coursesOn, minutes, nextCourse, parseDate, sectionFor, semesterMessage, teachingWeek } from '../model/Schedule';
import { courseBackground, courseForeground, themeById } from '../model/Themes';
import { WidgetService } from '../form/WidgetService';
import { AppIcon, IconAction, PrimaryAction } from '../components/Design';
import { syncSystemBars } from '../model/Appearance';

const DAYS: string[] = ['一', '二', '三', '四', '五', '六', '日'];

@Entry
@Component
struct Index {
  @State data: AppData = defaultData();
  @State shownWeek: number = 0;
  @State now: number = Date.now();
  @State expanded: boolean = false;
  @State ready: boolean = false;
  @State gridOpacity: number = 1;
  @State weekTranslation: number = 0;
  @State gridWidth: number = 0;
  @StorageProp('isDark') dark: boolean = false;
  @State showDetail: boolean = false;
  @State selectedCourse: Course = { id: 0, name: '', teacher: '', location: '', dayOfWeek: 1,
    startSection: 1, endSection: 1, weekPattern: 'all', weeksMask: '', colorIndex: 0 };
  private ticker: number = 0;
  private horizontalScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.refresh();
    this.ticker = setInterval(() => { this.now = Date.now(); }, 60000);
  }
  aboutToDisappear(): void { clearInterval(this.ticker); }
  onPageShow(): void { this.now = Date.now(); this.refresh(); }

  private async refresh(): Promise<void> {
    await Repository.get().init(getContext(this));
    this.data = await Repository.get().load();
    AppStorage.setOrCreate('themeId', this.data.themeId);
    await syncSystemBars(getContext(this), this.theme());
    let w = teachingWeek(this.data, new Date());
    if (this.shownWeek < 1 || this.shownWeek > this.data.semester.totalWeeks || this.data.courses.length === 0) {
      this.shownWeek = Math.max(1, Math.min(w, this.data.semester.totalWeeks));
    }
    this.getUIContext().animateTo({ duration: 350, curve: Curve.EaseOut }, () => { this.ready = true; });
  }
  private theme(): ThemeDef { return themeById(this.data.themeId, this.dark); }
  private dayDate(day: number): Date {
    return addDays(parseDate(this.data.semester.startDate), (this.shownWeek - 1) * 7 + day - 1);
  }
  private isToday(day: number): boolean { return this.dayDate(day).toDateString() === new Date(this.now).toDateString(); }
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
  private weekCount(): number {
    let count = 0;
    for (let day = 1; day <= 7; day++) count += coursesOn(this.data, this.dayDate(day)).length;
    return count;
  }
  private weekRange(): string {
    let start = this.dayDate(1);
    let end = this.dayDate(7);
    return `${start.getMonth() + 1}.${start.getDate()} — ${end.getMonth() + 1}.${end.getDate()}`;
  }
  private changeWeek(value: number): void {
    let target = Math.max(1, Math.min(value, this.data.semester.totalWeeks));
    if (target === this.shownWeek) return;
    this.weekTranslation = target > this.shownWeek ? 12 : -12;
    this.gridOpacity = 0.45;
    this.shownWeek = target;
    this.getUIContext().animateTo({ curve: curves.springMotion(0.35, 0.9) }, () => {
      this.weekTranslation = 0; this.gridOpacity = 1;
    });
  }
  private upcomingStatus(): string {
    let item = nextCourse(this.data, new Date(this.now));
    if (!item || semesterMessage(this.data, new Date(this.now))) return '学期概览';
    if (item.start.getTime() <= this.now) return '正在上课';
    if (item.date.toDateString() === new Date(this.now).toDateString()) {
      let wait = Math.ceil((item.start.getTime() - this.now) / 60000);
      return wait < 60 ? `${wait} 分钟后` : '今日待上';
    }
    return '下一节课';
  }
  private openCourse(course: Course): void { this.selectedCourse = course; this.showDetail = true; }
  private deleteSelected(): void {
    AlertDialog.show({ title: '删除课程', message: `确定删除「${this.selectedCourse.name}」吗？`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', action: () => { this.confirmDelete(); } } });
  }
  private async confirmDelete(): Promise<void> {
    await Repository.get().deleteCourse(this.selectedCourse.id);
    this.data = await Repository.get().load();
    await WidgetService.notify(getContext(this), this.data, this.dark);
    this.showDetail = false;
  }

  @Builder private CourseSheet() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Column().width(8).height(8).borderRadius(4)
          .backgroundColor(courseForeground(this.theme(), this.selectedCourse.colorIndex, this.dark))
        Text('课程详情').fontSize(12).fontColor(this.theme().textSecondary)
        Blank()
        Button({ type: ButtonType.Normal }) {
          AppIcon({ name: 'close', iconSize: 20, tint: this.theme().textPrimary })
        }.width(40).height(40).backgroundColor(this.theme().surface).borderRadius(20)
          .onClick(() => { this.showDetail = false; }).accessibilityText('关闭课程详情')
      }.width('100%')
      Text(this.selectedCourse.name).fontSize(26).fontWeight(FontWeight.Bold)
        .fontColor(this.theme().textPrimary).width('100%').maxLines(2)
      Text(`${this.selectedCourse.location || '地点未填写'} · ${this.selectedCourse.teacher || '教师未填写'}`)
        .fontSize(14).fontColor(this.theme().textSecondary).width('100%')
      Row({ space: 12 }) {
        AppIcon({ name: 'clock', tint: this.theme().accent })
        Column({ space: 5 }) {
          Text(`周${DAYS[this.selectedCourse.dayOfWeek - 1]} · 第 ${this.selectedCourse.startSection}-${this.selectedCourse.endSection} 节`)
            .fontSize(16).fontColor(this.theme().textPrimary)
          Text(`${sectionFor(this.data, this.selectedCourse.startSection).startTime} — ${sectionFor(this.data, this.selectedCourse.endSection).endTime}`)
            .fontSize(13).fontColor(this.theme().textSecondary)
        }.alignItems(HorizontalAlign.Start)
      }.width('100%').padding(16).backgroundColor(this.theme().surface).borderRadius(16)
      Row({ space: 8 }) {
        Text(`上课周次 · ${this.selectedCourse.weekPattern === 'all' ? '每周' : this.selectedCourse.weekPattern === 'odd' ? '单周' : this.selectedCourse.weekPattern === 'even' ? '双周' : this.selectedCourse.weeksMask}`)
          .fontSize(13).fontColor(this.theme().textSecondary).layoutWeight(1).maxLines(2)
        Text(coursesOn(this.data, this.dayDate(this.selectedCourse.dayOfWeek)).some((c: Course) => c.id === this.selectedCourse.id) ? '本周有课' : '本周无课')
          .fontSize(12).fontColor(this.theme().accent).padding(7).backgroundColor(this.theme().accentSoft).borderRadius(8)
      }.width('100%')
      Row({ space: 12 }) {
        Button('编辑课程', { type: ButtonType.Normal }).layoutWeight(2).height(48).borderRadius(14)
          .backgroundColor(this.theme().accent).fontColor(this.theme().cardBg)
          .onClick(() => { this.showDetail = false; router.pushUrl({ url: 'pages/CourseEdit', params: { id: this.selectedCourse.id } }); })
        Button('删除', { type: ButtonType.Normal }).layoutWeight(1).height(48).borderRadius(14)
          .backgroundColor(this.theme().surface).fontColor(this.dark || this.data.themeId === 'deep_space' ? '#FFA6AF' : '#AD4E61')
          .onClick(() => this.deleteSelected())
      }.width('100%')
    }.padding(24).width('100%').backgroundColor(this.theme().cardBg)
  }

  @Builder private Upcoming() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        AppIcon({ name: 'calendar', iconSize: 20, tint: this.theme().accent })
        Text('学习日程').fontSize(12).fontColor(this.theme().textSecondary)
        Blank()
        Text(this.upcomingStatus()).fontSize(12).fontWeight(FontWeight.Medium)
          .fontColor(this.theme().accent).padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.theme().cardBg).borderRadius(8)
      }.width('100%')
      if (semesterMessage(this.data, new Date(this.now))) {
        Text(semesterMessage(this.data, new Date(this.now))).fontSize(23).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().textPrimary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      } else if (nextCourse(this.data, new Date(this.now))) {
        Text(nextCourse(this.data, new Date(this.now))!.course.name).fontSize(25).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().textPrimary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          AppIcon({ name: 'clock', iconSize: 16, tint: this.theme().textSecondary })
          Text(`${sectionFor(this.data, nextCourse(this.data, new Date(this.now))!.course.startSection).startTime} · ${nextCourse(this.data, new Date(this.now))!.date.getMonth() + 1}/${nextCourse(this.data, new Date(this.now))!.date.getDate()}`)
            .fontSize(12).fontColor(this.theme().textSecondary)
          AppIcon({ name: 'location', iconSize: 16, tint: this.theme().textSecondary }).margin({ left: 6 })
          Text(nextCourse(this.data, new Date(this.now))!.course.location || '地点待补充')
            .fontSize(12).fontColor(this.theme().textSecondary).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        }.width('100%')
      } else {
        Text(this.data.courses.length === 0 ? '新学期，从容开始。' : '留一点时间给自己。')
          .fontSize(23).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
        Text(this.data.courses.length === 0 ? '添加课程，让每一天都有清晰的安排' : '未来两周暂无课程，享受课余时光')
          .fontSize(12).fontColor(this.theme().textSecondary)
      }
    }.alignItems(HorizontalAlign.Start).padding(18).width('100%')
      .backgroundColor(this.theme().accentSoft).borderRadius(22)
      .onClick(() => {
        let upcoming = nextCourse(this.data, new Date(this.now));
        if (upcoming && !semesterMessage(this.data, new Date(this.now))) this.openCourse(upcoming.course);
      })
      .accessibilityText('学习日程，点击查看下一节课详情')
  }

  @Builder private DayColumn(day: number) {
    Column() {
      Column({ space: 5 }) {
        Text(`周${DAYS[day - 1]}`).fontSize(12).fontColor(this.isToday(day) ? this.theme().accent : this.theme().textSecondary)
        Text(`${this.dayDate(day).getDate()}`).fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor(this.isToday(day) ? this.theme().cardBg : this.theme().textPrimary)
          .width(28).height(28).textAlign(TextAlign.Center).borderRadius(10)
          .backgroundColor(this.isToday(day) ? this.theme().accent : Color.Transparent)
      }.height(64).width('100%').justifyContent(FlexAlign.Center)
      ForEach(this.data.sections, (s: SectionTime) => {
        if (this.atStart(day, s.sectionNo)) {
          Button({ type: ButtonType.Normal }) {
            Column({ space: 5 }) {
              Text(this.atStart(day, s.sectionNo)!.name).fontSize(this.expanded ? 14 : 12).fontWeight(FontWeight.Medium)
                .maxLines(this.expanded ? 2 : 4).textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontColor(courseForeground(this.theme(), this.atStart(day, s.sectionNo)!.colorIndex, this.dark))
              if (this.expanded && this.atStart(day, s.sectionNo)!.location) {
                Text(this.atStart(day, s.sectionNo)!.location).fontSize(12).maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontColor(courseForeground(this.theme(), this.atStart(day, s.sectionNo)!.colorIndex, this.dark))
              }
            }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
              .padding({ left: this.expanded ? 5 : 2, right: this.expanded ? 3 : 2, top: 8 })
              .width('100%').height('100%')
          }.width('100%').height(64 * (this.atStart(day, s.sectionNo)!.endSection - s.sectionNo + 1) - 4)
            .backgroundColor(courseBackground(this.theme(), this.atStart(day, s.sectionNo)!.colorIndex, this.dark))
            .borderRadius(8).margin({ top: 2, bottom: 2 })
            .border({ width: { left: 2 }, color: courseForeground(this.theme(), this.atStart(day, s.sectionNo)!.colorIndex, this.dark) }).borderRadius(8)
            .onClick(() => this.openCourse(this.atStart(day, s.sectionNo)!))
            .accessibilityText(`${this.atStart(day, s.sectionNo)!.name}，周${DAYS[day - 1]}，第${s.sectionNo}节开始，点击查看详情`)
        } else if (!this.covered(day, s.sectionNo)) {
          Column().width('100%').height(64).border({ width: { bottom: 0.5 }, color: this.theme().line })
        }
      }, (s: SectionTime) => `${s.sectionNo}`)
    }.layoutWeight(1).margin({ left: 1, right: 1 })
      .backgroundColor(this.isToday(day) ? this.theme().surface : Color.Transparent)
      .borderRadius(12)
  }

  @Builder private EmptyState() {
    Column({ space: 14 }) {
      AppIcon({ name: 'book', iconSize: 36, tint: this.theme().accent })
      Text('你的课表，等你来填').fontSize(19).fontWeight(FontWeight.Medium).fontColor(this.theme().textPrimary)
      Text('先设置学期，再添加第一门课程\n每周的安排会自动出现在这里')
        .fontSize(13).lineHeight(22).textAlign(TextAlign.Center).fontColor(this.theme().textSecondary)
      Button('设置学期', { type: ButtonType.Normal }).fontSize(13).height(40)
        .backgroundColor(this.theme().accentSoft).fontColor(this.theme().accent).borderRadius(12)
        .onClick(() => router.pushUrl({ url: 'pages/SemesterSetting' }))
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      .backgroundColor(this.theme().cardBg).borderRadius(22)
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 4 }) {
          Text('我的课表').fontSize(26).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
          Text(this.data.semester.name).fontSize(14).fontColor(this.theme().textSecondary)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        IconAction({ icon: 'settings', label: '打开设置', theme: this.theme(),
          action: () => router.pushUrl({ url: 'pages/Settings' }) })
      }.width('100%').height(56)
      this.Upcoming()
      Row({ space: 8 }) {
        Column({ space: 4 }) {
          Text(`第 ${this.shownWeek} 周`).fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary)
          Text(this.weekRange()).fontSize(12).fontColor(this.theme().textSecondary)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        IconAction({ icon: 'back', label: '上一周', theme: this.theme(), active: this.shownWeek > 1,
          action: () => this.changeWeek(this.shownWeek - 1) })
        IconAction({ icon: 'next', label: '下一周', theme: this.theme(), active: this.shownWeek < this.data.semester.totalWeeks,
          action: () => this.changeWeek(this.shownWeek + 1) })
        Button('今天', { type: ButtonType.Normal }).height(48).fontSize(14).borderRadius(24)
          .fontColor(this.theme().accent).backgroundColor(this.theme().accentSoft)
          .onClick(() => this.changeWeek(teachingWeek(this.data, new Date(this.now))))
      }.width('100%')
      if (this.data.courses.length === 0) {
        Column() { this.EmptyState() }.layoutWeight(1).width('100%')
      } else {
        Column({ space: 10 }) {
          Row() {
            Column({ space: 3 }) {
              Text(`本周 ${this.weekCount()} 次课`).fontSize(12).fontColor(this.theme().textSecondary)
              Text(this.expanded ? '左右滑动' : '上下滑动').fontSize(12).fontColor(this.theme().textSecondary)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Row({ space: 2 }) {
              ForEach(['全周', '展开'], (label: string, index: number) => {
                Button(label, { type: ButtonType.Normal }).fontSize(14).height(40).borderRadius(20)
                  .backgroundColor(this.expanded === (index === 1) ? this.theme().cardBg : Color.Transparent)
                  .fontColor(this.expanded === (index === 1) ? this.theme().textPrimary : this.theme().textSecondary)
                  .onClick(() => {
                    this.horizontalScroller.scrollTo({ xOffset: 0, yOffset: 0 });
                    this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseOut }, () => { this.expanded = index === 1; });
                  })
              }, (label: string) => label)
            }.padding(3).backgroundColor(this.theme().surface).borderRadius(23)
          }.width('100%')
          Scroll() {
            Scroll(this.horizontalScroller) {
              Row() {
                Column() {
                  Text('节次').height(64).fontSize(12).fontColor(this.theme().textSecondary)
                  ForEach(this.data.sections, (s: SectionTime) => {
                    Column({ space: 4 }) {
                      Text(`${s.sectionNo}`).fontSize(12).fontWeight(FontWeight.Medium)
                        .fontColor(this.isCurrentSection(s.sectionNo) ? this.theme().accent : this.theme().textSecondary)
                      Text(sectionFor(this.data, s.sectionNo).startTime).fontSize(12).fontColor(this.theme().textSecondary)
                    }.width(this.expanded ? 48 : 32).height(64).justifyContent(FlexAlign.Center)
                      .backgroundColor(this.isCurrentSection(s.sectionNo) ? this.theme().accentSoft : Color.Transparent).borderRadius(8)
                  }, (s: SectionTime) => `${s.sectionNo}`)
                }.width(this.expanded ? 48 : 32)
                ForEach([1, 2, 3, 4, 5, 6, 7], (d: number) => { this.DayColumn(d) }, (d: number) => `${d}`)
              }.alignItems(VerticalAlign.Top).width(this.expanded ? Math.max(650, this.gridWidth) : '100%')
            }.scrollable(this.expanded ? ScrollDirection.Horizontal : ScrollDirection.None).scrollBar(BarState.Off).width('100%')
              .onAreaChange((oldArea: Area, newArea: Area) => { this.gridWidth = Number(newArea.width); })
          }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).width('100%').layoutWeight(1)
            .opacity(this.gridOpacity).translate({ x: this.weekTranslation })
        }.padding(8).width('100%').layoutWeight(1).backgroundColor(this.theme().cardBg)
          .border({ width: 1, color: this.theme().line }).borderRadius(22).clip(true)
      }
      PrimaryAction({ label: '添加课程', theme: this.theme(), action: () => router.pushUrl({ url: 'pages/CourseEdit' }) })
    }.padding({ left: 16, right: 16, top: 12, bottom: 16 }).width('100%').height('100%')
      .backgroundColor(this.theme().bg).opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 12 })
      .bindSheet(this.showDetail, this.CourseSheet(), { height: SheetSize.FIT_CONTENT, showClose: false, backgroundColor: this.theme().cardBg })
  }
}
