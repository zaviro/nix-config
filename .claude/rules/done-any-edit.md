# 编辑配置后执行流程

每次修改 Nix 配置后，按以下顺序执行：

```bash
# 1. 编辑配置

# 2. 代码格式化（社区规范，统一风格）
nix fmt

# 3. 前置校验：检查语法、引用错误（提前排坑）
nix flake check

# 4. 【依赖更新环节】更新 flake.lock（二选一）
# 方案A：全量更新所有依赖（日常通用）
nix flake update

# 方案B：只更新指定依赖（追求稳定/局部升级，比如仅更新 home-manager）
# nix flake lock --update-input home-manager

# 5. 更新 lock 后再次校验（必做！防止新依赖引入兼容问题）
nix flake check

# 6. 预构建测试（只构建不激活，确认能正常编译）
nh home build --flake ~/nix-config

# 7. 正式激活切换（应用新配置 + 新依赖）
nh home switch --flake ~/nix-config

# 8. 验证配置修改后系统行为符合预期

# 9. 统一提交所有变更（配置代码 + 改动后的 flake.lock 一起提交）
git add .
git commit -m "提交信息"
```
