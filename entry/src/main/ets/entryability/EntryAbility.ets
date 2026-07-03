import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../common/utils/Logger';
import { HttpClient } from '../common/network/HttpClient';

const TAG: string = 'EntryAbility';

/**
 * 应用主入口 Ability
 * 负责窗口加载与应用级生命周期管理
 */
export default class EntryAbility extends UIAbility {
  /**
   * Ability 创建时回调，可在此做全局初始化
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onCreate, launchReason: %{public}d', launchParam.launchReason);
  }

  /**
   * Ability 销毁时回调，释放网络会话等全局资源
   */
  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
    // 应用退出时关闭 RCP 会话，释放底层连接资源
    HttpClient.getInstance().close();
  }

  /**
   * 窗口创建时回调，加载首页
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(TAG, 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        Logger.error(TAG, '加载首页失败, code: %{public}d, msg: %{public}s',
          err.code, err.message);
        return;
      }
      Logger.info(TAG, '首页加载成功');
    });
  }

  /**
   * 窗口销毁时回调
   */
  onWindowStageDestroy(): void {
    Logger.info(TAG, 'onWindowStageDestroy');
  }

  /**
   * 应用切换到前台
   */
  onForeground(): void {
    Logger.info(TAG, 'Ability onForeground');
  }

  /**
   * 应用切换到后台
   */
  onBackground(): void {
    Logger.info(TAG, 'Ability onBackground');
  }
}
