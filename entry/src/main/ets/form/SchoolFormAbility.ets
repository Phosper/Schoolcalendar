import { Configuration, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Repository } from '../data/Repository';
import { defaultData } from '../model/Types';
import { WidgetRegistration, WidgetService } from './WidgetService';

export default class SchoolFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    let id = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    let name = want.parameters?.[formInfo.FormParam.NAME_KEY] as string;
    let dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number;
    let item: WidgetRegistration = { id: id, name: name, dimension: dimension };
    this.initialize(item);
    return formBindingData.createFormBindingData({ payload: JSON.stringify(defaultData()), dimension: `${dimension}`, dark: 'false' });
  }

  private async initialize(item: WidgetRegistration): Promise<void> {
    await WidgetService.add(this.context, item);
    await Repository.get().init(this.context);
    await WidgetService.update(item, await Repository.get().load(),
      this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
  }

  onUpdateForm(formId: string): void { this.refresh(formId); }

  private async refresh(formId: string): Promise<void> {
    await Repository.get().init(this.context);
    await WidgetService.notify(this.context, await Repository.get().load(),
      this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
  }

  onConfigurationUpdate(config: Configuration): void { this.refresh(''); }

  onRemoveForm(formId: string): void { WidgetService.remove(this.context, formId); }
  onAcquireFormState(want: Want): formInfo.FormState { return formInfo.FormState.READY; }
}
