# Design Decisions

設計決策流水帳。每個版本記錄「為什麼這樣選」— 哪些選項被考慮、決策動機、後果。
做了什麼的事實清單請見 [CHANGELOG.md](CHANGELOG.md)。

倒序排列，最新在最上面。

---

## v1.2.0 (2026-04-22) — `safe_fetch_local` 為什麼是新方法、不是 keyword

### 背景

`lib_auto_registry` v2.x 子類別讀 `REGISTRY_*` 常數時需要兩件事同時成立：

1. **inherit: false** — 不能誤繼承 owner 層級的 `REGISTRY_PREFIX` / `REGISTRY_ABSTRACT`
2. **lazy fallback** — fallback 可能涉及 DB 查詢 / registry 重算，不希望 eager 觸發

### 選項

- **A) keyword 路線**：`safe_fetch(*args, inherit: false, lazy: true)`
- **B) 新方法路線**：`safe_fetch_local(*args)` — 把兩個非預設行為打包成一個拋棄式組合

### 決策：B

### 動機

- 同時改變**兩個語意維度**（常數查找祖先鏈 + Proc 處理），打包成新方法比兩個 keyword 清晰
- 對比 v1.1.0 `safe_const` 加 `inherit:` keyword：那次只改一個 boolean 維度，且對齊 Ruby 原生 `const_defined?(name, inherit=true)` 慣例 — 路線不同有理
- 名字 `_local` 表達「鎖定當前作用域」，可讀性勝過呼叫端寫 `inherit: false, lazy: true`
- 想要「精確 + lazy fallback」的場景幾乎總是綁在一起；獨立 keyword 反而會誘人單獨打開、產生半套組合

### 後果

- API 表面增加一個方法
- `safe_fetch` 對外語意**完全不變**（向後相容）
- 內部抽 `_do_safe_fetch(args, inherit:, lazy:)` private helper，兩者共用底層邏輯

---

## v1.2.0 (2026-04-22) — 為什麼 `safe_fetch` 本身不擴張 Proc 支援

### 背景

v1.2.0 加 lazy fallback 時，理論上有兩條路：

- **A) 直接擴張既有方法**：在 `safe_fetch` 加 Proc 自動 `.call`
- **B) 拆出 `safe_fetch_local`**：新方法，預設 Proc 自動 `.call`

選了 B。除了「兩個維度打包成新方法」（見上一條目）之外，還有 4 個獨立論點支持「`safe_fetch` 本身**不能**擴張」：

### 論點 1：向後相容（contract 問題）

v1.0 / v1.1 已對外發布。呼叫端就算罕見，也可能傳 Proc 當「字面值 fallback」（例如把 Proc 物件本身當 sentinel / 標記）。改成自動 `.call` 是**靜默 breaking change** — 比 sentinel bug 還嚴重，因為 sentinel 是修錯誤、這個是改正確語意。

### 論點 2：語義一致性（API 美學）

`safe_fetch` 的識別規則：「**Symbol 才有特殊處理**（常數 / 實例變數 / 方法），其他型別**一律字面值**」。Proc 屬「其他型別」，特例化它會讓識別表多一個分支，破壞最小驚訝。

### 論點 3：fallback 多半 cheap，不需 lazy

實際使用 95% 是 `safe_fetch(:CONST, "default")` / `safe_fetch(:@var, 0)`，fallback cost ≈ 0。為了 5% 昂貴 fallback 改變預設語意不划算。

### 論點 4：意圖明示原則

Lazy evaluation 是**想要**的特殊行為，不是**應該**的預設。要 lazy 就 opt-in 到 `_local`，不要在 `safe_fetch` 偷偷觸發。避免帶副作用的 Proc 被意外 `.call`。

### 補：`safe_fetch(AAA.call, ...)` 不算「使用 Proc」

呼叫端寫 `safe_fetch(AAA.call, :ASDF, '00000')` 並**不是**讓 Proc 參與 fallback — Ruby 求值規則會在 method 呼叫前先 `.call`，Proc 退化成普通值，無論結果是字串、nil 或副作用都已發生。

```ruby
# Eager — AAA.call 一定先執行（無論後面有沒有值）
safe_fetch(AAA.call, :ASDF, '00000')
# 等同：safe_fetch(AAA.call_result, :ASDF, '00000')
# Proc 包裝在這完全沒意義

# Lazy — AAA 只在 :ASDF 為 nil 時才執行
safe_fetch_local(:ASDF, AAA)
```

要真正 lazy fallback **必須**傳 Proc 物件本身（不加 `.call`），並用 `safe_fetch_local`。

### 結論

`safe_fetch` 維持「Symbol 識別 + 其他字面值」的純粹語意；lazy fallback 走 `safe_fetch_local`。兩者並存是**有意的分工，不是冗餘**。

---

## v1.2.0 (2026-04-22) — sentinel bug 的修法

### 背景

v1.0.0 ~ v1.1.0 的 `safe_fetch` 借 `NilClass` class 作為 sentinel 推進 args：

```ruby
args.push(NilClass).each do |arg|
  ...
  break out_ unless out_.nil?
  break nil if arg.is_a?(NilClass)
end
```

**陷阱**：當所有 args 解析結果皆為 nil 時，某些路徑下 sentinel 會被當成「下一個 arg 的 out_」回傳 — 導致回傳的是 `NilClass` class 物件本身（**truthy**），而非真正的 `nil`。

