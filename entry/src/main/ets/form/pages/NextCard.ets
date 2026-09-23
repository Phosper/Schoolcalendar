import { AppData, Course, defaultData, ThemeDef } from '../../model/Types';
import { nextCourse, sectionFor, semesterMessage } from '../../model/Schedule';
import { themeById } from '../../model/Themes';

const storage = new LocalStorage();

@Entry(storage)
@Component
struct NextCard {
  @LocalStorageProp('payload') payload: string = '';
  @LocalStorageProp('dimension') dimension: string = '2';
  @LocalStorageProp('dark') dark: string = 'false';
  @State now: number = Date.now();

  private data(): AppData { return this.payload ? JSON.parse(this.payload) as AppData : defaultData(); }
  private theme(): ThemeDef { return themeById(this.data().themeId, this.dark === 'true'); }

  private title(): string {
    if (semesterMessage(this.data(), new Date(this.now))) return semesterMessage(this.data(), new Date(this.now));
    let item = nextCourse(this.data(), new Date(this.now));
    if (!item) return this.data().courses.length ? '未来两周没有课程' : '添加你的第一门课';
    return item.course.name;
  }

  private status(): string {
    if (semesterMessage(this.data(), new Date(this.now))) return '学期状态';
    let item = nextCourse(this.data(), new Date(this.now));
    if (!item) return '打开应用查看课表';
    if (item.start.getTime() <= this.now) return `进行中 · ${Math.ceil((item.end.getTime() - this.now) / 60000)} 分钟后下课`;
    if (item.date.toDateString() !== new Date(this.now).toDateString()) {
      return `周${'日一二三四五六'.split('')[item.date.getDay()]} ${sectionFor(this.data(), item.course.startSection).startTime}`;
    }
    return `${Math.ceil((item.start.getTime() - this.now) / 60000)} 分钟后上课`;
  }

  private detail(): string {
    let item = nextCourse(this.data(), new Date(this.now));
    if (!item) return '轻点卡片开始设置';
    return `${sectionFor(this.data(), item.course.startSection).startTime} · ${item.course.location || '地点未填写'}`;
  }

  build() {
    FormLink({ action: 'router', abilityName: 'EntryAbility', params: { focus: 'today' } }) {
      Column({ space: 6 }) {
        TextClock().format('HH:mm').fontSize(1).opacity(0)
          .onDateChange((value: number) => { this.now = value; })
        if (this.dimension !== '1') {
          Text('下一节课').fontSize(13).fontColor(this.theme().textSecondary).width('100%')
        }
        Text(this.status()).fontSize(this.dimension === '1' ? 17 : 19).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().accent).maxLines(1).width('100%')
        Text(this.title()).fontSize(this.dimension === '1' ? 15 : 20).fontWeight(FontWeight.Bold)
          .fontColor(this.theme().textPrimary).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        if (this.dimension !== '1') {
          Text(this.detail()).fontSize(12).fontColor(this.theme().textSecondary).maxLines(1).width('100%')
        }
      }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
        .padding(this.dimension === '1' ? 10 : 16).width('100%').height('100%')
        .backgroundColor(this.theme().cardBg).borderRadius(18)
    }
  }
}
