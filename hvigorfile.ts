// 工程级构建脚本，使用 hvigor 默认的 App 构建任务
import { appTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTasks, // 内置的应用构建任务，不建议修改
  plugins: [] // 自定义构建插件
};
