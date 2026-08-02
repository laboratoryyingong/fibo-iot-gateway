# Firmware 改动清单（App 联调后提出）

> 日期：2026-07-19 · 提出方：App 侧联调
> 对应固件：`esp32s3_bridge`（`main/ble_prov.c` / `main/net_config.c`）
> 协议基线：ble-provisioning-protocol.md v1
> 优先级：P0 必须 · P1 应该 · P2 可选

## 1. P0 — PoP 生产公式接入（产线注入身份）

App 侧已确定 PoP 生产公式（工厂密钥只存在产线工具，不进固件）：

```
pop = base32( HMAC-SHA256( FACTORY_KEY, serial ) )[:8]   # 小写 a-z2-7
serial = "FIBO-" + 12 位大写 MAC hex（完整 BT MAC）
ble 广播名 = "FIBO-" + MAC 后 3 字节（serial 的后 6 位 hex）
```

生成工具：本仓库 `docs/firmware/gen_pop.py`（读环境变量 `FIBO_FACTORY_KEY`）。

固件按文档 §6.7 已有 `hub-factory` endpoint，需核对/补齐以下行为：

- [ ] **持久化位置**：serial + pop 存独立 NVS namespace（如 `factory`），
      `hub-reset`（含 BOOT 10s）只擦 `config` 类数据，**绝不能擦 factory 数据**
      （文档已承诺"keeps the factory serial and PoP"，请确认实现一致）。
- [ ] **PoP 加载顺序**：启动时 NVS 有注入值 → 用注入值；没有 → 回退
      `fibo1234`（开发板行为不变）。
- [ ] **serial 与 MAC 一致性校验**：`hub-factory` 收到的 serial 内嵌 MAC
      应与本机 efuse MAC 比对，不一致返回
      `{"status":"invalid_args","reason":"mac_mismatch"}`，防止产线贴错标签。
- [ ] **pop 格式校验**：8 位 `[a-z2-7]`，不符返回 `invalid_args`。
- [ ] **二次注入保护**：已注入过身份的板子再次调用 `hub-factory` 应拒绝
      （当前仅"claimed 后拒绝"；建议改为"注入过即拒绝"，返修需专用解锁
      流程，防售后改身份）。

## 2. P0 — claim token 上云（文档 §10 标注"未实现"的缺口）

这是当前端到端闭环里唯一缺失的固件环节。App 已实现：BLE 写入
`hub-claim`（token 为不透明字符串 ≤256B）后轮询后端绑定状态。固件需要：

- [ ] `hub-claim` 收到 token → 持久化 NVS（已实现），并在**每次云连接建立后**
      将其上报：`hub` shadow 的 `reported.claim = "<token>"`（文档 §10 约定，
      最终字段名联调时定），附带 serial。
- [ ] 云端完成绑定后（建议通过 shadow `desired.claim_ack = true` 或 delta
      通知）：固件**清除本地 token 与 `reported.claim`**（token 一次性，
      避免长期暴露在 shadow 里）。
- [ ] 未收到 ack 前，每次重连云端都重报（幂等重试）。
- [ ] 断电重启不丢：token 上报状态机基于 NVS 值，不依赖内存。

## 3. P1 — `hub-info` 网络状态精细化

实测 `eth_link` 目前等于"拿到 IP"（文档 §6.2 自述）。App 无法区分
"没插网线"和"插了网线但 DHCP 失败"，两种情况的用户指引完全不同：

- [ ] `eth_link` 改为真实 PHY link 状态；
- [ ] 新增 `eth_ip` 保持现状（无地址 = `0.0.0.0`）；
- [ ] App 判断逻辑将变为：
      `link=false` → "请检查网线"；`link=true && ip=0.0.0.0` → "路由器未分配
      IP，建议配静态 IP"。
- [ ] 字段是新增/语义修正，按协议向后兼容原则做（unknown fields ignored），
      `proto-ver` 小版本 +1。

## 4. P1 — 提配窗口剩余时间

Claim 成功后窗口 5 分钟关闭，App 想给用户显示倒计时/在窗口将尽时提醒：

- [ ] `hub-info` 增加 `prov_win_s`：窗口剩余秒数（unclaimed 常开时为 -1）。

## 5. P2 — 可选增强（有则更好，不阻塞）

- [ ] **WiFi 扫描 endpoint**（如 `hub-wifi-scan` 0xFF59）：返回附近 2.4G
      SSID 列表（ssid/rssi/auth），App 就能做网络选择器而非手输 SSID。
      注意扫描期间 BLE 共存性能。
- [ ] `hub-info` 增加 `uptime_s`、`heap_free` 等诊断字段，App 详情页可展示。
- [ ] `hub-reset` 响应后延迟从 ~1.5s 提到 ~3s，给 BLE 层留足 indication
      送达时间（App 实测偶尔收不到最后一个响应，目前按超时容错处理）。

## 6. 产线 tester 侧配套（固件仓库 `tester/`）

- [ ] factory station 脚本集成 PoP 公式（可直接复制 `gen_pop.py` 的
      `derive_pop()`，密钥走 `FIBO_FACTORY_KEY` 环境变量）。
- [ ] 完整产线流程固化为一条命令：
      读 MAC → 组 serial → 算 pop → `hub-factory` 注入 → 用新 pop 重连验证
      握手 → 输出 QR label JSON（打印贴标）。
- [ ] 注入后自动做一次"验证握手失败"负测试（用错误 pop 连，应被拒），
      确保注入生效。

## 7. 联调时确认过、无需改动的点

- 广播包中包含 128-bit service UUID（Mac 实测 ✓），App 按 UUID 过滤 +
  广播名匹配，方案可行。
- security1 握手、全部 endpoint 的 JSON 契约与文档一致（App 侧纯 Dart
  实现已按文档 + 模拟设备对拍通过；真机对拍进行中）。
- QR label v1 格式不变；开发板 `sn=""` + 默认 PoP 的兼容路径保留。
