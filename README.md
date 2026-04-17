# lib_safe_const

安全地存取物件內部常數、實例變數與方法的輕量 Ruby 模組。提供 fallback 語法，在不事先確認目標是否存在的情況下取值。

純 Ruby 實作，**無任何外部依賴**。

## 安裝

本 gem 不發布至 rubygems.org，請透過 GitHub tag 安裝。在你的 `Gemfile` 中加入：

```ruby
gem "lib_safe_const", github: "ohmkao/lib_safe_const", tag: "v1.0.0"
```

然後執行：

```bash
bundle install
```

## 使用

```ruby
class MyClass
  include LibSafeConst

  MY_CONST = "hello"

  def initialize
    @my_var = "world"
  end

  def greet
    "greeting"
  end
end

obj = MyClass.new
```

### `safe_const`

安全取得常數，未定義時回傳 `nil`（不拋錯）：

```ruby
obj.safe_const(:MY_CONST)    # => "hello"
obj.safe_const(:NOT_EXIST)   # => nil
obj.safe_const(:my_const)    # => "hello"（自動大寫轉換）
```

### `safe_fetch`

依序從多個來源取值，回傳第一個非 `nil` 的結果：

```ruby
obj.safe_fetch(:MY_CONST)                    # => "hello"（常數）
obj.safe_fetch(:@my_var)                     # => "world"（實例變數）
obj.safe_fetch(:__greet__)                   # => "greeting"（方法呼叫）
obj.safe_fetch("default")                    # => "default"（一般值）

# 多來源 fallback：第一個非 nil 的勝出
obj.safe_fetch(:NOT_EXIST, :@my_var, "fallback")
# => "world"
```

#### 參數規則

| 形式 | 行為 |
|---|---|
| `:XXXX_YYYY`（全大寫 Symbol） | 查找同名常數 |
| `:@xxx`（`@` 開頭 Symbol） | 讀取實例變數 |
| `:__xxx__`（雙底線前後綴 Symbol） | 呼叫同名方法（`try`，方法不存在不拋錯） |
| `:xxx`（一般小寫 Symbol） | 視為一般值直接回傳 |
| 其他（String / Integer / Hash / ...） | 直接回傳 |

### Class Method

`include LibSafeConst` 後也會自動 `extend`，class 層級同樣可用：

```ruby
MyClass.safe_const(:MY_CONST)   # => "hello"
MyClass.safe_fetch(:MY_CONST)   # => "hello"
```

## 開發

```bash
bundle install
bundle exec rspec
```

## 授權

[MIT License](LICENSE)

## 相關

本 gem 自 [Abyss Portal](https://github.com/ohmkao/abyss_portal) 專案的 `app/lib/` 系列通用模組抽出。
