/**
 * 网络请求全局配置常量
 * 统一管理 BaseURL、超时时间等配置，避免散落在业务代码中
 */
export class HttpConfig {
  /** 服务端基础地址，接入真实后端时修改此处 */
  public static readonly BASE_URL: string = 'https://jsonplaceholder.typicode.com';

  /** 传输超时时间（毫秒）：整个请求传输过程允许的最大耗时 */
  public static readonly TRANSFER_TIMEOUT: number = 30 * 1000;

  /** 连接超时时间（毫秒）：与服务器建立连接允许的最大耗时 */
  public static readonly CONNECT_TIMEOUT: number = 10 * 1000;

  /** 业务成功状态码（根据后端约定调整） */
  public static readonly BIZ_SUCCESS_CODE: number = 0;
}

/**
 * HTTP 状态码常量
 */
export class HttpStatusCode {
  /** 请求成功 */
  public static readonly OK: number = 200;
  /** 未授权 */
  public static readonly UNAUTHORIZED: number = 401;
  /** 禁止访问 */
  public static readonly FORBIDDEN: number = 403;
  /** 资源不存在 */
  public static readonly NOT_FOUND: number = 404;
  /** 服务端错误 */
  public static readonly SERVER_ERROR: number = 500;
}
