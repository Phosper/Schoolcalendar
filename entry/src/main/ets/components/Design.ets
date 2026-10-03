import { router } from '@kit.ArkUI';
import { ThemeDef } from '../model/Types';
import { themeById } from '../model/Themes';

@Component
export struct FormField {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop hint: string = '';
  @Prop numeric: boolean = false;
  @Prop limit: number = 2147483647;
  @Prop theme: ThemeDef = themeById('fresh_green');
  changed: (value: string) => void = () => {};
  build() {
    Column({ space: 8 }) {
      Text(this.label).fontSize(12).fontColor(this.theme.textSecondary).width('100%')
      TextInput({ text: this.value, placeholder: this.hint }).height(48).fontSize(15).borderRadius(12)
        .fontColor(this.theme.textPrimary).placeholderColor(this.theme.textSecondary)
        .backgroundColor(this.theme.surface).type(this.numeric ? InputType.Number : InputType.Normal)
        .maxLength(this.limit).onChange((value: string) => this.changed(value))
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct AppIcon {
  @Prop name: string = 'calendar';
  @Prop iconSize: number = 20;
  build() {
    Image($rawfile(`${this.name}.svg`)).width(this.iconSize).height(this.iconSize)
      .objectFit(ImageFit.Contain).accessibilityLevel('no')
  }
}

@Component
export struct IconAction {
  @Prop icon: string = 'back';
  @Prop label: string = '返回';
  @Prop theme: ThemeDef = themeById('fresh_green');
  @Prop active: boolean = true;
  @State pressed: boolean = false;
  action: () => void = () => {};
  build() {
    Button({ type: ButtonType.Normal }) {
      AppIcon({ name: this.icon, iconSize: 20 })
    }.width(42).height(42).borderRadius(14).backgroundColor(this.theme.cardBg)
      .border({ width: 1, color: this.theme.line }).borderRadius(14).enabled(this.active)
      .opacity(this.active ? 1 : 0.35).accessibilityText(this.label)
      .scale({ x: this.pressed ? 0.92 : 1, y: this.pressed ? 0.92 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => { this.pressed = event.type === TouchType.Down; })
      .onClick(() => this.action())
  }
}

@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop caption: string = '';
  @Prop theme: ThemeDef = themeById('fresh_green');
  build() {
    Row({ space: 12 }) {
      IconAction({ theme: this.theme, action: () => router.back() })
      Column({ space: 3 }) {
        Text(this.title).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.theme.textPrimary)
        if (this.caption) {
          Text(this.caption).fontSize(12).fontColor(this.theme.textSecondary)
        }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }.width('100%').padding({ top: 6, bottom: 8 })
  }
}

@Component
export struct PrimaryAction {
  @Prop label: string = '';
  @Prop theme: ThemeDef = themeById('fresh_green');
  @State pressed: boolean = false;
  action: () => void = () => {};
  build() {
    Button(this.label, { type: ButtonType.Normal }).width('100%').height(50)
      .fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.theme.cardBg)
      .backgroundColor(this.theme.accent).borderRadius(16)
      .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => { this.pressed = event.type === TouchType.Down; })
      .onClick(() => this.action())
  }
}
