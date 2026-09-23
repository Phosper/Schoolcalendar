import { preferences } from '@kit.ArkData';
import { formBindingData, formProvider } from '@kit.FormKit';
import { AppData } from '../model/Types';

export interface WidgetRegistration { id: string; name: string; dimension: number; }

export class WidgetService {
  private static async list(context: Context): Promise<WidgetRegistration[]> {
    let pref = await preferences.getPreferences(context, 'widgets');
    let value = pref.getSync('registrations', '[]') as string;
    return JSON.parse(value) as WidgetRegistration[];
  }

  private static async put(context: Context, items: WidgetRegistration[]): Promise<void> {
    let pref = await preferences.getPreferences(context, 'widgets');
    pref.putSync('registrations', JSON.stringify(items));
    await pref.flush();
  }

  static async add(context: Context, item: WidgetRegistration): Promise<void> {
    let items = await WidgetService.list(context);
    items = items.filter((entry: WidgetRegistration) => entry.id !== item.id);
    items.push(item);
    await WidgetService.put(context, items);
  }

  static async remove(context: Context, id: string): Promise<void> {
    await WidgetService.put(context, (await WidgetService.list(context)).filter((item: WidgetRegistration) => item.id !== id));
  }

  static async notify(context: Context, data: AppData, dark: boolean = false): Promise<void> {
    let items = await WidgetService.list(context);
    for (let item of items) {
      try { await WidgetService.update(item, data, dark); } catch (_) { /* Removed by launcher. */ }
    }
  }

  static async update(item: WidgetRegistration, data: AppData, dark: boolean = false): Promise<void> {
    await formProvider.updateForm(item.id, formBindingData.createFormBindingData({
      payload: JSON.stringify(data), dimension: `${item.dimension}`, dark: dark ? 'true' : 'false'
    }));
  }
}
