import { Repository } from '../data/Repository';
import { AppData, defaultData, ThemeDef } from '../model/Types';
import { THEMES, courseBackground, courseForeground, themeById } from '../model/Themes';
import { WidgetService } from '../form/WidgetService';
import { PageHeader } from '../components/Design';
import { syncSystemBars } from '../model/Appearance';

@Entry
@Component
struct Theme {
  @State data: AppData = defaultData();
  @State saving: boolean = false;
  @StorageProp('isDark') dark: boolean = false;
  aboutToAppear(): void { this.load(); }
  private async load(): Promise<void> {
    await Repository.get().init(getContext(this)); this.data = await Repository.get().load();
  }
  private current(): ThemeDef { return themeById(this.data.themeId, this.dark); }
  private async select(t: ThemeDef): Promise<void> {
    if (this.saving || this.data.themeId === t.id) return;
    this.saving = true;
    try {
      await Repository.get().saveSetting('themeId', t.id);
      let updated = await Repository.get().load();
      this.getUIContext().animateTo({ duration: 240, curve: Curve.EaseOut }, () => { this.data = updated; });
      AppStorage.setOrCreate('themeId', updated.themeId);
      await syncSystemBars(getContext(this), this.current());
      await WidgetService.notify(getContext(this), this.data, this.dark);
    } finally { this.saving = false; }
  }
  @Builder private ThemeTile(t: ThemeDef) {
    Column({ space: 10 }) {
      Column({ space: 8 }) {
        Row() {
          Column().width(32).height(4).backgroundColor(t.accent).borderRadius(2)
          Blank()
          Column().width(6).height(6).backgroundColor(t.accent).borderRadius(3)
        }.width('100%')
        Row({ space: 4 }) {
          Column({ space: 4 }) {
            Column().height(24).width('100%').borderRadius(5).backgroundColor(courseBackground(t, 6, t.id === 'deep_space'))
            Column().height(13).width('100%').borderRadius(4).backgroundColor(courseBackground(t, 3, t.id === 'deep_space'))
          }.layoutWeight(1)
          Column().height(42).layoutWeight(1).borderRadius(5).backgroundColor(courseBackground(t, 5, t.id === 'deep_space'))
          Column({ space: 4 }) {
            Column().height(13).width('100%').borderRadius(4).backgroundColor(t.cardBg)
            Column().height(24).width('100%').borderRadius(5).backgroundColor(courseBackground(t, 0, t.id === 'deep_space'))
          }.layoutWeight(1)
        }.width('100%')
      }.width('100%').padding(14).backgroundColor(t.bg).borderRadius(14)
      Row() {
        Text(t.name).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.current().textPrimary)
        Blank()
        Text(this.data.themeId === t.id ? '✓' : '').fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor(this.current().cardBg).width(20).height(20).textAlign(TextAlign.Center).borderRadius(7)
          .backgroundColor(this.data.themeId === t.id ? this.current().accent : this.current().surface)
      }.width('100%')
    }.padding(12).width('100%').backgroundColor(this.current().cardBg).borderRadius(19)
      .border({ width: this.data.themeId === t.id ? 2 : 1, color: this.data.themeId === t.id ? this.current().accent : this.current().line }).borderRadius(19)
      .onClick(() => this.select(t)).accessibilityText(`${t.name}${this.data.themeId === t.id ? '，已选中' : '，点击应用'}`)
  }
  build() {
    Column({ space: 14 }) {
      PageHeader({ title: '主题外观', caption: '给每一天，换一种心情', theme: this.current() })
      Column({ space: 8 }) {
        Text('预览你的下一节课').fontSize(11).fontColor(this.current().textSecondary).width('100%')
        Text('设计你的校园日常').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.current().textPrimary).width('100%')
        Row({ space: 8 }) {
          Text('08:00 — 09:40').fontSize(12).fontColor(this.current().accent)
          Blank()
          Text(this.current().name).fontSize(11).fontColor(this.current().textSecondary)
        }.width('100%')
      }.padding(20).backgroundColor(this.current().accentSoft).borderRadius(22).width('100%')
      Grid() {
        ForEach(THEMES, (t: ThemeDef) => {
          GridItem() { this.ThemeTile(t) }
        }, (t: ThemeDef) => t.id)
      }.columnsTemplate('1fr 1fr').columnsGap(12).rowsGap(12).layoutWeight(1).width('100%').scrollBar(BarState.Off)
      Text('外观自动适配系统深色模式').fontSize(11).fontColor(this.current().textSecondary)
    }.padding({ left: 20, right: 20, top: 12, bottom: 16 }).width('100%').height('100%').backgroundColor(this.current().bg)
  }
  pageTransition() {
    PageTransitionEnter({ duration: 260, curve: Curve.EaseOut }).opacity(0).translate({ x: 14 })
    PageTransitionExit({ duration: 180, curve: Curve.EaseIn }).opacity(0).translate({ x: -8 })
  }
}
