import { HttpClient } from '../common/network/HttpClient';
import { Logger } from '../common/utils/Logger';

const TAG: string = 'ApiService';

/**
 * 文章数据模型（对应 jsonplaceholder 的 /posts 接口，接入真实后端时替换）
 */
export interface PostModel {
  /** 用户 ID */
  userId: number;
  /** 文章 ID */
  id: number;
  /** 标题 */
  title: string;
  /** 正文 */
  body: string;
}

/**
 * 创建文章的请求参数
 */
export interface CreatePostParams {
  userId: number;
  title: string;
  body: string;
}

/**
 * 业务 API 服务层
 * 页面/ViewModel 不直接调用 HttpClient，统一通过 Service 层访问接口，
 * 便于集中管理接口路径与数据模型
 */
export class ApiService {
  /**
   * 获取文章列表
   */
  public static async getPostList(): Promise<PostModel[]> {
    Logger.info(TAG, '开始获取文章列表');
    const list: PostModel[] = await HttpClient.getInstance().get<PostModel[]>('/posts');
    Logger.info(TAG, '获取文章列表成功, 数量: %{public}d', list.length);
    return list;
  }

  /**
   * 获取文章详情
   * @param id 文章 ID
   */
  public static async getPostDetail(id: number): Promise<PostModel> {
    Logger.info(TAG, '开始获取文章详情, id: %{public}d', id);
    return HttpClient.getInstance().get<PostModel>(`/posts/${id}`);
  }

  /**
   * 创建文章
   * @param params 创建参数
   */
  public static async createPost(params: CreatePostParams): Promise<PostModel> {
    Logger.info(TAG, '开始创建文章, title: %{public}s', params.title);
    return HttpClient.getInstance().post<PostModel>('/posts', params);
  }
}
