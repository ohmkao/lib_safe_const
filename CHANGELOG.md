# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-22

### Added
- `safe_const` 新增 `inherit:` 關鍵字參數（預設 `true`，向後相容）
  - `inherit: false` 僅查當前類別的常數，不走祖先鏈
  - 適用於需要精確控制常數來源的場景（例如子類別獨立宣告、避免誤繼承）
- RSpec 新增 `inherit:` 參數的測試 context

### Notes
- `safe_fetch` 內部仍以預設 `inherit: true` 呼叫 `safe_const`，維持既有行為

## [1.0.1] - 2026-04-18

### Changed
- `README.md` 提供中英雙語版本（bilingual Traditional Chinese / English）
- 無程式碼變更 — 純文件更新

## [1.0.0] - 2026-04-18

### Added
- `safe_const(const_name, obj = self)`：安全取得常數，未定義時回傳 `nil`
- `safe_fetch(*args)`：依序取值並 fallback，支援：
  - `:CONST_NAME` 全大寫 Symbol → 常數查找
  - `:@instance_var` → 實例變數
  - `:__method_name__` 雙底線前後綴 → 方法呼叫（`try`）
  - 其他型別（String / Integer / Hash 等）→ 直接回傳
- 自動 `extend` 與 `include`：同一 `include LibSafeConst` 即可在 instance 與 class 層級使用
- RSpec 測試覆蓋（25 examples）

### Changed（相較於原 v4 實作）
- 移除對 ActiveSupport 的依賴：
  - `String#in?` → `Array#include?`
  - `Object#try` → `respond_to?` + `send`
  - 行為完全等價，但本 gem 可在純 Ruby 環境使用

### Notes
- 本 gem 自 Abyss Portal 專案 `app/lib/lib_safe_const.rb` v4（2025-02-12）抽出
- 純 Ruby 實作，無任何外部依賴
