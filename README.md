# hongmapp 鸿蒙应用

基于 HarmonyOS Stage 模型 + ArkTS 的应用工程，内置基于 RCP（Remote Communication Kit）的网络请求封装。

## 环境要求

- DevEco Studio 5.0 及以上
- HarmonyOS SDK API 12 及以上（RCP 能力要求）

## 目录结构

```
├── AppScope/                        # 应用全局配置与资源
│   └── app.json5                    # 包名、版本号等应用级配置
├── entry/                           # 主入口模块（HAP）
│   └── src/main/
│       ├── module.json5             # 模块清单（含 INTERNET 权限声明）
│       ├── ets/
│       │   ├── entryability/        # UIAbility 入口
│       │   │   └── EntryAbility.ets
│       │   ├── common/
│       │   │   ├── network/         # 网络请求封装层
│       │   │   │   ├── HttpClient.ets     # RCP 封装核心（单例 Session）
│       │   │   │   ├── HttpConfig.ets     # BaseURL / 超时等全局配置
│       │   │   │   ├── HttpModel.ets      # 响应模型与统一错误 HttpError
│       │   │   │   └── LogInterceptor.ets # 请求/响应日志拦截器
│       │   │   └── utils/
│       │   │       └── Logger.ets   # hilog 日志工具类
│       │   ├── service/
│       │   │   └── ApiService.ets   # 业务接口层（示例）
│       │   └── pages/
│       │       └── Index.ets        # 首页（网络请求演示）
│       └── resources/               # 模块资源
├── build-profile.json5              # 工程级构建配置
└── oh-package.json5                 # 工程级依赖配置
```

## 网络封装使用说明

### 基本用法

```ts
import { HttpClient } from '../common/network/HttpClient';

// GET 请求（泛型约束返回类型）
const list: PostModel[] = await HttpClient.getInstance().get<PostModel[]>('/posts');

// POST 请求
const created: PostModel = await HttpClient.getInstance().post<PostModel>('/posts', params);
```

### 统一错误处理

网络异常、HTTP 状态码异常均转换为 `HttpError` 抛出：

```ts
try {
  await ApiService.getPostList();
} catch (err) {
  const httpErr: HttpError = err as HttpError;
  console.error(`code: ${httpErr.code}, message: ${httpErr.message}`);
}
```

### 登录后写入 Token

```ts
HttpClient.getInstance().setHeader('authorization', `Bearer ${token}`);
```

### 修改服务端地址

编辑 `entry/src/main/ets/common/network/HttpConfig.ets` 中的 `BASE_URL`。

## 日志查看

所有日志通过 hilog 输出，统一前缀 `[HongmApp]`，在 DevEco Studio 的 Log 面板中过滤该关键字即可查看请求/响应全链路日志。

## 运行

使用 DevEco Studio 打开工程根目录，等待 ohpm 同步依赖后，连接真机或模拟器直接运行 entry 模块。
