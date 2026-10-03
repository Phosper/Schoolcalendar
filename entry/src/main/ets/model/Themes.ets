import { ThemeDef } from './Types';

// Shared by the app and widgets; keep palette indices stable for saved courses.
const BASE_COLORS: string[] = ['#AD4E61', '#A7622F', '#887021', '#337D68', '#287C88',
  '#486EB0', '#795CAD', '#AA527F', '#856950', '#64738B'];

export function blend(color: string, base: string, amount: number): string {
  let result = '#';
  for (let i = 1; i < 7; i += 2) {
    let value = Math.round(parseInt(color.slice(i, i + 2), 16) * amount +
      parseInt(base.slice(i, i + 2), 16) * (1 - amount));
    result += value.toString(16).padStart(2, '0');
  }
  return result;
}

function defineTheme(id: string, name: string, bg: string, card: string, text: string,
  secondary: string, accent: string): ThemeDef {
  return { id: id, name: name, bg: bg, cardBg: card, textPrimary: text,
    textSecondary: card === '#FFFFFF' ? blend(secondary, text, 0.80) : secondary, accent: accent, palette: BASE_COLORS,
    line: blend(text, card, 0.09), surface: blend(text, card, 0.035),
    accentSoft: blend(accent, card, 0.10) };
}

export const THEMES: ThemeDef[] = [
  defineTheme('fresh_green', '清新薄荷', '#F4F7F6', '#FFFFFF', '#202E2A', '#65776E', '#287961'),
  defineTheme('sakura_pink', '樱花粉', '#FAF5F7', '#FFFFFF', '#382B34', '#82707B', '#AB4876'),
  defineTheme('deep_space', '深空黑', '#14161D', '#20232D', '#EFF0F7', '#A6ACBE', '#B5A4F6'),
  defineTheme('aurora_purple', '柔雾紫', '#F6F5FA', '#FFFFFF', '#292738', '#79768D', '#7359B8'),
  defineTheme('minimal_white', '极简白', '#F5F6F8', '#FFFFFF', '#242831', '#6C7483', '#48536A'),
  defineTheme('lemon_yellow', '柠檬黄', '#FAF8F0', '#FFFFFF', '#373226', '#817966', '#88701D'),
  defineTheme('ocean_blue', '海空蓝', '#F3F6FA', '#FFFFFF', '#273246', '#6C7A91', '#3A6CA8'),
  defineTheme('sunset_orange', '落日橙', '#FAF6F2', '#FFFFFF', '#3B2F29', '#8A786C', '#AD602D'),
  defineTheme('academy_green', '墨绿学院', '#F1F5F2', '#FFFFFF', '#25352C', '#697C70', '#326B4E'),
  defineTheme('cherry_red', '樱桃红', '#FAF4F5', '#FFFFFF', '#3D2A32', '#8A6C77', '#B04362')
];

export function themeById(id: string, dark: boolean = false): ThemeDef {
  let theme = THEMES.find((t: ThemeDef) => t.id === id) ?? THEMES[0];
  if (!dark || id === 'deep_space') return theme;
  return defineTheme(theme.id, theme.name, '#14171C', '#20262D', '#EFF3F5', '#A5B1BB',
    blend(theme.accent, '#FFFFFF', 0.55));
}

export function courseBackground(theme: ThemeDef, index: number, dark: boolean): string {
  return blend(theme.palette[index] ?? theme.accent, theme.cardBg, dark || theme.id === 'deep_space' ? 0.30 : 0.12);
}

export function courseForeground(theme: ThemeDef, index: number, dark: boolean): string {
  let color = theme.palette[index] ?? theme.accent;
  return dark || theme.id === 'deep_space' ? blend(color, '#FFFFFF', 0.40) : blend(color, theme.textPrimary, 0.82);
}
