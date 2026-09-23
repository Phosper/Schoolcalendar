import { router } from '@kit.ArkUI';
import { Repository } from '../data/Repository';
import { AppData, defaultData, ThemeDef } from '../model/Types';
import { THEMES, themeById } from '../model/Themes';
import { WidgetService } from '../form/WidgetService';

@Entry
@Component
struct Theme {
  @State data: AppData = defaultData();
  @StorageProp('isDark') dark: boolean = false;
  aboutToAppear(): void { this.load(); }
  private async load(): Promise<void> {
    await Repository.get().init(getContext(this)); this.data = await Repository.get().load();
  }
  private current(): ThemeDef { return themeById(this.data.themeId, this.dark); }
  private async select(t: ThemeDef): Promise<void> {
    await Repository.get().saveSetting('themeId', t.id);
    this.data = await Repository.get().load();
    await WidgetService.notify(getContext(this), this.data, this.dark);
  }
  build() {
    Column({ space: 14 }) {
      Row() { Text('‹').fontSize(30).fontColor(this.current().accent).onClick(() => router.back())
        Text('主题').fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 14 }) }.width('100%')
      Text('选择主题后，课表颜色立即更新').fontSize(14).fontColor(this.current().textSecondary).width('100%')
      Scroll() {
        Column({ space: 10 }) {
          ForEach(THEMES, (t: ThemeDef) => {
            Row({ space: 14 }) {
              Column() {
                Row({ space: 3 }) {
                  ForEach(t.palette.slice(0, 4), (c: string) => { Column().width(17).height(28).backgroundColor(c).borderRadius(3) }, (c: string) => c)
                }
              }.width(88).height(58).justifyContent(FlexAlign.Center).backgroundColor(t.bg).borderRadius(9)
              Text(t.name).fontSize(16).fontColor(t.textPrimary)
              Blank()
              if (this.data.themeId === t.id) Text('✓').fontSize(20).fontColor(t.accent)
            }.padding(12).width('100%').backgroundColor(t.cardBg).borderRadius(13)
              .onClick(() => this.select(t))
          }, (t: ThemeDef) => t.id)
        }.width('100%')
      }.layoutWeight(1)
    }.padding(18).width('100%').height('100%').backgroundColor(this.current().bg)
  }
}
