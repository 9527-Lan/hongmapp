import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志工具类
 * 基于系统 hilog 封装，统一管理日志域和标签，便于在 DevEco Studio 中过滤日志
 *
 * 使用方式：
 *   Logger.info('MyTag', '普通日志 %{public}s', 'content');
 *   Logger.error('MyTag', '错误日志 %{public}s', JSON.stringify(err));
 */
export class Logger {
  /** 日志域，范围 0x0000 ~ 0xFFFF，用于区分业务模块 */
  private static readonly DOMAIN: number = 0x0001;
  /** 日志统一前缀，便于全局过滤 */
  private static readonly PREFIX: string = '[HongmApp]';

  /**
   * debug 级别日志（仅调试阶段可见）
   * @param tag 业务标签
   * @param format 格式化字符串，占位符使用 %{public}s / %{public}d
   * @param args 格式化参数
   */
  public static debug(tag: string, format: string, ...args: (string | number | boolean)[]): void {
    hilog.debug(Logger.DOMAIN, `${Logger.PREFIX}${tag}`, format, ...args);
  }

  /**
   * info 级别日志（常规流程日志）
   */
  public static info(tag: string, format: string, ...args: (string | number | boolean)[]): void {
    hilog.info(Logger.DOMAIN, `${Logger.PREFIX}${tag}`, format, ...args);
  }

  /**
   * warn 级别日志（潜在异常，不影响主流程）
   */
  public static warn(tag: string, format: string, ...args: (string | number | boolean)[]): void {
    hilog.warn(Logger.DOMAIN, `${Logger.PREFIX}${tag}`, format, ...args);
  }

  /**
   * error 级别日志（错误信息，需要关注）
   */
  public static error(tag: string, format: string, ...args: (string | number | boolean)[]): void {
    hilog.error(Logger.DOMAIN, `${Logger.PREFIX}${tag}`, format, ...args);
  }
}
