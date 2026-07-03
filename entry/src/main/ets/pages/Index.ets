import { ApiService, PostModel } from '../service/ApiService';
import { HttpError } from '../common/network/HttpModel';
import { Logger } from '../common/utils/Logger';

const TAG: string = 'IndexPage';

/**
 * 首页：网络请求封装演示
 * 展示如何通过 Service 层发起 GET 请求并渲染列表，
 * 包含加载中 / 成功 / 失败三种 UI 状态
 */
@Entry
@Component
struct Index {
  /** 文章列表数据 */
  @State postList: PostModel[] = [];
  /** 是否加载中 */
  @State isLoading: boolean = false;
  /** 错误提示信息，空字符串表示无错误 */
  @State errorMsg: string = '';

  /**
   * 页面即将显示时自动拉取数据
   */
  aboutToAppear(): void {
    Logger.info(TAG, '页面初始化，开始加载数据');
    this.loadData();
  }

  /**
   * 加载文章列表数据
   * 统一处理 loading 状态与 HttpError 异常
   */
  private async loadData(): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const list: PostModel[] = await ApiService.getPostList();
      // 演示只展示前 20 条
      this.postList = list.slice(0, 20);
      Logger.info(TAG, '数据加载完成, 展示条数: %{public}d', this.postList.length);
    } catch (err) {
      // 网络层统一抛出 HttpError，此处直接读取 code 与 message
      const httpErr: HttpError = err as HttpError;
      this.errorMsg = `请求失败(${httpErr.code}): ${httpErr.message}`;
      Logger.error(TAG, '数据加载失败: %{public}s', this.errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('RCP 网络请求演示')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('刷新')
          .fontSize(14)
          .height(32)
          .enabled(!this.isLoading)
          .onClick(() => {
            Logger.info(TAG, '用户点击刷新');
            this.loadData();
          })
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMsg !== '') {
        // 失败状态
        Column() {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#D94838')
            .textAlign(TextAlign.Center)
            .padding(16)
          Button('重试')
            .margin({ top: 12 })
            .onClick(() => {
              this.loadData();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 成功状态：渲染列表
        List({ space: 12 }) {
          ForEach(this.postList, (item: PostModel) => {
            ListItem() {
              Column() {
                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.body)
                  .fontSize(14)
                  .fontColor('#666666')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
            }
          }, (item: PostModel) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F7')
  }
}
