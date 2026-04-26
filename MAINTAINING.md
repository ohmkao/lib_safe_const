# Maintaining lib_safe_const

本 gem 的維護紀律 — 補充 [DECISIONS.md](DECISIONS.md)（記錄已做的決策）以外的「未來怎麼維護」。

---

## API Freeze Policy

v1.2.0（2026-04-22）後 API 凍結至少至 **2026-10-22**（6 個月）。

### 期間原則

- 不新增方法 / 不加 keyword
- 不改變現有方法的識別規則或預設行為
- 修 bug 可以發 patch（v1.2.x），但不夾帶任何 feature

凍結期過後重新評估；若實際使用回饋顯示 API 已夠用，凍結繼續延長。

### Why

兩次升級（v1.1 / v1.2）都由單一 consumer（`lib_auto_registry`）推動。每次擴張都有合理動機（見 [DECISIONS.md](DECISIONS.md)），但累積下來：

- Symbol 觸發規則 6 條
- `_local` 同時編碼兩個語意維度（`inherit: false` + Proc lazy）
- `safe_fetch` vs `safe_fetch_local` 對讀者已產生選擇成本

設計被單一下游拉著走的風險開始浮現。需要冷卻期讓**實際使用回饋自然累積**，再決定要不要再擴張。

---

## 擴張前必問：「能在呼叫端用組合解決嗎？」

凍結期結束後，若有擴張需求，**第一個問題必須是**：

> 這個需求能不能在呼叫端用現有 API 的組合解決？

只有在「組合明確不可行」或「組合產生的 boilerplate 在多個 consumer 重複」時，才考慮加方法 / keyword。

### 擴張選項優先順序（由輕到重）

| 順序 | 做法 | 何時用 |
|---|---|---|
| 1 | 呼叫端組合 | 預設選項，不動 gem |
| 2 | 內部 helper | gem 內部 private 用、不暴露 API |
| 3 | 新增 keyword | 單一語意維度變動（例：v1.1 `inherit:`） |
| 4 | 新增方法 | 多維度組合 + 命名能準確表達意圖（例：v1.2 `safe_fetch_local`） |
| 5 | 新增 helper class | 多個 `_xxx` 變體要加時才划算（例：`LibSafeConst::Strict`） |

跳過 1 直接到 3-5 是過去的失誤路徑，不應重複。

---

## Versioning

- **patch (1.2.x)**：bug fix only，不夾帶 feature
- **minor (1.x.0)**：feature 新增，向後相容
- **major (x.0.0)**：breaking change

> v1.2.0 把 `safe_fetch_local`（feature）跟 sentinel bug fix 綁一起發是維護失誤。下次：bug fix 走 patch、feature 走 minor，**就算實作上共用底層也分兩次發版**。
