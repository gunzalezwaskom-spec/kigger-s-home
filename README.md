# 电脑文件智能整理与空间清理工具

一个完全在本地运行、默认只做模拟预览、无需第三方依赖的 Windows/Python 工具。包含桌面图形界面、可自动化的命令行、JSON 计划、逐条事务日志和自包含 HTML 报告。

## 快速开始

环境要求：Windows 10/11，Python 3.10 或更高版本（安装 Python 时建议勾选“Add Python to PATH”）。

最省事的方式是双击 `start_gui.bat`。也可以在项目目录中运行：

```powershell
$env:PYTHONPATH = "$PWD\src"
python -m smart_organizer gui
```

图形界面的安全工作流：

1. 添加桌面、下载等一个或多个目标目录。
2. 选择分类组合维度、去重策略和大文件阈值。
3. 点击“生成安全预览”。这一步只扫描、计算 MD5、生成临时 HTML 报告，不改动目标文件。
4. 查看报告；确认无误后点击“确认执行”。
5. 如结果不符合预期，点击“撤销历史操作”并输入计划编号。
6. 确定不再需要撤销后，才使用“清空隔离区”真正释放重复/大文件占用的磁盘空间。

## 已实现功能

- 组合归档：按文件类型、修改年月、文件大小任意组合；分类维度同时决定目录层级。
- 内置分类：12 大类，130+ 常见后缀；未知后缀归入“其他”。
- 自定义规则：使用 `分类名 -> 扩展名列表` 的 JSON；自定义后缀会覆盖内置归属。
- 精准查重：先按大小分桶，再计算 MD5；支持跨目标目录的重复组。
- 三种策略：保留最新、保留最大、逐组手动指定唯一保留项。
- 大文件：阈值默认 50 MB，报告展示 TOP10，图形界面支持多选清理。
- 空目录：扫描时识别，执行时仅对仍为空的目录调用删除，非空目录安全跳过并记为失败。
- 默认模拟：生成 JSON 计划和 HTML 预览，不移动或删除目标文件。
- 可撤销：每次执行先保存完整计划，再逐条写 `journal.jsonl`；撤销按相反顺序恢复。
- HTML 报告：前后数量/活跃空间预测、分类饼图、大文件条形图、重复空间和操作明细。

## 安全模型

工具不会直接永久删除重复文件或用户勾选的大文件，而是把它们移动到首个目标目录下：

```text
.smart_organizer/
├── runs/<计划编号>/plan.json
├── runs/<计划编号>/journal.jsonl
├── runs/<计划编号>/summary.json
└── trash/<计划编号>/...
```

这保证了移动、去重、大文件清理和空目录删除都可撤销。隔离区仍位于磁盘上，因此只有显式清空隔离区才会真正释放磁盘空间；清空后对应文件不可撤销。符号链接、内部控制目录、归档目录与默认隐藏文件会被跳过。发生重名时自动添加 ` (1)`、` (2)`，撤销时绝不覆盖原位置已有文件。

建议第一次先用一个测试目录熟悉流程。归档目录可放在扫描目标内（默认如此）或完全位于扫描目标外，但不要设置成扫描目标本身或它的上级目录。

## 命令行示例

以下命令均在项目目录中执行，或直接使用 `start_cli.bat` 代替 `python -m smart_organizer`。

生成预览，按“类型 / 年月 / 大小”归档：

```powershell
$env:PYTHONPATH = "$PWD\src"
python -m smart_organizer preview "$HOME\Desktop" "$HOME\Downloads" --open
```

调整组合顺序、阈值和自定义规则：

```powershell
python -m smart_organizer preview "D:\Inbox" `
  --dimensions date,type,size `
  --large-mb 100 `
  --rules ".\examples\custom_rules.json" `
  --duplicates largest `
  --plan ".\my-plan.json" `
  --report ".\my-report.html"
```

手动策略中，每个重复组用一个 `--keep` 指定保留文件。没有唯一选择的组会安全跳过：

```powershell
python -m smart_organizer preview "D:\Inbox" --duplicates manual `
  --keep "D:\Inbox\keep-this.pdf"
```

大文件清理必须明确给出扫描结果中达到阈值的路径：

```powershell
python -m smart_organizer preview "D:\Inbox" --large-mb 50 `
  --delete-large "D:\Inbox\old-video.mp4" --plan ".\cleanup.json"
```

执行计划。没有 `--yes` 时仍是模拟执行：

```powershell
python -m smart_organizer execute ".\cleanup.json"
python -m smart_organizer execute ".\cleanup.json" --yes --open
```

查看历史、撤销、永久清空指定隔离区：

```powershell
python -m smart_organizer runs "D:\Inbox"
python -m smart_organizer undo "D:\Inbox" 20260821-120000-ab12cd34
python -m smart_organizer purge "D:\Inbox" 20260821-120000-ab12cd34 --yes
```

查看所有参数：

```powershell
python -m smart_organizer --help
python -m smart_organizer preview --help
```

## 自定义规则格式

```json
{
  "项目图纸": [".dwg", "dxf", ".cad"],
  "电子书": [".epub", ".mobi", ".azw3"]
}
```

扩展名可以省略开头的点，工具会统一转为小写。示例位于 `examples/custom_rules.json`。

## 开发与测试

项目只使用 Python 标准库。运行测试：

```powershell
$env:PYTHONPATH = "$PWD\src"
python -m unittest discover -s tests -v
```

可选安装命令：

```powershell
python -m pip install -e .
smart-organizer --help
smart-organizer-gui
```

