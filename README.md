[中文](./README.md) | [English](./README_EN.md)

# Claude Code 安全扫描 Skill

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/KimYx0207/SkillSemgrep?style=social)
![GitHub forks](https://img.shields.io/github/forks/KimYx0207/SkillSemgrep?style=social)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/Claude_Code-2.1.39-green.svg)

</div>

> 老金的开源知识库，实时更新群二维码：https://my.feishu.cn/wiki/OhQ8wqntFihcI1kWVDlcNdpznFf

## 📞 联系方式

<div align="center">
  <img src="images/二维码基础款.png" alt="联系方式" width="600"/>
  <p><strong>获取更多AI资讯和技术支持</strong></p>
  <p>微信公众号：获取AI第一信息 | 个人微信号：备注'AI'加群交流</p>
</div>

### ☕ 请我喝杯咖啡

<div align="center">
  <p><strong>如果这个教程对你有帮助，欢迎打赏支持！</strong></p>
  <table align="center">
    <tr>
      <td align="center">
        <img src="images/微信.jpg" alt="微信收款码" width="300"/>
        <br/>
        <strong>微信支付</strong>
      </td>
      <td align="center">
        <img src="images/支付宝.jpg" alt="支付宝收款码" width="300"/>
        <br/>
        <strong>支付宝</strong>
      </td>
    </tr>
  </table>
</div>

---

## 概述

说句中文就能扫漏洞。

基于 [Semgrep](https://semgrep.dev/) 的代码安全扫描技能，安装后在 Claude Code 里用自然语言触发安全扫描，无需记任何命令。

## 它能干什么

- **全面安全扫描**：自动检测 OWASP Top 10 漏洞
- **密钥泄露检测**：找出代码里硬编码的 API Key、密码、Token
- **多语言支持**：Python、JavaScript/TypeScript、Go 等几十种语言
- **结构化报告**：按高危/中危/低危分类，附带修复建议
- **中文触发**：说"安全扫描"、"扫漏洞"就能用，也支持英文和斜杠命令

## 前置要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 已安装

Python 和 Semgrep 不用你手动装，安装脚本会自动搞定。

## 安装

### 方式一：Clone + 一键安装（推荐）

```bash
git clone https://github.com/KimYx0207/SkillSemgrep.git
cd SkillSemgrep
```

**Mac / Linux：**

```bash
bash install.sh
```

**Windows（PowerShell）：**

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

**Windows（Git Bash）：**

```bash
bash install.sh
```

脚本会自动：
1. 检测 Python（未安装会提示下载链接）
2. 检测并安装 Semgrep（未安装会自动 `pip install`）
3. 复制 SKILL.md 到 Skill 目录
4. 验证安装成功

### 方式二：手动安装

如果你不想跑脚本，三步搞定：

**Mac / Linux：**

```bash
pip install semgrep
mkdir -p ~/.claude/skills/code-security
curl -fsSL https://raw.githubusercontent.com/KimYx0207/SkillSemgrep/main/SKILL.md -o ~/.claude/skills/code-security/SKILL.md
```

**Windows（PowerShell）：**

```powershell
pip install semgrep
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude\skills\code-security" -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/KimYx0207/SkillSemgrep/main/SKILL.md" -OutFile "$env:USERPROFILE\.claude\skills\code-security\SKILL.md"
```

安装完成，不需要重启 Claude Code。**Hot Reloading** 会自动加载新 Skill。

### 安装位置说明

| 位置 | 路径 | 作用域 |
|------|------|--------|
| 全局（推荐） | `~/.claude/skills/code-security/SKILL.md` | 所有项目可用 |
| 项目级 | `.claude/skills/code-security/SKILL.md` | 仅当前项目 |

## 使用方法

### 自然语言触发

在 Claude Code 里直接说：

```
安全扫描一下这个项目
```

```
扫一下有没有漏洞
```

```
检查一下密钥有没有泄露
```

```
对 src 目录做个安全检查
```

### 斜杠命令

```
/code-security
```

### 扫描模式

| 模式 | 触发方式 | 规则集 |
|------|---------|--------|
| 全面扫描 | "安全扫描" | `--config auto` |
| OWASP审计 | "OWASP扫描" | `p/security-audit` |
| 密钥检测 | "扫密钥泄露" | `p/secrets` |
| Python专项 | "扫一下Python代码" | `p/python` + `p/bandit` |
| JS/TS专项 | "检查JS安全" | `p/javascript` + `p/typescript` |
| Go专项 | "Go代码安全检查" | `p/golang` |

## 报告示例

扫描完成后，Claude Code 会输出结构化报告：

```
扫描摘要
├── 扫描工具：Semgrep v1.152.0
├── 规则集：auto
├── 扫描文件数：127
└── 发现问题数：5

高危（必须修复）
├── src/auth.py:42  SQL注入风险 - 使用参数化查询替代字符串拼接
└── config/db.js:15 硬编码数据库密码 - 移到环境变量

中危（建议修复）
├── utils/http.py:88  未验证SSL证书 - 启用verify=True
└── api/upload.js:23  未限制上传文件大小 - 添加size限制

低危
└── tests/mock.py:5  测试文件中的弱密码 - 仅影响测试环境
```

## SKILL.md 官方格式说明

本项目遵循 Claude Code 官方 Skill 格式：

| 字段 | 说明 |
|------|------|
| `name` | Skill 唯一标识，同时也是 `/斜杠命令` 名 |
| `description` | Claude 靠这个做语义匹配，决定什么时候自动加载 |
| `version` | 版本号 |
| `context: fork` | 在隔离上下文执行，不影响主对话 |

`description` 是最关键的字段。Claude Code 用它做语义匹配——你说"安全扫描"，它去匹配所有 Skill 的 description，找最相关的加载。所以 description 里要把触发条件写清楚，中英文都可以。

## 自定义

### 添加新的扫描规则

编辑 `SKILL.md`，在"核心能力"部分添加新的扫描命令：

```markdown
### 6. Docker安全扫描

```bash
semgrep scan --config "p/docker-compose"
```
```

### 修改报告格式

编辑 `SKILL.md` 的"报告格式"部分，按你的需求调整输出模板。

修改后保存即可，Claude Code 的 Hot Reloading 会自动生效。

## Semgrep vs Claude Code Security

| 维度 | Semgrep（本Skill） | Claude Code Security |
|------|-------------------|---------------------|
| 原理 | 规则模式匹配 | AI理解代码逻辑 |
| 速度 | 快 | 较慢 |
| 误报率 | 中等 | 低（多阶段自我验证） |
| 发现能力 | 已知漏洞模式 | 可发现全新类型漏洞 |
| 价格 | 免费开源 | Enterprise/Team客户 |
| 可用性 | 现在就能用 | 限量预览中 |

本 Skill 基于 Semgrep，适合日常开发的安全检查。等 Claude Code Security 开放后可以升级。

## 背景

2026年2月20日，Anthropic 发布 Claude Code Security，在测试阶段找出了 500 多个零日漏洞。消息一出，CrowdStrike 跌了 8%，Okta 跌了 9.2%。

但 Claude Code Security 目前只对 Enterprise 和 Team 客户开放。这个 Skill 是免费替代方案——用 Semgrep 做基础安全扫描，集成到 Claude Code 里，说句话就能用。

## License

MIT
