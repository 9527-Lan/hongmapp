import { rcp } from '@kit.RemoteCommunicationKit';
import { Logger } from '../utils/Logger';
import { HttpStatusCode } from './HttpConfig';
import { HttpError } from './HttpModel';
import { TokenManager } from './TokenManager';

const TAG: string = 'ResponseInterceptor';

/**
 * 统一响应拦截器
 *
 * 在响应返回后集中处理 HTTP 状态码：
 * 1. 401 未授权：清除本地 Token 并分发登录失效事件（业务侧可跳转登录页）
 * 2. 其他非 2xx：转换为统一的 HttpError 抛出，附带友好的中文提示
 * 3. 2xx 正常：直接放行给上层解析业务数据
 *
 * 拦截器链中应排在最后（最靠近真实请求），保证状态码处理最先执行
 */
export class ResponseInterceptor implements rcp.Interceptor {
  /**
   * 拦截方法：先放行请求，拿到响应后统一校验 HTTP 状态码
   * @param context 请求上下文
   * @param next 请求处理链的下一个处理器
   */
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    // 先执行请求，拿到响应
    const response: rcp.Response = await next.handle(context);
    const statusCode: number = response.statusCode;
    const url: string = context.request.url.toString();

    // ---------- 2xx 成功，直接放行 ----------
    if (statusCode >= HttpStatusCode.OK && statusCode < 300) {
      return response;
    }

    // ---------- 401 未授权：统一登出处理 ----------
    if (statusCode === HttpStatusCode.UNAUTHORIZED) {
      Logger.warn(TAG, '响应 401 未授权, url: %{public}s', url);
      TokenManager.getInstance().notifyUnauthorized();
      throw new HttpError(statusCode, '登录状态已失效，请重新登录');
    }

    // ---------- 其他异常状态码：转换为友好提示 ----------
    Logger.error(TAG, 'HTTP 状态码异常: %{public}d, url: %{public}s', statusCode, url);
    throw new HttpError(statusCode, ResponseInterceptor.mapStatusMessage(statusCode));
  }

  /**
   * 将常见 HTTP 状态码映射为友好的中文提示
   * @param statusCode HTTP 状态码
   */
  private static mapStatusMessage(statusCode: number): string {
    if (statusCode === HttpStatusCode.FORBIDDEN) {
      return '没有访问权限（403）';
    }
    if (statusCode === HttpStatusCode.NOT_FOUND) {
      return '请求的资源不存在（404）';
    }
    if (statusCode >= HttpStatusCode.SERVER_ERROR) {
      return `服务器开小差了，请稍后重试（${statusCode}）`;
    }
    return `请求失败（${statusCode}）`;
  }
}
