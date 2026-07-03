/**
 * 网络层数据模型定义
 * 遵循 ArkTS 规范：禁止使用 any/unknown 作为业务类型，全部显式建模
 */

/**
 * 通用后端响应结构（按后端实际约定调整字段名）
 * @template T 业务数据泛型
 */
export interface BaseResponse<T> {
  /** 业务状态码，0 表示成功 */
  code: number;
  /** 提示信息 */
  message: string;
  /** 业务数据 */
  data: T;
}

/**
 * 统一网络错误对象
 * 网络异常、HTTP 状态码异常、业务码异常均转换为该类型抛出
 */
export class HttpError extends Error {
  /** 错误码：HTTP 状态码或业务错误码，网络异常时为 -1 */
  public code: number;

  constructor(code: number, message: string) {
    super(message);
    this.name = 'HttpError';
    this.code = code;
  }
}

/**
 * 请求方法枚举
 */
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}
