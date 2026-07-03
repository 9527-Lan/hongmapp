import { rcp } from '@kit.RemoteCommunicationKit';
import { Logger } from '../utils/Logger';

const TAG: string = 'LogInterceptor';

/**
 * 网络日志拦截器
 * 实现 rcp.Interceptor 接口，在请求发出前和响应返回后统一打印日志，
 * 包含请求方法、URL、耗时、状态码等关键信息，便于排查网络问题
 */
export class LogInterceptor implements rcp.Interceptor {
  /**
   * 拦截方法：先打印请求日志，调用 next 继续请求链，再打印响应日志
   * @param context 请求上下文，包含 request 对象
   * @param next 请求处理链的下一个处理器
   * @returns 服务端响应
   */
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const request: rcp.Request = context.request;
    const startTime: number = Date.now();

    // ---------- 请求日志 ----------
    Logger.info(TAG, '==> 发起请求 [%{public}s] %{public}s',
      request.method ?? 'GET', request.url.toString());
    if (request.headers) {
      Logger.debug(TAG, '==> 请求头: %{public}s', JSON.stringify(request.headers));
    }

    try {
      // 继续执行请求链（后续拦截器 / 真正发起请求）
      const response: rcp.Response = await next.handle(context);
      const cost: number = Date.now() - startTime;

      // ---------- 响应日志 ----------
      Logger.info(TAG, '<== 收到响应 [%{public}d] %{public}s 耗时 %{public}dms',
        response.statusCode, request.url.toString(), cost);
      return response;
    } catch (err) {
      // ---------- 异常日志 ----------
      const cost: number = Date.now() - startTime;
      Logger.error(TAG, '<== 请求异常 %{public}s 耗时 %{public}dms 错误: %{public}s',
        request.url.toString(), cost, JSON.stringify(err));
      throw err as Error;
    }
  }
}
