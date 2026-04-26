---
name: lib_safe_const
description: 安全存取常數 / 實例變數 / 方法的輕量 Ruby 模組（純 Ruby、零依賴）。本 skill 是設計者視角的完整文件，含 API 規範、使用情境決策樹、設計動機與演進歷程。
---

# lib_safe_const — Skill (設計者視角)

> 本 skill 為 gem 維護端的 single source of truth。下游 abyss_portal 母專案僅保留「使用速查表」並連回此處。
> 對外使用快速上手請見 [README.md](../../../README.md)；版本變更紀錄見 [CHANGELOG.md](../../../CHANGELOG.md)；設計決策動機見 [DECISIONS.md](../../../DECISIONS.md)。

## 概述

`LibSafeConst` 提供三個方法：在不事先確認目標是否存在的情況下安全取得**常數 / 實例變數 / 方法回傳值**，並支援多來源 fallback。

- **純 Ruby 實作**，無任何外部依賴（v1.0.0 抽 gem 時剝離 ActiveSupport — 詳見 DECISIONS）
- `include LibSafeConst` 後 instance / class 兩層皆可用（自動 `extend`）
- 來源：自 [Abyss Portal](https://github.com/ohmkao/abyss_portal) 的 `app/lib/lib_safe_const.rb` v4（2025-02-12）抽出

---

## API 速查

| 方法 | 簽章 | 用途 | 引入版本 |
|---|---|---|---|
| `safe_const` | `safe_const(const_name, obj = self, inherit: true)` | 安全取常數，未定義回 `nil` | v1.0.0；`inherit:` v1.1.0+ |
| `safe_fetch` | `safe_fetch(*args)` | 多來源依序取值，回第一個非 `nil` | v1.0.0 |
| `safe_fetch_local` | `safe_fetch_local(*args)` | `safe_fetch` 精確版：`inherit: false` + Proc lazy fallback | v1.2.0+ |

### 參數識別規則（`safe_fetch` / `safe_fetch_local` 共用）

| 形式 | 行為 | 範例 |
|---|---|---|
| `:XXXX_YYYY`（全大寫 Symbol） | 查找同名常數 | `safe_fetch(:API_KEY)` |
| `:@xxx`（`@` 開頭 Symbol） | 讀取實例變數 | `safe_fetch(:@user_id)` |
| `:__xxx__`（雙底線前後綴 Symbol） | 呼叫同名方法（不存在不拋錯） | `safe_fetch(:__current_user_id__)` |
| `:xxx`（一般小寫 Symbol） | 視為一般值直接回傳 | `safe_fetch(:fallback)` |
| 其他（String / Integer / Hash / Proc / ...） | 直接回傳（`safe_fetch_local` 對 `Proc` 例外，自動 `.call`） | `safe_fetch("default")` |

> **注意**：`:__xxx__` 雙底線是 v4（2025-02-12）的 API 變更，原 `:xxx` 全小寫已不再觸發方法呼叫。

---

## 使用情境決策樹

### `safe_const` vs `safe_fetch`

- 只想取**單一**常數 → `safe_const`
- 要從**多個來源**依序 fallback → `safe_fetch`

### `safe_fetch` vs `safe_fetch_local`

兩者語意差別**只有兩點**，但通常綁在一起：

| 行為 | `safe_fetch` | `safe_fetch_local` |
|---|---|---|
| 常數查找 | `inherit: true`（含祖先鏈） | `inherit: false`（僅當前類別） |
| 遇 `Proc` / `Lambda` | 視為字面值直接回傳 | 自動 `.call`（lazy evaluation） |

**決策**：

- 一般使用者層級 fallback（讀子類別 / instance 自訂值，falls through 到模組預設常數）→ `safe_fetch`
- 內部框架邏輯需「精確控制常數來源 + 昂貴 fallback」→ `safe_fetch_local`
  - 典型例：`lib_auto_registry` 讀子類別 `REGISTRY_*` 常數，避免誤繼承 owner 層級設定

```ruby
# 一般 fallback：祖先鏈會吃到 Parent 的 SHARED
Child.safe_fetch(:SHARED, "default")        # => "from_parent"

# 精確版：只查 Child 自己 + Proc 只在前面都 nil 時才執行
Child.safe_fetch_local(:SHARED, -> { expensive_compute })
```

---

## 典型使用範例

### 1. 常數 fallback

```ruby
class MyService
  include LibSafeConst

  DEFAULT_TIMEOUT = 30

  def timeout
    safe_fetch(:TIMEOUT, :DEFAULT_TIMEOUT)  # 沒覆寫就用預設
  end
end
```

### 2. 實例變數 + 方法 + 字面值串接

```ruby
class MyService
  include LibSafeConst

  def user_id
    safe_fetch(:@custom_user_id, :__current_user_id__, 0)
  end

  def current_user_id
    Current.user&.id
  end
end
```

### 3. 從其他物件取常數

```ruby
def get_provider_config(provider_class)
  safe_const(:API_CONFIG, provider_class)
end
```

### 4. 子類別精確查找 + 昂貴 fallback（v1.2.0+）

```ruby
class Child < Parent
  include LibSafeConst
end

# Child 沒自己的 REGISTRY_PREFIX 時才執行 expensive_default
Child.safe_fetch_local(:REGISTRY_PREFIX, -> { expensive_default })
```

---

## 與 `lib_auto_registry` 的耦合

`lib_safe_const` v1.1 與 v1.2 的兩次擴張**都源自 lib_auto_registry 的需求**：

- v1.1.0：`lib_auto_registry` v2.0.1 開始用 `safe_const(..., inherit: false)` 讀子類別 `REGISTRY_PREFIX` / `REGISTRY_ABSTRACT`，避免誤繼承 owner 層級設定
- v1.2.0：`lib_auto_registry` 的 fallback 路徑常需要 lazy 計算（避免 eager 觸發 DB / registry 重算），催生 `safe_fetch_local` + Proc 自動 `.call` 語意

**邊界**：`lib_safe_const` 本身不依賴 `lib_auto_registry`；耦合僅單向（registry 用 const）。新版本 API 變動時應驗證 lib_auto_registry 仍正確運作。

---

## 演進摘要

| 版本 | 重點 | 動機 |
|---|---|---|
| v1.0.0 | 抽 gem，剝離 ActiveSupport（`in?` / `try` 改純 Ruby） | 讓非 Rails 環境也能用 |
| v1.0.1 | README 中英雙語 | 對外可讀性 |
| v1.1.0 | `safe_const` 加 `inherit:` keyword | lib_auto_registry 子類別精確查找 |
| v1.2.0 | 新增 `safe_fetch_local` + 修 sentinel bug | lib_auto_registry 需要 lazy fallback；舊 `safe_fetch(...) || x` 寫法因 NilClass sentinel truthy 沒走 fallback |

> **為什麼 v1.1 選 keyword、v1.2 卻選新方法？** 詳見 [DECISIONS.md](../../../DECISIONS.md)。

---

## Sentinel Bug（v1.2.0 修正）

> [!WARNING]
> v1.0.0 ~ v1.1.0 有此 bug。升級到 v1.2.0 即可修正，**呼叫端無需改動**。

**症狀**：

```ruby
# v1.1.0 以前
safe_fetch(:NOT_EXIST, :@nope) || "default"
# => NilClass（class 物件，truthy） — 不走 fallback！
```

**根因**：原實作借 `NilClass` class 作為 sentinel 推進 args，全 nil 時某些路徑會回傳 `NilClass` 物件本身（`is_a?(NilClass)` 為 false，但物件本身 truthy）。

**修法**：v1.2.0 內部抽 `_do_safe_fetch` 用 `each + return` 模式，全 nil 顯式回 `nil`。對外語意不變，僅修正錯誤回傳值。詳見 [DECISIONS.md](../../../DECISIONS.md) v1.2.0 段落。

---

## 開發

```bash
bundle install
bundle exec rspec
```

測試覆蓋：v1.2.0 共 39 examples。

---

## 連結

- [README.md](../../../README.md) — 對外快速上手（中英雙語）
- [CHANGELOG.md](../../../CHANGELOG.md) — Keep-a-Changelog 格式變更紀錄
- [DECISIONS.md](../../../DECISIONS.md) — 設計決策動機流水帳
- [GitHub repo](https://github.com/ohmkao/lib_safe_const)
