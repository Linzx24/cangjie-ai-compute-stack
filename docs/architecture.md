# 总体架构

```text
用户 API
Tensor / nn / optim / data
            │
            ▼
自动微分
计算图 / backward
            │
            ▼
算子分派
            │
      ┌─────┴─────┐
      ▼           ▼
 CPU Backend   可选加速后端
```

开发基础设施与框架主体分离：Skill 和诊断工具负责提升开发与验证效率，不进入框架运行时依赖。
