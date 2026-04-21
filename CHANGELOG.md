# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-04-22

### Added
- `safe_fetch_local(*args)` — `safe_fetch` 的精確版：
  - 常數查找使用 `inherit: false`（僅當前類別，不走祖先鏈）
  - 支援 `Proc` / `Lambda` fallback：傳入 Proc 物件會被自動 `.call`，避免 eager evaluation 副作用
  - 適用於「內部程式邏輯 + 需精確常數來源 + 有昂貴 fallback」的場景
- RSpec 新增 `safe_fetch_local` 測試 context（+8 examples）

### Changed
- 內部抽出 `_do_safe_fetch` private helper，`safe_fetch` / `safe_fetch_local` 共用底層邏輯
- `safe_fetch` 對外語意**完全不變**（inherit: true、Proc 視為字面值）

### Fixed
- 修正 `safe_fetch` 既有 sentinel bug：所有 args 皆為 nil 時，原本回傳 `NilClass` class 物件（**truthy**，導致 `safe_fetch(...) || "default"` 不走 fallback），修正為回傳真正的 `nil`
- 相關 spec（`所有來源都是 nil 時` / `無參數`）移除 `satisfy` 容忍 matcher，改為嚴格 `to be_nil`

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
