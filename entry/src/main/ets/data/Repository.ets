import { relationalStore, preferences } from '@kit.ArkData';
import { AppData, Course, DEFAULT_SECTIONS, defaultData, SectionTime, Semester } from '../model/Types';

const DB_CONFIG: relationalStore.StoreConfig = {
  name: 'schoolcalendar.db', securityLevel: relationalStore.SecurityLevel.S1
};

export class Repository {
  private static instance: Repository = new Repository();
  private db?: relationalStore.RdbStore;
  private pref?: preferences.Preferences;
  private initTask?: Promise<void>;

  static get(): Repository { return Repository.instance; }

  async init(context: Context): Promise<void> {
    if (this.initTask) return this.initTask;
    this.initTask = this.open(context);
    return this.initTask;
  }

  private async open(context: Context): Promise<void> {
    this.db = await relationalStore.getRdbStore(context, DB_CONFIG);
    this.pref = await preferences.getPreferences(context, 'settings');
    await this.db.executeSql('CREATE TABLE IF NOT EXISTS course (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, teacher TEXT, location TEXT, dayOfWeek INTEGER, startSection INTEGER, endSection INTEGER, weekPattern TEXT, weeksMask TEXT, colorIndex INTEGER)');
    await this.db.executeSql('CREATE TABLE IF NOT EXISTS section_time (sectionNo INTEGER PRIMARY KEY, startTime TEXT, endTime TEXT)');
    await this.db.executeSql('CREATE TABLE IF NOT EXISTS semester (id INTEGER PRIMARY KEY, name TEXT, startDate TEXT, totalWeeks INTEGER)');
    let result = await this.db.querySql('SELECT COUNT(*) AS n FROM section_time');
    result.goToFirstRow();
    let count = result.getLong(0);
    result.close();
    if (count === 0) await this.saveSections(DEFAULT_SECTIONS);
    result = await this.db.querySql('SELECT COUNT(*) AS n FROM semester');
    result.goToFirstRow();
    count = result.getLong(0);
    result.close();
    if (count === 0) await this.saveSemester(defaultData().semester);
  }

  async load(): Promise<AppData> {
    let data = defaultData();
    let db = this.db!;
    let rows = await db.querySql('SELECT id,name,teacher,location,dayOfWeek,startSection,endSection,weekPattern,weeksMask,colorIndex FROM course ORDER BY dayOfWeek,startSection');
    let courses: Course[] = [];
    while (rows.goToNextRow()) {
      courses.push({ id: rows.getLong(0), name: rows.getString(1), teacher: rows.getString(2),
        location: rows.getString(3), dayOfWeek: rows.getLong(4), startSection: rows.getLong(5),
        endSection: rows.getLong(6), weekPattern: rows.getString(7), weeksMask: rows.getString(8),
        colorIndex: rows.getLong(9) });
    }
    rows.close();
    data.courses = courses;
    rows = await db.querySql('SELECT sectionNo,startTime,endTime FROM section_time ORDER BY sectionNo');
    let sections: SectionTime[] = [];
    while (rows.goToNextRow()) sections.push({ sectionNo: rows.getLong(0), startTime: rows.getString(1), endTime: rows.getString(2) });
    rows.close();
    data.sections = sections;
    rows = await db.querySql('SELECT name,startDate,totalWeeks FROM semester WHERE id=1');
    if (rows.goToFirstRow()) data.semester = { name: rows.getString(0), startDate: rows.getString(1), totalWeeks: rows.getLong(2) };
    rows.close();
    data.themeId = this.pref!.getSync('themeId', 'fresh_green') as string;
    data.reminderMinutes = this.pref!.getSync('reminderMinutes', 15) as number;
    data.calendarSyncEnabled = this.pref!.getSync('calendarSyncEnabled', false) as boolean;
    return data;
  }

  async saveCourse(course: Course): Promise<void> {
    let db = this.db!;
    let args: relationalStore.ValueType[] = [course.name, course.teacher, course.location,
      course.dayOfWeek, course.startSection, course.endSection, course.weekPattern, course.weeksMask, course.colorIndex];
    if (course.id > 0) {
      args.push(course.id);
      await db.executeSql('UPDATE course SET name=?,teacher=?,location=?,dayOfWeek=?,startSection=?,endSection=?,weekPattern=?,weeksMask=?,colorIndex=? WHERE id=?', args);
    } else {
      await db.executeSql('INSERT INTO course (name,teacher,location,dayOfWeek,startSection,endSection,weekPattern,weeksMask,colorIndex) VALUES (?,?,?,?,?,?,?,?,?)', args);
    }
  }

  async deleteCourse(id: number): Promise<void> { await this.db!.executeSql('DELETE FROM course WHERE id=?', [id]); }

  async saveSections(sections: SectionTime[]): Promise<void> {
    let db = this.db!;
    await db.executeSql('DELETE FROM section_time');
    for (let s of sections) await db.executeSql('INSERT INTO section_time VALUES (?,?,?)', [s.sectionNo, s.startTime, s.endTime]);
  }

  async saveSemester(semester: Semester): Promise<void> {
    await this.db!.executeSql('INSERT OR REPLACE INTO semester VALUES (1,?,?,?)',
      [semester.name, semester.startDate, semester.totalWeeks]);
  }

  async saveSetting(key: string, value: string | number | boolean): Promise<void> {
    this.pref!.putSync(key, value);
    await this.pref!.flush();
  }
}
