import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';
import { HttpConfig } from './HttpConfig';
import { BaseResponse, HttpError, HttpMethod } from './HttpModel';
import { AuthInterceptor } from './AuthInterceptor';
import { LogInterceptor } from './LogInterceptor';
import { ResponseInterceptor } from './ResponseInterceptor';

const TAG: string = 'HttpClient';

/**
 * 网络请求封装类（基于 RCP - Remote Communication Kit）
 *
 * 设计要点：
 * 1. 单例模式：全局复用同一个 rcp.Session，避免重复创建连接开销
 * 2. 统一配置：BaseURL、超时时间、公共请求头集中在 HttpConfig 管理
 * 3. 日志拦截器：通过 LogInterceptor 打印请求/响应全链路日志
 * 4. 泛型返回：get/post 等方法通过泛型 T 约束返回类型，规避 any
 * 5. 统一异常：网络异常与 HTTP 状态码异常统一转换为 HttpError 抛出
 *
 * 使用示例：
 *   const user: UserInfo = await HttpClient.getInstance().get<UserInfo>('/user/1');
 */
export class HttpClient {
  /** 单例实例 */
  private static instance: HttpClient | undefined = undefined;
  /** RCP 会话对象，整个应用生命周期内复用 */
  private session: rcp.Session;

  /**
   * 私有构造函数，初始化 RCP Session
   * 外部禁止 new，统一通过 getInstance() 获取
   */
  private constructor() {
    Logger.info(TAG, '初始化 RCP Session, baseURL: %{public}s', HttpConfig.BASE_URL);
    this.session = rcp.createSession({
      // 基础地址：所有相对路径请求都会拼接该前缀
      baseAddress: HttpConfig.BASE_URL,
      // 公共请求头：全局生效，可在此添加 token 等
      headers: {
        'content-type': 'application/json',
        'accept': 'application/json'
      },
      // 拦截器链：按声明顺序执行请求侧逻辑，响应侧逆序返回
      // 1. AuthInterceptor（最前）：注入 Token / 请求 ID 等公共请求头
      // 2. LogInterceptor：打印含公共头在内的完整请求与响应日志
      // 3. ResponseInterceptor（最后）：统一处理 401 与异常状态码
      interceptors: [
        new AuthInterceptor(),
        new LogInterceptor(),
        new ResponseInterceptor()
      ],
      // 请求配置：超时时间等
      requestConfiguration: {
        transfer: {
          timeout: {
            // 建立连接超时
            connectMs: HttpConfig.CONNECT_TIMEOUT,
            // 整体传输超时
            transferMs: HttpConfig.TRANSFER_TIMEOUT
          }
        }
      }
    });
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /**
   * 设置/更新全局请求头（如登录后写入 token）
   * @param key 请求头名称
   * @param value 请求头的值
   */
  public setHeader(key: string, value: string): void {
    Logger.info(TAG, '更新全局请求头: %{public}s', key);
    if (this.session.configuration?.headers) {
      this.session.configuration.headers[key] = value;
    }
  }

  /**
   * GET 请求
   * @param path 接口路径（相对 BaseURL），如 '/user/list'
   * @returns 泛型 T 类型的业务数据
   */
  public async get<T>(path: string): Promise<T> {
    return this.request<T>(HttpMethod.GET, path);
  }

  /**
   * POST 请求
   * @param path 接口路径
   * @param body 请求体对象，内部序列化为 JSON
   */
  public async post<T>(path: string, body?: object): Promise<T> {
    return this.request<T>(HttpMethod.POST, path, body);
  }

  /**
   * PUT 请求
   * @param path 接口路径
   * @param body 请求体对象
   */
  public async put<T>(path: string, body?: object): Promise<T> {
    return this.request<T>(HttpMethod.PUT, path, body);
  }

  /**
   * DELETE 请求
   * @param path 接口路径
   */
  public async delete<T>(path: string): Promise<T> {
    return this.request<T>(HttpMethod.DELETE, path);
  }

  /**
   * GET 请求（自动解包 BaseResponse 业务结构）
   * 适用于后端返回 { code, message, data } 统一包装结构的接口，
   * 内部完成业务码校验：code 非成功值时抛出 HttpError
   * @param path 接口路径
   * @returns 解包后的业务数据 data
   */
  public async getData<T>(path: string): Promise<T> {
    const resp: BaseResponse<T> = await this.request<BaseResponse<T>>(HttpMethod.GET, path);
    return HttpClient.unwrap(resp, path);
  }

  /**
   * POST 请求（自动解包 BaseResponse 业务结构）
   * @param path 接口路径
   * @param body 请求体对象
   * @returns 解包后的业务数据 data
   */
  public async postData<T>(path: string, body?: object): Promise<T> {
    const resp: BaseResponse<T> = await this.request<BaseResponse<T>>(HttpMethod.POST, path, body);
    return HttpClient.unwrap(resp, path);
  }

  /**
   * 统一业务码校验与解包
   * 业务码非成功值时打印错误日志并抛出 HttpError（携带后端 message）
   * @param resp 后端统一包装的响应结构
   * @param path 接口路径（仅用于日志）
   */
  private static unwrap<T>(resp: BaseResponse<T>, path: string): T {
    if (resp.code !== HttpConfig.BIZ_SUCCESS_CODE) {
      Logger.error(TAG, '业务码异常: %{public}d, msg: %{public}s, path: %{public}s',
        resp.code, resp.message ?? '', path);
      throw new HttpError(resp.code, resp.message ?? '业务处理失败');
    }
    return resp.data;
  }

  /**
   * 通用请求方法（核心逻辑）
   * 流程：构建请求 -> 发起请求 -> 校验 HTTP 状态码 -> 解析 JSON -> 返回业务数据
   * @param method 请求方法
   * @param path 接口路径
   * @param body 请求体（可选）
   */
  private async request<T>(method: HttpMethod, path: string, body?: object): Promise<T> {
    try {
      // 构建 RCP 请求对象；请求体序列化为 JSON 字符串
      const content: string | undefined = body !== undefined ? JSON.stringify(body) : undefined;
      const request: rcp.Request = new rcp.Request(path, method, undefined, content);

      // 发起请求
      // 日志由 LogInterceptor 打印，HTTP 状态码异常（含 401）由 ResponseInterceptor 统一处理
      const response: rcp.Response = await this.session.fetch(request);

      // 解析响应体为 JSON
      const result: T | null = response.toJSON() as T | null;
      if (result === null) {
        Logger.error(TAG, '响应体解析失败, path: %{public}s', path);
        throw new HttpError(-1, '响应数据解析失败');
      }
      return result;
    } catch (err) {
      // 已是 HttpError 直接向上抛出
      if (err instanceof HttpError) {
        throw err;
      }
      // RCP 底层异常（如断网、超时、DNS 失败），转换为统一的 HttpError
      const bizErr: BusinessError = err as BusinessError;
      Logger.error(TAG, '网络请求失败, path: %{public}s, code: %{public}d, msg: %{public}s',
        path, bizErr.code ?? -1, bizErr.message ?? '未知错误');
      throw new HttpError(bizErr.code ?? -1, bizErr.message ?? '网络请求失败，请检查网络连接');
    }
  }

  /**
   * 关闭会话，释放底层资源
   * 一般在应用退出（UIAbility onDestroy）时调用
   */
  public close(): void {
    Logger.info(TAG, '关闭 RCP Session');
    this.session.close();
    HttpClient.instance = undefined;
  }
}