呼叫端慣用的 `safe_fetch(...) || "default"` 寫法因此**不走 fallback**。

### 選項

- **A) sentinel 換成 unique object**（如 `SENTINEL = Object.new`）
- **B) 改用 `each + return` 模式**，顯式回 `nil`

### 決策：B

### 動機

- B 更直白，無需引入私有 sentinel 物件
- 結合「同時要新增 `safe_fetch_local`」的時機，順便把底層邏輯抽成 `_do_safe_fetch`，sentinel 問題自然消失
- 對外語意修正為文件原本宣稱的「全 nil 回 nil」

### 後果

- 舊寫法 `safe_fetch(...) || "default"` 從此正確走 fallback（**靜默修正**，無破壞性變更）
- spec 從 `satisfy { |v| v.nil? || v == NilClass }` 容忍 matcher 改為嚴格 `to be_nil`
- ⚠️ 若下游程式碼曾經**依賴錯誤的 `NilClass` 回傳值**做判斷，升級到 v1.2.0 後會失效；但這是錯誤用法，不視為 breaking change

### 後果分析（為什麼這 bug 值得修）

bug 不會在 `safe_fetch` 內部 crash，而是把 `NilClass` class 物件當「毒素」傳到下游後才出問題 — 屬於**靜默危險**。

行為對照：

| 操作 | v1.0/1.1（bug） | v1.2.0 |
|---|---|---|
| 回傳值 | `NilClass`（class 物件本身） | `nil` |
| `.nil?` | `false` | `true` |
| `== nil` | `false` | `true` |
| truthy？ | **truthy** | falsy |
| `.to_s` | `"NilClass"` | `""` |
| `.class` | `Class` | `NilClass` |

實務毒性場景（由低到高）：

1. **fallback 失效**：`safe_fetch(:NOT_EXIST) || "default"` 回傳 `NilClass`，不走 `||`
2. **短路判斷誤判**：`return unless safe_fetch(:OPT)` 因 truthy 不會 return，下游拿到 `NilClass`
3. **序列化下游污染**：`JSON.generate({ x: safe_fetch(:NOT_EXIST) })` → `'{"x":"NilClass"}'` — 字串 `"NilClass"` 寫進 JSON
4. **DB 寫入污染**：`record.update(field: safe_fetch(:NOT_EXIST))` → 欄位寫入字串 `"NilClass"` 或類型錯誤，比 `NULL` 更難察覺
5. **case/when 命中錯支**：`when Class` 會命中（`NilClass` 是 `Class` 的 instance）

debug 線索差別：v1.0/1.1 路徑拋的錯訊會出現 `NilClass:Class` 反直覺字串（class object 的 inspect 形式），易誤導為 metaclass / 元程式設計問題。

### 實務觸發頻率

慣用寫法多數帶非 nil 兜底（`safe_fetch(:KEY, "default")` / `safe_fetch(:K, [])`），fallback 字面值會在「全 nil」之前命中 — bug 在實務上**極少**實際觸發。

本次屬於**預防性修正**：拆除未爆彈，無 user-visible 故障需追溯。風險不在現有程式碼，而在未來新寫的「無兜底 + truthy 判斷」組合。

---

## v1.1.0 (2026-04-22) — `safe_const` 為什麼選 keyword、不是新方法

### 背景

`lib_auto_registry` 子類別誤繼承 owner 層級的 `REGISTRY_PREFIX` / `REGISTRY_ABSTRACT`，需要「只查當前類別、不沿祖先鏈」的常數查找。

### 選項

- **A) 新增方法**：`safe_const_local(const_name, obj = self)`
- **B) 加 keyword**：`safe_const(const_name, obj = self, inherit: true)`

### 決策：B

### 動機

- 對齊 Ruby 原生 `Module#const_defined?(name, inherit=true)` / `Module#const_get(name, inherit=true)` 簽章 — 使用者已經熟悉這個 boolean
- 只改**一個**維度（祖先鏈 on/off），keyword 清晰，不增加 API 表面
- 預設 `true` 維持向後相容

### 後果

- 後續 v1.2.0 因為要同時改**兩個**維度（常數查找 + Proc 處理），改採新方法路線（`safe_fetch_local`），與此次決策**路線不同**
- 這個對比是刻意的：單維度用 keyword、多維度組合包成新方法

---

## v1.0.0 (2026-04-18) — 抽 gem 為什麼剝離 ActiveSupport

### 背景

原 `app/lib/lib_safe_const.rb` v4（2025-02-12，於 abyss_portal 專案內）使用了 ActiveSupport 的 `String#in?` 與 `Object#try`。

### 選項

- **A) 保留 ActiveSupport 依賴**：抽 gem 但保留 `require "active_support/core_ext/..."`
- **B) 改寫成純 Ruby**：`Array#include?` 取代 `in?`、`respond_to?` + `send` 取代 `try`

### 決策：B

### 動機

- 通用工具不應強迫下游帶 ActiveSupport（含其載入時間與相依鏈）
- 純 Ruby 環境（不一定是 Rails 專案）也應可用
- 行為等價，沒有功能損失

### 後果

- gem 真正零依賴（gemspec 無 runtime dependency）
- abyss_portal 母專案行為完全不變
- README 標題突顯「pure Ruby, zero dependencies」作為對外賣點
