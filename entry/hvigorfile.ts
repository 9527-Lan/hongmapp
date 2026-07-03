// entry 模块构建脚本，使用 hvigor 默认的 HAP 构建任务
import { hapTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: hapTasks, // 内置的 HAP 构建任务，不建议修改
  plugins: [] // 自定义构建插件
};
