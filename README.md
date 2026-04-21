# lib_safe_const

> 安全地存取物件內部常數、實例變數與方法的輕量 Ruby 模組。純 Ruby 實作，**無任何外部依賴**。
> A lightweight Ruby module for safely accessing constants, instance variables, and methods. Pure Ruby, **zero dependencies**.

[中文](#中文) | [English](#english)

---

## 中文

提供 `safe_const` 與 `safe_fetch` 兩個方法，在不事先確認目標是否存在的情況下安全取值，並支援多來源 fallback 語法。

### 安裝

本 gem 不發布至 rubygems.org，請透過 GitHub tag 安裝。在你的 `Gemfile` 中加入：

```ruby
gem "lib_safe_const", github: "ohmkao/lib_safe_const", tag: "v1.2.0"
```

然後執行：

```bash
bundle install
```

### 使用

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

#### `safe_const`

安全取得常數，未定義時回傳 `nil`（不拋錯）：

```ruby
obj.safe_const(:MY_CONST)    # => "hello"
obj.safe_const(:NOT_EXIST)   # => nil
obj.safe_const(:my_const)    # => "hello"（自動大寫轉換）
```

自 **v1.1.0** 起支援 `inherit:` 關鍵字參數（預設 `true`）。`inherit: false` 時僅查當前類別，不走祖先鏈：

```ruby
class Parent
  include LibSafeConst
  INHERITED = "from_parent"
end

class Child < Parent; end

Child.safe_const(:INHERITED)                  # => "from_parent"（預設繼承）
Child.safe_const(:INHERITED, inherit: false)  # => nil（僅查自己）
```

#### `safe_fetch`

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

##### 參數規則

| 形式 | 行為 |
|---|---|
| `:XXXX_YYYY`（全大寫 Symbol） | 查找同名常數 |
| `:@xxx`（`@` 開頭 Symbol） | 讀取實例變數 |
| `:__xxx__`（雙底線前後綴 Symbol） | 呼叫同名方法（方法不存在不拋錯） |
| `:xxx`（一般小寫 Symbol） | 視為一般值直接回傳 |
| 其他（String / Integer / Hash / ...） | 直接回傳 |

#### Class Method

`include LibSafeConst` 後也會自動 `extend`，class 層級同樣可用：

```ruby
MyClass.safe_const(:MY_CONST)   # => "hello"
MyClass.safe_fetch(:MY_CONST)   # => "hello"
```

### 開發

```bash
bundle install
bundle exec rspec
```

### 授權

[MIT License](LICENSE)

### 相關

本 gem 自 [Abyss Portal](https://github.com/ohmkao/abyss_portal) 專案的 `app/lib/` 系列通用模組抽出。

---

## English

Provides two methods — `safe_const` and `safe_fetch` — that let you read constants, instance variables, or invoke methods without checking existence first, with built-in fallback chains.

### Installation

This gem is not published to rubygems.org. Install it via GitHub tag. Add to your `Gemfile`:

```ruby
gem "lib_safe_const", github: "ohmkao/lib_safe_const", tag: "v1.2.0"
```

Then run:

```bash
bundle install
```

### Usage

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

#### `safe_const`

Safely fetch a constant; returns `nil` if undefined (no exception raised):

```ruby
obj.safe_const(:MY_CONST)    # => "hello"
obj.safe_const(:NOT_EXIST)   # => nil
obj.safe_const(:my_const)    # => "hello" (auto-uppercased)
```

Since **v1.1.0**, `safe_const` accepts an `inherit:` keyword argument (default `true`). Pass `inherit: false` to look up the constant on the current class only, skipping ancestors:

```ruby
class Parent
  include LibSafeConst
  INHERITED = "from_parent"
end

class Child < Parent; end

Child.safe_const(:INHERITED)                  # => "from_parent" (default: inherits)
Child.safe_const(:INHERITED, inherit: false)  # => nil (own-class only)
```

#### `safe_fetch`

Iterate through sources in order and return the first non-`nil` result:

```ruby
obj.safe_fetch(:MY_CONST)                    # => "hello"   (constant)
obj.safe_fetch(:@my_var)                     # => "world"   (instance variable)
obj.safe_fetch(:__greet__)                   # => "greeting" (method call)
obj.safe_fetch("default")                    # => "default" (literal value)

# Fallback chain — first non-nil wins
obj.safe_fetch(:NOT_EXIST, :@my_var, "fallback")
# => "world"
```

##### Argument rules

| Form | Behavior |
|---|---|
| `:XXXX_YYYY` (all-uppercase Symbol) | Look up the constant |
| `:@xxx` (Symbol starting with `@`) | Read the instance variable |
| `:__xxx__` (double-underscore wrapped Symbol) | Call the method (no error if method is missing) |
| `:xxx` (regular lowercase Symbol) | Treated as a literal value, returned as-is |
| Anything else (String / Integer / Hash / ...) | Returned as-is |

#### Class Methods

`include LibSafeConst` also `extend`s the class, so both methods are available at the class level:

```ruby
MyClass.safe_const(:MY_CONST)   # => "hello"
MyClass.safe_fetch(:MY_CONST)   # => "hello"
```

### Development

```bash
bundle install
bundle exec rspec
```

### License

[MIT License](LICENSE)

### Origin

This gem was extracted from the shared utility modules under `app/lib/` in the [Abyss Portal](https://github.com/ohmkao/abyss_portal) project.
