# 复杂场景演示

这些输入使用虚构业务，复用正式 CLI 离线解析、生成 D2，再调用 D2 0.7.1 / ELK。目录中的场景彼此独立，包含故意错误的输入，运行时应选择具体场景的 `migrations/`。

## 一键运行

在项目根目录执行：

```bash
make demo
```

打开 `generated/demos/index.html`，即可查看四张图、源码、实际命令、运行日志和六种预期失败。`report.json` 保存退出码、耗时、产物保护等核验结果。整个目录可复制给同事离线浏览。

单独演示一个场景：

```bash
make demo DEMO=release_evolution
make demo DEMO=tenant_orders
make demo DEMO=logical_relationships
make demo DEMO=readability
```

单场景运行会更新目录页为本次选择的结果；其他已有文件保留。重新运行 `make demo` 恢复完整目录。脚本也支持 `--output` 和 `--d2-binary`：

```bash
.venv/bin/python scripts/run_demos.py --output generated/presentation --case readability
```

仅生成源码仍使用正式 CLI，无需 D2 可执行文件：

```bash
.venv/bin/python -m erd_generator \
  --migrations examples/tenant_orders/migrations \
  --out generated/tenant-source.d2 --show-types --direction down
```

## 四组成功生成场景

| 场景 | 表 / 字段 / FK 约束 / 连线 | 参数 | 重点核验 |
| --- | --- | --- | --- |
| `tenant_orders` | 9 / 42 / 15 / 26 | `--direction right --show-types` | 复合主外键、一个订单的创建/审批/分配三种用户角色、多对多授权、组织和分类自引用、复合与条件唯一索引 |
| `release_evolution` | 4 / 15 / 3 / 3 | `--direction down --show-types` | V1、V2、V3、V10、V11 数字排序；表和字段重命名后引用跟随；CASCADE 删除依赖；类型、非空、索引维护 |
| `logical_relationships` | 6 / 23 / 10 / 10 | `--direction left --fk-config …`，隐藏类型 | auth.users 与 crm.users 分开解析；SQL/注释/YAML 合并去重；循环依赖、自引用、孤立 outbox |
| `readability` | 4 / 17 / 3 / 3 | `--direction up --show-types --force-appendix` | 中文、长名称、D2 保留词、点号、引号、反斜杠、字面 `${reference}`、空表与详细索引附录 |

复合外键逐列连线，所以 FK 约束数量与箭头数量不同。`tenant_orders` 的 4 个单列和 11 个双列外键，共有 26 条连线。复合列的对应顺序由 SQL 的显式声明提供。

`logical_relationships` 的部分关系来自注释或 YAML，用于表达业务关联；不代表数据库已经建立这些约束。`ops.outbox.payload` 是 JSONB，工具不会根据载荷猜测外键。

## 六组预期失败

| 场景 | 预期退出码 | 演示的问题 | 核验产物 |
| --- | --- | --- | --- |
| `ambiguous_table` | 1 | YAML 使用 `users`，无法区分两个 schema | 原源码和 SVG 均保持不变 |
| `stale_fk_column` | 1 | 字段已重命名，YAML 仍引用 `audit.events.actor_id` | 原源码和 SVG 均保持不变 |
| `implicit_composite` | 1 | 合法的 SQL 省略复合目标列，但当前模型无法可靠恢复顺序 | 原源码和 SVG 均保持不变 |
| `malformed_sql` | 1 | CREATE TABLE 未完成 | 原源码和 SVG 均保持不变 |
| `invalid_layout` | 2 | D2 模式传入 draw.io 的 `--layout grid` | 原源码和 SVG 均保持不变 |
| `missing_renderer` | 1 | D2 路径不存在 | 新源码保留，旧 SVG 保持不变 |

运行器先用本轮真实生成的成功产物作为对照，再执行错误命令，逐字节比较结果。退出码、关键诊断和产物保护全部符合预期才计为通过。失败目录里的 SVG 属于上一次成功结果，目录页不会把它当作新生成图展示。

全部场景满足预期时 `make demo` 返回 0；任何意外失败返回非零。没有成功生成的对照图时，不运行产物保护演示。详细失败证据保存在各场景的 `console.log`。

## 建议的讲解顺序

1. **版本演进（约 2 分钟）**：从 V1 的 `app.accounts` 看起，对照最终的 `app.customers.customer_id`，指出旧表、旧字段和临时表已经消失。展示 V10 在 V3 后执行。
2. **逻辑关联（约 2 分钟）**：说明两个 `users` 的区别，打开 YAML，看 SQL 和 YAML 重复声明只绘制一次。展示孤立表仍保留。
3. **复合键与布局压力（约 2 分钟）**：打开多租户原图，选 `fk_order_product [1/2]` 和 `[2/2]` 解释 tenant 与 id 配对，再看组织自引用和多角色关联。
4. **可读性与错误处理（约 2 分钟）**：展示中文原图、索引附录，然后打开六种错误的退出码与日志。

## 人工检查发现的布局限制

**自动核验通过不等于无重叠的视觉验收。** 本地浏览器检查发现，`tenant_orders` 中复合自引用和多边汇聚会造成局部标签相互重叠，部分自引用标签与字段文字重叠。D2 源码的关系与列顺序正确，但这张图明确作为布局压力演示，不能作为无重叠排版的示范。

`release_evolution` 和 `logical_relationships` 的样例标签与结构可读。`readability` 原图中的中文、特殊字符和附录已检查；长字段与附录在缩略图中较小，讲解时应打开 SVG 原图。实际复杂度主要由边密度和标签决定，不能仅按表数量判断。

当前没有自动业务拆图、交叉数量验收或像素级碰撞检测；四个场景都使用现有 CLI 能力。已知布局限制同时显示在目录页和 JSON 报告中。

## 测试与维护

- `scenarios.json` 维护输入路径、演示参数、预期表/标签和错误结果。
- `tests/test_demo_scenarios.py` 从 SQL/YAML 核验完整关系集合、字段状态、删除结果、去重、四个方向及错误保护，不依赖布局快照。
- `tests/integration/test_demo_rendering.py` 执行同一个演示命令、检查四个真实 SVG、六种预期失败以及渲染器不可用时不会把旧图显示为新结果。
- 依赖流为：示例/参数 → 正式 CLI → Schema/D2 → ELK；演示脚本仅调用 CLI 并生成报告，不提供另一套解析器或布局器。
- 组合测试发现并修复了 `DROP COLUMN` 后唯一约束注册名称残留；单列/复合唯一约束均有针对性回归测试。
- 移除演示可删除 `examples/`、`scripts/run_demos.py`、相关演示测试，以及 Makefile 的 `demo` 入口和本文件链接。默认生成命令和 draw.io 兼容入口不依赖这些示例；独立的解析器修复可单独保留。

运行验收：

```bash
make build test lint
make test-integration
make demo
```
