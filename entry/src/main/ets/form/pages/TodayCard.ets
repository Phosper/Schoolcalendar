import { AppData, Course, defaultData, ThemeDef } from '../../model/Types';
import { addDays, coursesOn, endOf, sectionFor, semesterMessage, startOf } from '../../model/Schedule';
import { themeById } from '../../model/Themes';

const storage = new LocalStorage();

@Entry(storage)
@Component
struct TodayCard {
  @LocalStorageProp('payload') payload: string = '';
  @LocalStorageProp('dimension') dimension: string = '3';
  @LocalStorageProp('dark') dark: string = 'false';
  @State now: number = Date.now();
  private data(): AppData { return this.payload ? JSON.parse(this.payload) as AppData : defaultData(); }
  private theme(): ThemeDef { return themeById(this.data().themeId, this.dark === 'true'); }

  private displayDate(): Date {
    let today = new Date(this.now);
    for (let offset = 0; offset <= 14; offset++) {
      let date = addDays(today, offset);
      let items = coursesOn(this.data(), date);
      if (items.some((c: Course) => endOf(this.data(), c, date).getTime() > this.now)) return date;
    }
    return today;
  }

  private items(): Course[] { return coursesOn(this.data(), this.displayDate()).slice(0, this.dimension === '2' ? 3 : 5); }

  private label(): string {
    let date = this.displayDate();
    let today = new Date(this.now);
    let prefix = date.toDateString() === today.toDateString() ? '今日' : '前瞻';
    return `${prefix} · ${date.getMonth() + 1}月${date.getDate()}日 周${'日一二三四五六'.split('')[date.getDay()]}`;
  }

  private state(c: Course): string {
    let date = this.displayDate();
    if (endOf(this.data(), c, date).getTime() <= this.now) return '✓';
    if (startOf(this.data(), c, date).getTime() <= this.now) return '▶';
    return '·';
  }

  build() {
    FormLink({ action: 'router', abilityName: 'EntryAbility', params: { focus: 'today' } }) {
      Column({ space: 8 }) {
        TextClock().format('HH:mm').fontSize(1).opacity(0)
          .onDateChange((value: number) => { this.now = value; })
        Text(this.label()).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.theme().textPrimary).width('100%')
        if (this.items().length === 0) {
          Text(semesterMessage(this.data(), new Date(this.now)) ||
            (this.data().courses.length === 0 ? '打开应用，添加你的第一门课' : '今天没有课 ☀️'))
            .fontSize(16).fontColor(this.theme().textSecondary).width('100%')
        }
        ForEach(this.items(), (c: Course) => {
          Row({ space: 6 }) {
            Text(this.state(c)).fontSize(14).fontColor(this.theme().accent).width(18)
            Text(sectionFor(this.data(), c.startSection).startTime).fontSize(12).fontColor(this.theme().textSecondary)
            Text(c.name).fontSize(14).fontWeight(this.state(c) === '▶' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.state(c) === '✓' ? this.theme().textSecondary : this.theme().textPrimary)
              .maxLines(1).layoutWeight(1)
            if (this.dimension !== '2') Text(c.location).fontSize(11).fontColor(this.theme().textSecondary).maxLines(1)
          }.width('100%').padding(6).backgroundColor(this.state(c) === '▶' ? this.theme().bg : this.theme().cardBg)
            .borderRadius(6)
        }, (c: Course) => `${c.id}`)
        if (coursesOn(this.data(), this.displayDate()).length > this.items().length) {
          Text(`还有 ${coursesOn(this.data(), this.displayDate()).length - this.items().length} 门`)
            .fontSize(11).fontColor(this.theme().textSecondary)
        }
      }.padding(14).width('100%').height('100%').backgroundColor(this.theme().cardBg).borderRadius(20)
    }
  }
}
