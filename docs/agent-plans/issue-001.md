# Agent Plan: Issue 001

## Workflow Mode Prompt

~~~text
使用工程协作流程实现 D2Q9 CUDA LBM 圆柱绕流算例。Codex 作为 planner、supervisor、reviewer。
先固定公共 API，再将 CPU 核心、CUDA 后端、测试/运行器、用户文档拆成有依赖关系的 lane。
除非我明确要求，不使用外部 Codex CLI builder；优先使用 claude-builder 和 bailian-opencode-builder。
创建远端 GitHub issue、feature PR，验证 GitHub Actions，并保存完整用户视角端到端记录。
~~~

## Dispatch Order

1. Commit contract baseline.
2. Run Lane A and Lane B in parallel worktrees.
3. Merge Lane A and Lane B into integration/issue-001.
4. Run Lane C from the integrated branch.
5. Run Lane D after validation.
6. Push final feature branch, open PR, wait for Actions, and perform Codex review.

