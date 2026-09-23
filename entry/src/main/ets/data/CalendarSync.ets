import { calendarManager } from '@kit.CalendarKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppData, Course } from '../model/Types';
import { addDays, endOf, parseDate, startOf, weekContains } from '../model/Schedule';

const ACCOUNT: calendarManager.CalendarAccount = {
  name: 'com.schoolcalendar.app', type: calendarManager.CalendarType.LOCAL,
  displayName: 'SchoolCalendar 课表'
};

export class CalendarSync {
  static async remove(context: Context): Promise<void> {
    let manager = calendarManager.getCalendarManager(context);
    try {
      let calendar = await manager.getCalendar(ACCOUNT);
      await manager.deleteCalendar(calendar);
    } catch (error) {
      if ((error as BusinessError).code !== 23900003) throw new Error((error as BusinessError).message);
    }
  }

  static async rebuild(context: Context, data: AppData): Promise<number> {
    await CalendarSync.remove(context);
    let manager = calendarManager.getCalendarManager(context);
    let calendar = await manager.createCalendar(ACCOUNT);
    let events: calendarManager.Event[] = [];
    let firstMonday = parseDate(data.semester.startDate);
    for (let week = 1; week <= data.semester.totalWeeks; week++) {
      for (let course of data.courses) {
        if (!weekContains(course, week)) continue;
        let date = addDays(firstMonday, (week - 1) * 7 + course.dayOfWeek - 1);
        events.push({
          type: calendarManager.EventType.NORMAL,
          title: course.name,
          startTime: startOf(data, course, date).getTime(),
          endTime: endOf(data, course, date).getTime(),
          location: { location: course.location },
          description: course.teacher ? `教师：${course.teacher}` : 'SchoolCalendar 课程',
          reminderTime: [data.reminderMinutes]
        });
      }
    }
    for (let i = 0; i < events.length; i += 50) {
      await calendar.addEvents(events.slice(i, i + 50));
    }
    return events.length;
  }
}
