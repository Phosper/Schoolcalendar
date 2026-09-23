const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const studio = process.env.DEVECO_HOME;
if (!studio) throw new Error('DEVECO_HOME is required');
const ts = require(path.join(studio, 'tools/hvigor/hvigor/node_modules/typescript'));
const root = path.resolve(__dirname, '../entry/src/main/ets/model');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'schoolcalendar-test-'));
try {
  for (const name of ['Types', 'Schedule']) {
    const source = fs.readFileSync(path.join(root, `${name}.ets`), 'utf8');
    const output = ts.transpileModule(source, {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
    }).outputText;
    fs.writeFileSync(path.join(temp, `${name}.js`), output);
  }
  const { defaultData } = require(path.join(temp, 'Types.js'));
  const { teachingWeek, weekContains, validWeeksMask, coursesOn, nextCourse, conflict, semesterMessage } = require(path.join(temp, 'Schedule.js'));
  const data = defaultData();
  data.semester = { name: '测试学期', startDate: '2026-09-21', totalWeeks: 20 };
  const odd = { id: 1, name: '数学', teacher: '', location: 'A101', dayOfWeek: 1,
    startSection: 1, endSection: 2, weekPattern: 'odd', weeksMask: '', colorIndex: 3 };
  const custom = { id: 2, name: '物理', teacher: '', location: 'B201', dayOfWeek: 3,
    startSection: 3, endSection: 4, weekPattern: 'custom', weeksMask: '1-8,11,13', colorIndex: 5 };
  data.courses = [odd, custom];
  assert.equal(teachingWeek(data, new Date(2026, 8, 21)), 1);
  assert.equal(teachingWeek(data, new Date(2026, 8, 28)), 2);
  assert.equal(weekContains(odd, 1), true);
  assert.equal(weekContains(odd, 2), false);
  assert.equal(weekContains(custom, 8), true);
  assert.equal(weekContains(custom, 9), false);
  assert.equal(weekContains(custom, 11), true);
  assert.equal(validWeeksMask('1-8,11,13', 20), true);
  assert.equal(validWeeksMask('1-21', 20), false);
  assert.equal(validWeeksMask('9-2', 20), false);
  assert.equal(validWeeksMask('1,abc', 20), false);
  assert.equal(coursesOn(data, new Date(2026, 8, 28)).length, 0);
  assert.equal(nextCourse(data, new Date(2026, 8, 21, 7, 30)).course.name, '数学');
  assert.equal(nextCourse(data, new Date(2026, 8, 21, 8, 30)).course.name, '数学');
  assert.equal(nextCourse(data, new Date(2026, 8, 21, 9, 40)).course.name, '物理');
  assert.equal(conflict(data, { ...odd, id: 3, name: '冲突课程' }).id, 1);
  assert.equal(conflict(data, { ...odd, id: 3, weekPattern: 'even' }), undefined);
  assert.match(semesterMessage(data, new Date(2026, 8, 20)), /距开学还有 1 天/);
  assert.equal(semesterMessage(data, new Date(2027, 2, 1)), '本学期已结束');
  console.log('课程周次、跨节、冲突和前瞻逻辑测试通过');
} finally {
  const base = path.resolve(os.tmpdir()) + path.sep;
  if (!path.resolve(temp).startsWith(base)) throw new Error('Unsafe temporary path');
  fs.rmSync(temp, { recursive: true, force: true });
}
