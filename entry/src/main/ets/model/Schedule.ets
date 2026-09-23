import { AppData, Course, SectionTime } from './Types';

export function parseDate(value: string): Date {
  let p = value.split('-').map((x: string) => Number(x));
  return new Date(p[0], p[1] - 1, p[2]);
}

export function dateKey(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function pad(n: number): string { return n < 10 ? `0${n}` : `${n}`; }

export function addDays(date: Date, days: number): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);
}

export function teachingWeek(data: AppData, date: Date): number {
  let start = parseDate(data.semester.startDate);
  let current = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  return Math.floor((current.getTime() - start.getTime()) / 604800000) + 1;
}

export function semesterMessage(data: AppData, date: Date): string {
  let week = teachingWeek(data, date);
  if (week < 1) {
    let today = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    let days = Math.ceil((parseDate(data.semester.startDate).getTime() - today.getTime()) / 86400000);
    return `距开学还有 ${days} 天`;
  }
  if (week > data.semester.totalWeeks) return '本学期已结束';
  return '';
}

export function weekContains(course: Course, week: number): boolean {
  if (week < 1) return false;
  if (course.weekPattern === 'odd') return week % 2 === 1;
  if (course.weekPattern === 'even') return week % 2 === 0;
  if (course.weekPattern === 'custom') {
    for (let part of course.weeksMask.split(',')) {
      let bounds = part.trim().split('-');
      if (bounds.length === 1 && Number(bounds[0]) === week) return true;
      if (bounds.length === 2 && week >= Number(bounds[0]) && week <= Number(bounds[1])) return true;
    }
    return false;
  }
  return true;
}

export function validWeeksMask(mask: string, totalWeeks: number): boolean {
  let parts = mask.split(',');
  if (parts.length === 0) return false;
  for (let part of parts) {
    let value = part.trim();
    if (!/^\d+(?:-\d+)?$/.test(value)) return false;
    let bounds = value.split('-').map((n: string) => Number(n));
    if (bounds[0] < 1 || bounds[0] > totalWeeks) return false;
    if (bounds.length === 2 && (bounds[1] < bounds[0] || bounds[1] > totalWeeks)) return false;
  }
  return true;
}

export function coursesOn(data: AppData, date: Date): Course[] {
  let week = teachingWeek(data, date);
  if (week < 1 || week > data.semester.totalWeeks) return [];
  let day = date.getDay() === 0 ? 7 : date.getDay();
  return data.courses.filter((c: Course) => c.dayOfWeek === day && weekContains(c, week))
    .sort((a: Course, b: Course) => a.startSection - b.startSection);
}

export function minutes(time: string): number {
  let p = time.split(':');
  return Number(p[0]) * 60 + Number(p[1]);
}

export function sectionFor(data: AppData, no: number): SectionTime {
  return data.sections[no - 1];
}

export function startOf(data: AppData, course: Course, date: Date): Date {
  let p = sectionFor(data, course.startSection).startTime.split(':');
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), Number(p[0]), Number(p[1]));
}

export function endOf(data: AppData, course: Course, date: Date): Date {
  let p = sectionFor(data, course.endSection).endTime.split(':');
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), Number(p[0]), Number(p[1]));
}

export interface CourseOccurrence { course: Course; date: Date; start: Date; end: Date; }

export function nextCourse(data: AppData, now: Date): CourseOccurrence | undefined {
  for (let offset = 0; offset <= 14; offset++) {
    let date = addDays(now, offset);
    for (let course of coursesOn(data, date)) {
      let start = startOf(data, course, date);
      let end = endOf(data, course, date);
      if (end.getTime() > now.getTime()) return { course: course, date: date, start: start, end: end };
    }
  }
  return undefined;
}

export function conflict(data: AppData, draft: Course): Course | undefined {
  for (let course of data.courses) {
    if (course.id === draft.id || course.dayOfWeek !== draft.dayOfWeek ||
      course.endSection < draft.startSection || draft.endSection < course.startSection) continue;
    for (let week = 1; week <= data.semester.totalWeeks; week++) {
      if (weekContains(course, week) && weekContains(draft, week)) return course;
    }
  }
  return undefined;
}
