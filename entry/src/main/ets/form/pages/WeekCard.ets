import { AppData, Course, defaultData, SectionTime, ThemeDef } from '../../model/Types';
import { addDays, coursesOn, parseDate, semesterMessage, teachingWeek } from '../../model/Schedule';
import { themeById } from '../../model/Themes';

const storage = new LocalStorage();

@Entry(storage)
@Component
struct WeekCard {
  @LocalStorageProp('payload') payload: string = '';
  @LocalStorageProp('dimension') dimension: string = '4';
  @LocalStorageProp('dark') dark: string = 'false';
  @State now: number = Date.now();
  private data(): AppData { return this.payload ? JSON.parse(this.payload) as AppData : defaultData(); }
  private theme(): ThemeDef { return themeById(this.data().themeId, this.dark === 'true'); }
  private week(): number { return teachingWeek(this.data(), new Date(this.now)); }
  private date(day: number): Date {
    return addDays(parseDate(this.data().semester.startDate), (this.week() - 1) * 7 + day - 1);
  }
  private color(day: number, section: number): string {
    let course = coursesOn(this.data(), this.date(day)).find((c: Course) => c.startSection <= section && c.endSection >= section);
    return course ? this.theme().palette[course.colorIndex] : this.theme().bg;
  }

  @Builder private GridDay(day: number) {
    Column({ space: 2 }) {
      Text('一二三四五六日'.split('')[day - 1]).fontSize(10).fontColor(this.theme().textPrimary).height(18)
      ForEach(this.data().sections, (s: SectionTime) => {
        Column().width('100%').height(12).backgroundColor(this.color(day, s.sectionNo)).borderRadius(2)
      }, (s: SectionTime) => `${s.sectionNo}`)
    }.layoutWeight(1)
  }

  build() {
    FormLink({ action: 'router', abilityName: 'EntryAbility', params: { focus: 'week' } }) {
      Column({ space: 9 }) {
        TextClock().format('HH:mm').fontSize(1).opacity(0)
          .onDateChange((value: number) => { this.now = value; })
        Text(semesterMessage(this.data(), new Date(this.now)) || `第 ${this.week()} 周 · 周课表`).fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().textPrimary).width('100%')
        if (this.data().courses.length === 0) {
          Text('打开应用，添加你的第一门课').fontSize(14).fontColor(this.theme().textSecondary)
        } else if (this.dimension === '3') {
          ForEach([0, 1], (offset: number) => {
            Column({ space: 4 }) {
              Text(`周${'日一二三四五六'.split('')[addDays(new Date(this.now), offset).getDay()]}`).fontSize(12).fontColor(this.theme().accent)
              ForEach(coursesOn(this.data(), addDays(new Date(this.now), offset)).slice(0, 4), (c: Course) => {
                Text(c.name).fontSize(12).fontColor(this.theme().textPrimary).maxLines(1)
                  .backgroundColor(this.theme().palette[c.colorIndex]).padding(3).borderRadius(4)
              }, (c: Course) => `${c.id}`)
            }.alignItems(HorizontalAlign.Start).width('100%')
          }, (offset: number) => `${offset}`)
        } else {
          Row({ space: 3 }) {
            ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => { this.GridDay(day) }, (day: number) => `${day}`)
          }.width('100%')
        }
      }.padding(13).width('100%').height('100%').backgroundColor(this.theme().cardBg).borderRadius(20)
    }
  }
}
