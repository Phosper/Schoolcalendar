import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ThemeDef } from './Types';

export async function syncSystemBars(context: common.Context, theme: ThemeDef): Promise<void> {
  try {
    let mainWindow = await window.getLastWindow(context);
    mainWindow.setWindowBackgroundColor(theme.bg);
    await mainWindow.setWindowSystemBarProperties({
      statusBarColor: theme.bg, statusBarContentColor: theme.textPrimary,
      navigationBarColor: theme.bg, navigationBarContentColor: theme.textPrimary
    });
  } catch (_) {
    // Some window types do not expose system bars; keep their platform defaults.
  }
}
