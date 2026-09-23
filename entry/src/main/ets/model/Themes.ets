import { ThemeDef } from './Types';

const BASE_COLORS: string[] = ['#E87272', '#F4A45C', '#D9BA4C', '#60B68A', '#50AFB5',
  '#6A96D7', '#9C80C8', '#DB83A9', '#A48B74', '#949BA0'];

export const THEMES: ThemeDef[] = [
  { id: 'fresh_green', name: '清新薄荷', bg: '#F2F8F4', cardBg: '#FFFFFF', textPrimary: '#173B31', textSecondary: '#72867D', accent: '#4AAB85', palette: BASE_COLORS },
  { id: 'sakura_pink', name: '樱花粉', bg: '#FFF4F7', cardBg: '#FFFFFF', textPrimary: '#4E2F3A', textSecondary: '#927581', accent: '#DB83A9', palette: BASE_COLORS },
  { id: 'deep_space', name: '深空黑', bg: '#101720', cardBg: '#1B2632', textPrimary: '#F2F6FC', textSecondary: '#A9B8C8', accent: '#70B7EE', palette: BASE_COLORS },
  { id: 'aurora_purple', name: '渐变紫', bg: '#F7F3FD', cardBg: '#FFFFFF', textPrimary: '#34274D', textSecondary: '#87769E', accent: '#9C80C8', palette: BASE_COLORS },
  { id: 'minimal_white', name: '极简白', bg: '#F5F5F5', cardBg: '#FFFFFF', textPrimary: '#252525', textSecondary: '#777777', accent: '#555555', palette: BASE_COLORS },
  { id: 'lemon_yellow', name: '柠檬黄', bg: '#FFFBEF', cardBg: '#FFFFFF', textPrimary: '#463B24', textSecondary: '#8A8068', accent: '#C8A535', palette: BASE_COLORS },
  { id: 'ocean_blue', name: '海空蓝', bg: '#F1F8FF', cardBg: '#FFFFFF', textPrimary: '#233A53', textSecondary: '#758B9C', accent: '#5B9BCC', palette: BASE_COLORS },
  { id: 'sunset_orange', name: '落日橙', bg: '#FFF6F0', cardBg: '#FFFFFF', textPrimary: '#53382C', textSecondary: '#987C6E', accent: '#E78C62', palette: BASE_COLORS },
  { id: 'academy_green', name: '墨绿学院', bg: '#EEF3EF', cardBg: '#FFFFFF', textPrimary: '#1F3A2B', textSecondary: '#718779', accent: '#326D52', palette: BASE_COLORS },
  { id: 'cherry_red', name: '樱桃红', bg: '#FFF3F3', cardBg: '#FFFFFF', textPrimary: '#502A34', textSecondary: '#977681', accent: '#D6576B', palette: BASE_COLORS }
];

export function themeById(id: string, dark: boolean = false): ThemeDef {
  let theme = THEMES.find((t: ThemeDef) => t.id === id) ?? THEMES[0];
  if (!dark || id === 'deep_space') return theme;
  return {
    id: theme.id, name: theme.name, bg: '#121A1D', cardBg: '#1D2A2D',
    textPrimary: '#F2F7F5', textSecondary: '#A9BDB5', accent: theme.accent,
    palette: BASE_COLORS
  };
}
