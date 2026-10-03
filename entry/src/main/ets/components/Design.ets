import { curves, router } from '@kit.ArkUI';
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
      Text(this.label).fontSize(14).fontColor(this.theme.textSecondary).width('100%')
      TextInput({ text: this.value, placeholder: this.hint }).height(48).fontSize(16).borderRadius(16)
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
  @Prop tint: string = '#64738B';
  private symbol(): Resource {
    switch (this.name) {
      case 'back': return $r('sys.symbol.chevron_left');
      case 'next': return $r('sys.symbol.chevron_right');
      case 'close': return $r('sys.symbol.xmark');
      case 'settings': return $r('sys.symbol.gearshape');
      case 'clock': return $r('sys.symbol.clock');
      case 'location': return $r('sys.symbol.mappin_and_rectangle');
      case 'palette': return $r('sys.symbol.paintpalette');
      case 'book': return $r('sys.symbol.book');
      case 'sync': return $r('sys.symbol.arrow_clockwise');
      case 'widget': return $r('sys.symbol.square_grid_2x2');
      default: return $r('sys.symbol.calendar');
    }
  }
  build() {
    SymbolGlyph(this.symbol()).fontSize(this.iconSize).fontColor([this.tint])
      .renderingStrategy(SymbolRenderingStrategy.SINGLE).accessibilityLevel('no')
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
      AppIcon({ name: this.icon, iconSize: 24, tint: this.theme.textPrimary })
    }.width(48).height(48).backgroundColor(this.theme.surface).borderRadius(24).enabled(this.active)
      .opacity(this.active ? 1 : 0.35).accessibilityText(this.label)
      .scale({ x: this.pressed ? 0.95 : 1, y: this.pressed ? 0.95 : 1 })
      .animation({ curve: curves.responsiveSpringMotion() })
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
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        IconAction({ theme: this.theme, action: () => router.back() })
        Text(this.title).fontSize(26).fontWeight(FontWeight.Bold).fontColor(this.theme.textPrimary)
          .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').height(56)
      if (this.caption) {
        Text(this.caption).fontSize(14).fontColor(this.theme.textSecondary).width('100%')
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
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
      .fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.theme.cardBg)
      .backgroundColor(this.theme.accent).borderRadius(25)
      .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
      .animation({ curve: curves.responsiveSpringMotion() })
      .onTouch((event: TouchEvent) => { this.pressed = event.type === TouchType.Down; })
      .onClick(() => this.action())
  }
}
