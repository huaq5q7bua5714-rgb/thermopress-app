# 免费测试到自己 iPhone 的路线

这个项目可以先用 GitHub Actions 的 macOS 机器构建一个未签名 IPA，然后在 Windows 上用你自己的 Apple ID 签名并安装到自己的 iPhone。

## 需要准备

- 一个 GitHub 仓库，用来放这个 Flutter 项目。
- 一台连接到 Windows 的 iPhone。
- 你自己的 Apple ID。
- 一个 Windows 旁加载工具，例如 AltStore 或 Sideloadly。

免费 Apple ID 旁加载只适合个人测试，通常 7 天会过期，过期后需要重新签名安装。

## 生成未签名 IPA

1. 把这个项目推送到 GitHub。
2. 打开 GitHub 仓库页面。
3. 进入 `Actions`。
4. 选择 `Build unsigned iOS IPA`。
5. 点击 `Run workflow`。
6. 构建完成后，下载 `ThermoPress-unsigned-ipa` artifact。

下载出来的 artifact 里会有 `ThermoPress-unsigned.ipa`。

## 在 Windows 上安装到 iPhone

1. 用 USB 连接 iPhone 和 Windows。
2. 打开旁加载工具。
3. 选择 `ThermoPress-unsigned.ipa`。
4. 用你自己的 Apple ID 签名。
5. 安装到连接的 iPhone。
6. 如果 iPhone 提示信任开发者，在系统设置里信任该 Apple ID 对应的开发者资料。

## iPhone 真机测试清单

- App 能正常打开。
- 首次启动时允许蓝牙权限。
- 能扫描到 BLE 设备。
- 能连接设备。
- 点击开始测量后，温度和压力曲线实时更新。
- 停止测量后，历史记录和 CSV 数据能打开。
