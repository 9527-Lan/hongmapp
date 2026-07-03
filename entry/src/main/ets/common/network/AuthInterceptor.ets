import { rcp } from '@kit.RemoteCommunicationKit';
import { Logger } from '../utils/Logger';
import { TokenManager } from './TokenManager';

const TAG: string = 'AuthInterceptor';

/**
 * 统一请求拦截器
 *
 * 在每个请求发出前自动注入公共请求头：
 * 1. Authorization：从 TokenManager 读取 Token，登录后无需业务侧手动携带
 * 2. x-request-id：为每个请求生成唯一 ID，便于前后端日志串联排查
 * 3. x-timestamp：请求发起时间戳，可用于服务端防重放校验
 *
 * 拦截器链中应排在最前，保证后续日志拦截器能打印出完整请求头
 */
export class AuthInterceptor implements rcp.Interceptor {
  /**
   * 拦截方法：注入公共请求头后放行
   * @param context 请求上下文
   * @param next 请求处理链的下一个处理器
   */
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const request: rcp.Request = context.request;

    // 确保 headers 对象存在
    if (!request.headers) {
      request.headers = {};
    }

    // ---------- 注入鉴权 Token ----------
    const token: string = TokenManager.getInstance().getToken();
    if (token.length > 0) {
      request.headers['authorization'] = `Bearer ${token}`;
      Logger.debug(TAG, '已注入 Authorization 请求头');
    }

    // ---------- 注入请求追踪 ID ----------
    const requestId: string = AuthInterceptor.generateRequestId();
    request.headers['x-request-id'] = requestId;

    // ---------- 注入请求时间戳 ----------
    request.headers['x-timestamp'] = Date.now().toString();

    Logger.debug(TAG, '请求拦截完成, requestId: %{public}s', requestId);

    // 放行，继续执行后续拦截器链
    return next.handle(context);
  }

  /**
   * 生成请求唯一 ID：时间戳 + 随机数，用于日志追踪
   */
  private static generateRequestId(): string {
    const timestamp: string = Date.now().toString(36);
    const random: string = Math.random().toString(36).substring(2, 10);
    return `${timestamp}-${random}`;
  }
}
