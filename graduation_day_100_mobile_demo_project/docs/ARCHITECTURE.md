# 《毕业后的第100天》网页原型结构说明

当前公开游戏版本为 v0.6.1：多处境剧情补全测试版。

## 当前结构

```text
docs/
  index.html              # 页面入口，只负责加载 CSS 和 JS
  css/
    app.split.css          # 视觉主题、PC/手机布局、卡片、按钮、弹窗样式
  js/
    app.js                # 游戏逻辑入口：状态、事件、行动、UI 渲染、存档
  data/
    locations.json        # 地点数据
    life_scenarios.json   # 第 0 天人生处境数据；当前启用 4 条处境，保留 2 条 disabled placeholder
  assets/audio/           # BGM 和音频清单
```

## 为什么先这样拆

当前游戏仍是一个纯静态 GitHub Pages 原型，没有构建工具。为了降低发布风险，本次先做“入口拆分”：

- `index.html` 保持很小，避免每次改代码都卡。
- `css/app.split.css` 单独维护视觉主题和响应式布局。
- `js/app.js` 单独维护游戏逻辑。
- `data/life_scenarios.json` 单独维护毕业处境，已启用处境包括“有人陪你，但你不敢失败”“工科女生，正在被反复证明”“一直失利，但还没放弃”“普通到不知道怎么介绍自己”；未启用处境只做 disabled placeholder。
- 不引入打包器，不影响 GitHub Pages 直接发布。

## 后续建议拆分方向

当 `js/app.js` 继续变大时，可以继续拆成：

```text
js/
  app.js                  # 启动入口
  state.js                # freshState、存档、normalize、数值处理
  data.js                 # 行动、事件、联系人、每日主题、变体数据
  actions.js              # performAction、行动变体、求职/住房推进
  events.js               # renderEvent、每日主题、开场剧情、宿舍事件
  ui.js                   # renderShell、renderRoom、卡片、弹窗、电脑中心
  report.js               # 第 7 天报告、复制本局记录、测试统计
  audio.js                # BGM 管理
```

注意：如果继续拆 JS，建议先把全局状态和工具函数整理清楚，再拆 UI，否则容易出现函数顺序和全局变量依赖问题。
