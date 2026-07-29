# Todo 列表性能与容量方案

本文定义 Floatick Todo 列表的现状、性能目标、验证方法和数据量增长方案。性能结论必须来自
Profile/Release 模式与真实设备；Debug 模式只用于功能调试。

## 当前实现

```mermaid
flowchart LR
    A["todos.json / tags.json<br/>启动时全量读取"] --> B["TodoViewModel<br/>内存索引、排序与筛选"]
    B --> C["ListView.builder<br/>只创建可见区域附近的行"]
    C --> D["TodoListRow<br/>滚动时暂停 hover 动画"]
```

- **Widget 已懒构建**：列表使用 `ListView.builder`，不会同时创建全部 Todo 行。
- **数据未分页**：Todo 与 Tag 仍会在启动时全部载入内存；修改后会原子性重写整个 JSON。
- **派生数据已缓存**：活动/归档排序、数量、标题与 Tag 搜索索引在数据变化时重建，不再随
  每次 Widget rebuild 重复计算。
- **日期分组已缓存**：结果集、语言、日期与列表范围没有变化时复用分组条目。
- **滚动期间暂停 hover**：鼠标固定在列表上时，滚动会让不同 Todo 行不断经过指针。滚动
  期间暂停 hover 背景和操作按钮动画，结束后再恢复，避免持续触发动画和 rebuild。
- **预构建下一屏**：列表在可见区域外缓存约 0.75 个窗口高度，减少快速滚动时临时创建
  Widget 的尖峰。

## 性能目标

| 指标 | 60Hz 设备 | 120Hz 设备 |
| --- | ---: | ---: |
| 单帧预算 | 16.67 ms | 8.33 ms |
| 滚动 build/raster p95 | 不超过单帧预算 | 不超过单帧预算 |
| 严重慢帧率 | < 1% | < 1% |
| 10,000 条搜索响应 | < 50 ms | < 50 ms |
| 10,000 条冷启动加载与索引 | < 250 ms | < 250 ms |

120Hz 的结论必须在真实 120Hz 屏幕上验证。CI 虚拟机的帧率和负载不稳定，只适合发现明显
回归，不能替代 M3 Pro/Intel Mac 的 Draft 验收。

## 当前容量结论

当前没有代码层面的 Todo 数量硬上限，但“没有硬上限”不代表已证明任意数量都流畅。

| 等级 | 数据量 | 用途 | 当前状态 |
| --- | ---: | --- | --- |
| 日常基线 | 1,000 | 普通用户长期使用 | 数据路径已验证 |
| 扩展基线 | 5,000 | 重度用户 | 数据路径已验证，需持续做 Profile 帧测试 |
| 压力基线 | 10,000 | 回归与容量压力测试 | 数据路径已验证，不能据此宣称 120Hz 已达标 |
| 迁移阈值 | 10,000+ | 超大工作区 | 应迁移到带索引和分页的本地数据库 |

2026-07-29 当前开发机上的一次对比基准如下。该结果用于观察数量级，不作为跨机器的绝对
承诺：

| Todo | 保存 JSON | 加载并建索引 | 首次搜索 | 缓存搜索 | 双 Tag 筛选 |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 100 | 34.7 ms | 47.8 ms | 1.7 ms | 0.6 ms | 0.9 ms |
| 1,000 | 18.7 ms | 49.4 ms | 2.1 ms | 0.03 ms | 1.6 ms |
| 5,000 | 45.3 ms | 109.1 ms | 10.1 ms | 0.10 ms | 11.7 ms |
| 10,000 | 60.9 ms | 121.8 ms | 12.4 ms | 0.01 ms | 4.5 ms |

少量数据的时间会受 JIT 预热和文件系统缓存影响，因此只比较整体趋势，不比较相邻两行的
细小差异。

## 基准命令

数据路径：

```bash
flutter test benchmark/todo_data_benchmark_test.dart --reporter expanded
```

真实 Flutter 引擎滚动帧：

```bash
flutter drive --profile -d macos \
  --driver=test_driver/performance_test_driver.dart \
  --target=integration_test/todo_scroll_performance_test.dart
```

帧测试固定生成 10,000 条 Todo 并连续快速滚动。验收时还应在 DevTools Performance 中
检查 UI/GPU 两条时间线：UI 超预算优先排查 build/layout；GPU 超预算优先排查裁剪、阴影和
saveLayer。

## 压测矩阵

每个 Draft 至少覆盖 1,000 与 10,000 两档，发布前抽测 5,000：

1. 启动、悬浮图标展开主容器、首次显示列表；
2. 触控板慢滚、快速 fling、滚动中移动鼠标；
3. 输入搜索、清空搜索、单/多 Tag 筛选；
4. 完成、归档、恢复、永久删除；
5. 同一天全部数据与跨 365 天分组两种分布；
6. 短标题、长标题、Markdown content、0/1/多 Tag；
7. Intel 60Hz、Apple Silicon 60Hz、Apple Silicon 120Hz。

记录指标包括 build/raster p50、p95、p99，慢帧数量，内存峰值，冷启动时间以及单次写入
耗时。任何优化都应在相同设备、相同数据集、相同 Profile 构建下做前后对比。

## 后续演进

### 阶段 1：当前 JSON 架构内继续优化

- 搜索输入增加短防抖，但保留回车立即搜索；
- 根据真实行高分布评估 `itemExtentBuilder`，避免为了估算高度引入跳动；
- 在独立物理 Mac 上保留 Profile 基准历史，监控 p95/p99 回归。

### 阶段 2：工作区超过 10,000 条

将 Todo、Tag 和 assignment 迁移到 SQLite 类本地数据库：

- 为 `archived_at`、`created_at`、规范化标题和 assignment 建索引；
- 使用 keyset/cursor 分页，不使用越往后越慢的深 offset；
- 首屏只读一页，滚动接近尾部时预取下一页；
- 搜索和 Tag 筛选下推到数据库；
- 保留 JSON/Markdown 导入导出，不再把 JSON 作为运行时主存储。

数据库迁移应单独写 ADR，并提供幂等迁移、备份与失败回滚；在此之前不为了“可能的数据量”
引入新的持久化依赖。

## 发布门槛

- 功能测试全部通过；
- 10,000 条数据路径基准无数量级退化；
- Profile 滚动基准能够执行并保留结果；
- 目标 Intel 与 M3 Pro 设备人工验证 60/120Hz；
- 若某项因工具链或设备缺失无法验证，Release 说明必须明确残余风险，不得写成“已支持”。
