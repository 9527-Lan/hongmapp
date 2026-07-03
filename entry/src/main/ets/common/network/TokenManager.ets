import { Logger } from '../utils/Logger';

const TAG: string = 'TokenManager';

/**
 * 登录失效（401）回调函数类型
 * 业务侧可注册该回调，在 Token 过期时跳转登录页等
 */
export type UnauthorizedCallback = () => void;

/**
 * Token 统一管理器（单例）
 *
 * 职责：
 * 1. 集中保存/读取/清除鉴权 Token，供请求拦截器自动注入
 * 2. 提供 401 登录失效回调注册，响应拦截器检测到 401 时统一分发
 *
 * 注意：当前 Token 仅保存在内存中，如需持久化可在 set/get 中
 * 接入 @ohos.data.preferences 首选项存储
 */
export class TokenManager {
  /** 单例实例 */
  private static instance: TokenManager | undefined = undefined;
  /** 内存中的鉴权 Token */
  private token: string = '';
  /** 登录失效回调列表 */
  private unauthorizedCallbacks: UnauthorizedCallback[] = [];

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): TokenManager {
    if (!TokenManager.instance) {
      TokenManager.instance = new TokenManager();
    }
    return TokenManager.instance;
  }

  /**
   * 保存 Token（登录成功后调用）
   * @param token 服务端下发的鉴权令牌
   */
  public setToken(token: string): void {
    Logger.info(TAG, '已更新鉴权 Token');
    this.token = token;
  }

  /**
   * 读取当前 Token，未登录时返回空字符串
   */
  public getToken(): string {
    return this.token;
  }

  /**
   * 清除 Token（退出登录或 401 时调用）
   */
  public clearToken(): void {
    Logger.info(TAG, '已清除鉴权 Token');
    this.token = '';
  }

  /**
   * 注册登录失效回调（如跳转登录页）
   * @param callback 401 发生时执行的回调
   */
  public onUnauthorized(callback: UnauthorizedCallback): void {
    this.unauthorizedCallbacks.push(callback);
  }

  /**
   * 分发登录失效事件（由响应拦截器在检测到 401 时调用）
   * 内部先清除失效 Token，再依次通知所有注册的回调
   */
  public notifyUnauthorized(): void {
    Logger.warn(TAG, '检测到登录失效（401），分发回调，数量: %{public}d',
      this.unauthorizedCallbacks.length);
    this.clearToken();
    for (const callback of this.unauthorizedCallbacks) {
      callback();
    }
  }
}
