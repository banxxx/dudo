# dudo

> 一个使用 Flutter 构建的 Material You 风格在线/本地小说阅读应用。
>
> 作者：**banxxx**

## ✨ 特性

- Material 3 / Material You：动态取色（Android 12+）+ 品牌种子色 fallback
- Riverpod + get_it + injectable 的现代架构分层
- drift (SQLite) + Hive + shared_preferences 三层本地存储
- dio 网络层（Cookie 持久化、并发下载、指数退避重试）
- Legado 3.0 兼容的书源规则引擎（CSS / XPath / JSONPath / Regex）
- flutter_tts + audio_service 后台朗读，支持锁屏控制
- go_router + 平台自适应（手机/平板/横屏/双页）

## 🗂 目录结构

```
lib/
├── app/              # 应用入口、路由、DI
├── core/             # 基础设施：数据库 / 网络 / 书源引擎 / TTS / 工具
├── features/         # 业务模块：bookshelf / search / reader / sources / profile
├── shared/           # 主题、通用组件、国际化
└── main.dart
```

## 🚀 开始

> ⚠️ 首次拉取后，需要先用 `flutter create .` 为本目录生成原生平台外壳
> （android / ios / linux / macos / windows / web），它会复用现有的
> `pubspec.yaml`，**不会**覆盖 `lib/`。

```bash
# 1. 生成原生平台目录（只需一次）
flutter create . --org com.banxxx --project-name dudo \
  --platforms=android,ios,windows,macos,linux,web

# 2. 拉取依赖
flutter pub get

# 3. 跑代码生成（drift / freezed / injectable / riverpod / json）
dart run build_runner build --delete-conflicting-outputs

# 4. 启动
flutter run
```

## 🎨 主题

- 全局：M3 动态取色，种子色 `#446355`
- 阅读器：羊皮纸 / 护眼绿 / 简白 / 夜间，独立于全局主题
- 字体：默认 Noto Sans SC；阅读器可切换 Noto Serif SC

## 🧩 书源引擎

`core/rule_engine/` 内的 `RuleEngine` + `ParserRegistry` 抽象，目前内置四种解析器骨架：
CSS、XPath、JSONPath、Regex，可按 Legado 3.0 JSON 直接导入 `SourceRule`。

## 🔉 TTS

`core/tts/tts_service.dart` 是单例服务，初始化 `flutter_tts` 与 `audio_service`，并提供
`TtsAudioHandler` 用于在锁屏 / 通知栏控制朗读。
