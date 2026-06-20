# Remote Multi-Agent D2Q9 CUDA LBM Test

本仓库验证完整的 GitHub + Codex + 外部 builder 工程协作流程：

- 远端 GitHub issue 创建与跟踪；
- 基于 Git worktree 的并行 builder 车道（lane）；
- 集成分支合并与 gate 验证；
- GitHub Actions CI（CPU 回退路径）；
- Codex supervisor 审查；
- D2Q9 格子 Boltzmann 方法圆柱绕流算例，支持 CUDA 后端与 CPU 回退。

实现代码由 builder agent 在 issue、gate 和 lane 约束下完成，而非预先存在于规划基线中。

## 项目结构

```
.
├── src/
│   ├── lbm.hpp            # 公共 API 合约（Codex planner 提交的基线）
│   ├── lbm_cpu.cpp        # CPU BGK 碰撞/迁移实现（Lane A + Lane A2 修复）
│   ├── lbm_cuda.cu        # CUDA 设备内核与内存管理（Lane B）
│   └── main.cpp           # 验证可执行文件入口（Lane C）
├── tests/
│   └── lbm_tests.cpp      # 单元测试（Lane C）
├── scripts/
│   ├── validate.ps1       # 跨平台验证脚本（Lane C）
│   ├── workflow-preflight.ps1        # Workflow Mode 启动前检查
│   ├── workflow-integration-check.ps1 # 多分支集成 gate 检查
│   └── builders/           # 各 builder 的 PowerShell 包装器
├── docs/
│   ├── architecture-brief.md        # 架构简述与 lane 依赖图
│   ├── requirements.md              # 数值与输出需求
│   ├── gates/issue-001.md           # Gate 通过标准
│   ├── lanes/                       # 每条 lane 的定义
│   ├── agent-plans/issue-001.md     # Agent 调度计划
│   ├── runs/issue-001-run-log.md    # 执行日志
│   └── user-end-to-end-guide.md     # 使用者视角端到端记录
├── config/builders.yml              # Builder 非密钥端点与密钥来源配置
├── .codex-agent-workflow.yml        # 工作流定义与 agent 注册
├── .github/
│   ├── workflows/ci.yml             # GitHub Actions CI（CPU 回退验证）
│   ├── ISSUE_TEMPLATE/agent-task.md # Issue 模板
│   ├── labels.yml                   # Issue/PR 标签
│   └── pull_request_template.md     # PR 模板
└── AGENTS.md                        # Agent 行为规则
```

## 构建

### 前置条件

- **编译器**：g++（C++17）或等效编译器。
- **CUDA（可选）**：NVIDIA CUDA Toolkit（nvcc），用于 GPU 加速路径。
- **PowerShell**：Windows PowerShell 5.1+ 或 PowerShell Core 7+（跨平台）。
- **操作系统**：Windows（本地 CUDA 测试）或 Linux（GitHub Actions CI）。

### 快速构建与验证

运行集成验证脚本，自动检测 CUDA 是否可用并选择合适的编译路径：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate.ps1
```

脚本执行流程：
1. 检测编译器和 CUDA 工具链。
2. 编译单元测试（`tests/lbm_tests.cpp` + `src/lbm_cpu.cpp`）并执行。
3. 编译主可执行文件（含或不含 CUDA 后端）。
4. 运行 180 步圆柱绕流模拟。
5. 验证 CSV 输出文件存在且非空。

### 手动构建（仅 CPU）

```powershell
# 编译测试
g++ -std=c++17 -O2 -Isrc tests/lbm_tests.cpp src/lbm_cpu.cpp -o build/lbm_tests.exe

# 运行测试
./build/lbm_tests.exe

# 编译主程序
g++ -std=c++17 -O2 -Isrc src/main.cpp src/lbm_cpu.cpp -o build/main.exe

# 运行模拟
./build/main.exe 180
```

### 手动构建（CUDA + CPU 混合）

```powershell
nvcc -std=c++17 -O2 -Isrc -DLBM_WITH_CUDA src/main.cpp src/lbm_cpu.cpp src/lbm_cuda.cu -o build/main.exe
./build/main.exe 180
```

## 输出

模拟运行后在 `out/` 目录生成：

- **`out/cylinder_wake.csv`**：圆柱绕流场数据，CSV 格式，包含 `x,y,rho,ux,uy` 列。默认以 stride=2 采样输出，文件大小取决于网格分辨率（默认 160×80）。

标准输出包含：
- 后端标识（`CUDA` 或 `CPU`）
- 网格尺寸（160×80）
- 迭代次数（180）
- 密度范围 `[rhoMin, rhoMax]`
- 总质量
- 圆柱下游采样点速度
- 验证通过标记 `LBM_VALIDATION_OK`
- 测试通过标记 `LBM_TESTS_OK`

## 数值方法

- **模型**：D2Q9 格子 Boltzmann 方法
- **碰撞算子**：BGK 单松弛时间（τ = 0.56）
- **边界条件**：
  - 左边界：Zou/He 速度入口（Ux = 0.06）
  - 右边界：零梯度出口
  - 上下边界：反弹（bounce-back）
  - 圆柱表面：反弹（bounce-back）
- **圆柱参数**：圆心 (40, 40)，半径 10（网格 160×80）

## 远端仓库

- **GitHub**：[kyoheyo/codex-lbm-d2q9-workflow-test](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test)
- **Issue**：[#1 - D2Q9 CUDA LBM 圆柱绕流](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test/issues/1)
- **PR**：[#2 - implement D2Q9 CUDA LBM cylinder wake](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test/pull/2)
- **Actions**：[run 27871525664 - success](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test/actions/runs/27871525664)
- **Artifact**：cylinder-wake-csv，ID 7765392870，37,084 bytes
- **Review**：[approved-by-supervisor](https://github.com/kyoheyo/codex-lbm-d2q9-workflow-test/pull/2#pullrequestreview-4537515438)

## 许可证

本仓库为工程协作流程测试项目。
