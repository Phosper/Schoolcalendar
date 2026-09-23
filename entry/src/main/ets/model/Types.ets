export interface Course {
  id: number;
  name: string;
  teacher: string;
  location: string;
  dayOfWeek: number;
  startSection: number;
  endSection: number;
  weekPattern: string;
  weeksMask: string;
  colorIndex: number;
}

export interface SectionTime {
  sectionNo: number;
  startTime: string;
  endTime: string;
}

export interface Semester {
  name: string;
  startDate: string;
  totalWeeks: number;
}

export interface AppData {
  courses: Course[];
  sections: SectionTime[];
  semester: Semester;
  themeId: string;
  reminderMinutes: number;
  calendarSyncEnabled: boolean;
}

export interface ThemeDef {
  id: string;
  name: string;
  bg: string;
  cardBg: string;
  textPrimary: string;
  textSecondary: string;
  accent: string;
  palette: string[];
}

export const DEFAULT_SECTIONS: SectionTime[] = [
  { sectionNo: 1, startTime: '08:00', endTime: '08:45' },
  { sectionNo: 2, startTime: '08:55', endTime: '09:40' },
  { sectionNo: 3, startTime: '10:00', endTime: '10:45' },
  { sectionNo: 4, startTime: '10:55', endTime: '11:40' },
  { sectionNo: 5, startTime: '11:45', endTime: '12:30' },
  { sectionNo: 6, startTime: '14:00', endTime: '14:45' },
  { sectionNo: 7, startTime: '14:30', endTime: '15:15' },
  { sectionNo: 8, startTime: '15:20', endTime: '16:05' },
  { sectionNo: 9, startTime: '16:15', endTime: '17:00' },
  { sectionNo: 10, startTime: '17:05', endTime: '17:50' },
  { sectionNo: 11, startTime: '19:00', endTime: '19:45' },
  { sectionNo: 12, startTime: '19:50', endTime: '20:35' }
];

export function defaultSemester(): Semester {
  let date = new Date();
  let day = date.getDay();
  date.setDate(date.getDate() - (day === 0 ? 6 : day - 1));
  let month = date.getMonth() + 1;
  let dayNo = date.getDate();
  return { name: `${date.getFullYear()} 学期`,
    startDate: `${date.getFullYear()}-${month < 10 ? '0' : ''}${month}-${dayNo < 10 ? '0' : ''}${dayNo}`,
    totalWeeks: 20 };
}

export function defaultData(): AppData {
  return { courses: [], sections: DEFAULT_SECTIONS, semester: defaultSemester(),
    themeId: 'fresh_green', reminderMinutes: 15, calendarSyncEnabled: false };
}
