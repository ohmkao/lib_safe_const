# frozen_string_literal: true

require "spec_helper"

RSpec.describe LibSafeConst do
  # 在檔案頂層定義測試用類別，避免常數重複定義 warning
  before(:all) do
    # 測試用類別：包含常數、實例變數、方法
    unless self.class.const_defined?(:TestSafeConst)
      self.class.const_set(:TestSafeConst, Class.new do
        include LibSafeConst

        const_set(:MY_CONST, "const_value")
        const_set(:ANOTHER_CONST, 42)
        const_set(:NIL_CONST, nil)

        def initialize
          @my_var = "var_value"
          @nil_var = nil
        end

        def my_method
          "method_result"
        end

        def nil_method
          nil
        end
      end,)
    end

    # 不含任何常數的空類別
    unless self.class.const_defined?(:EmptySafeConst)
      self.class.const_set(:EmptySafeConst, Class.new do
        include LibSafeConst
      end,)
    end
  end

  let(:instance) { self.class::TestSafeConst.new }
  let(:empty_instance) { self.class::EmptySafeConst.new }

  # =============================================
  # safe_const
  # =============================================
  describe "#safe_const" do
    context "常數已定義" do
      it "回傳常數值" do
        expect(instance.safe_const(:MY_CONST)).to eq("const_value")
      end

      it "回傳數值型常數" do
        expect(instance.safe_const(:ANOTHER_CONST)).to eq(42)
      end
    end

    context "常數未定義" do
      it "回傳 nil 而非拋出錯誤" do
        expect(instance.safe_const(:NOT_EXIST)).to be_nil
      end
    end

    context "從其他物件取得常數" do
      let(:other_class) do
        Class.new do
          const_set(:OTHER_VALUE, "from_other")
        end
      end

      it "透過第二參數指定來源物件" do
        expect(instance.safe_const(:OTHER_VALUE, other_class)).to eq("from_other")
      end
    end

    context "小寫輸入自動轉大寫" do
      it "將小寫 symbol 轉為大寫後查找常數" do
        expect(instance.safe_const(:my_const)).to eq("const_value")
      end
    end

    # =============================================
    # inherit: 參數（v1.1.0+）
    # =============================================
    context "inherit: 參數" do
      before(:all) do
        unless self.class.const_defined?(:InheritParent)
          self.class.const_set(:InheritParent, Class.new do
            include LibSafeConst
            const_set(:INHERITED_CONST, "from_parent")
          end,)
        end
        unless self.class.const_defined?(:InheritChild)
          self.class.const_set(:InheritChild, Class.new(self.class::InheritParent))
        end
      end

      it "預設 inherit: true 時會沿繼承鏈查找" do
        expect(self.class::InheritChild.safe_const(:INHERITED_CONST)).to eq("from_parent")
      end

      it "inherit: false 時僅查當前類別，不含繼承" do
        expect(self.class::InheritChild.safe_const(:INHERITED_CONST, inherit: false)).to be_nil
      end

      it "inherit: false 時當前類別有定義則正常取得" do
        expect(self.class::InheritParent.safe_const(:INHERITED_CONST, inherit: false)).to eq("from_parent")
      end

      it "指定 obj 搭配 inherit: false" do
        expect(instance.safe_const(:INHERITED_CONST, self.class::InheritChild, inherit: false)).to be_nil
        expect(instance.safe_const(:INHERITED_CONST, self.class::InheritChild, inherit: true)).to eq("from_parent")
      end
    end
  end

  # =============================================
  # safe_fetch - 常數 (全大寫 Symbol)
  # =============================================
  describe "#safe_fetch" do
    context "全大寫 Symbol → 常數查找" do
      it "回傳已定義的常數值" do
        expect(instance.safe_fetch(:MY_CONST)).to eq("const_value")
      end

      it "常數不存在時跳過，取下一個" do
        expect(instance.safe_fetch(:NOT_EXIST, :MY_CONST)).to eq("const_value")
      end

      it "常數值為 nil 時跳過" do
        expect(instance.safe_fetch(:NIL_CONST, "fallback")).to eq("fallback")
      end
    end

    # =============================================
    # safe_fetch - 實例變數 (:@xxx)
    # =============================================
    context ":@xxx → 實例變數" do
      it "回傳實例變數值" do
        expect(instance.safe_fetch(:@my_var)).to eq("var_value")
      end

      it "實例變數為 nil 時跳過" do
        expect(instance.safe_fetch(:@nil_var, "fallback")).to eq("fallback")
      end

      it "實例變數不存在時跳過" do
        expect(instance.safe_fetch(:@not_exist, "fallback")).to eq("fallback")
      end
    end

    # =============================================
    # safe_fetch - 方法呼叫 (:__xxx__)
    # =============================================
    context ":__xxx__ → 方法呼叫 (try)" do
      it "呼叫對應方法並回傳結果" do
        expect(instance.safe_fetch(:__my_method__)).to eq("method_result")
      end

      it "方法回傳 nil 時跳過" do
        expect(instance.safe_fetch(:__nil_method__, "fallback")).to eq("fallback")
      end

      it "方法不存在時不拋錯，跳過取下一個" do
        expect(instance.safe_fetch(:__not_exist_method__, "fallback")).to eq("fallback")
      end
    end

    # =============================================
    # safe_fetch - 全小寫 Symbol (不應觸發方法呼叫)
    # =============================================
    context "全小寫 Symbol（非 __xxx__ 格式）" do
      it "視為一般值直接回傳，不觸發方法呼叫" do
        # :my_method 是全小寫但不是 __xxx__ 格式
        # 應視為一般值直接回傳 Symbol 本身
        expect(instance.safe_fetch(:my_method)).to eq(:my_method)
      end
    end

    # =============================================
    # safe_fetch - 一般值 (String, Integer 等)
    # =============================================
    context "一般值直接回傳" do
      it "回傳字串" do
        expect(instance.safe_fetch("default_string")).to eq("default_string")
      end

      it "回傳數值" do
        expect(instance.safe_fetch(99)).to eq(99)
      end

      it "回傳 Hash" do
        expect(instance.safe_fetch({ a: 1 })).to eq({ a: 1 })
      end
    end

    # =============================================
    # safe_fetch - Fallback 優先順序
    # =============================================
    context "Fallback 優先順序" do
      it "回傳第一個非 nil 的值" do
        expect(instance.safe_fetch(:NOT_EXIST, :@not_exist, :MY_CONST)).to eq("const_value")
      end

      it "所有來源都是 nil 時回傳 nil（v1.2.0 修正 sentinel bug）" do
        expect(instance.safe_fetch(:NOT_EXIST, :@not_exist)).to be_nil
      end

      it "混合多種類型的 Fallback" do
        # 常數不存在 → 實例變數不存在 → 方法呼叫 → 取得結果
        expect(
          instance.safe_fetch(:NOT_EXIST, :@not_exist, :__my_method__, "last_resort"),
        ).to eq("method_result")
      end

      it "第一個找到值就停止" do
        expect(
          instance.safe_fetch(:@my_var, :MY_CONST, "default"),
        ).to eq("var_value")
      end
    end

    # =============================================
    # safe_fetch - 無參數
    # =============================================
    context "無參數" do
      it "回傳 nil（v1.2.0 修正 sentinel bug）" do
        expect(instance.safe_fetch).to be_nil
      end
    end
  end

  # =============================================
  # safe_fetch_local（v1.2.0+）
  # =============================================
  describe "#safe_fetch_local" do
    context "inherit: false（僅查當前類別）" do
      before(:all) do
        unless self.class.const_defined?(:LocalFetchParent)
          self.class.const_set(:LocalFetchParent, Class.new do
            include LibSafeConst
            const_set(:SHARED, "from_parent")
          end,)
        end
        unless self.class.const_defined?(:LocalFetchChild)
          self.class.const_set(:LocalFetchChild, Class.new(self.class::LocalFetchParent))
        end
      end

      it "子類別不繼承父類常數（走到後續 fallback）" do
        # 若繼承：拿到 "from_parent"；不繼承：走到 "fallback"
        result = self.class::LocalFetchChild.safe_fetch_local(:SHARED, "fallback")
        expect(result).to eq("fallback")
      end

      it "父類自身可取得（inherit: false 不影響 own class）" do
        expect(self.class::LocalFetchParent.safe_fetch_local(:SHARED)).to eq("from_parent")
      end

      it "全無值時回傳 nil" do
        expect(self.class::LocalFetchChild.safe_fetch_local(:SHARED)).to be_nil
      end
    end

    context "Proc / Lambda lazy 支援" do
      it "Proc 物件被自動 .call" do
        expect(instance.safe_fetch_local(-> { "lazy_value" })).to eq("lazy_value")
      end

      it "Lambda 也適用" do
        expect(instance.safe_fetch_local(lambda { "lambda_value" })).to eq("lambda_value")
      end

      it "前面命中時後面的 Proc 不被呼叫（驗證 lazy）" do
        counter = 0
        expensive = -> { counter += 1; "expensive" }
        result = instance.safe_fetch_local(:MY_CONST, expensive)
        expect(result).to eq("const_value")
        expect(counter).to eq(0)
      end

      it "前面 nil 時 Proc 才被呼叫" do
        counter = 0
        expensive = -> { counter += 1; "expensive" }
        result = instance.safe_fetch_local(:NOT_EXIST, expensive)
        expect(result).to eq("expensive")
        expect(counter).to eq(1)
      end

      it "Proc 回傳 nil 時跳過到下一個" do
        expect(instance.safe_fetch_local(-> { nil }, "fallback")).to eq("fallback")
      end
    end

    context "與 safe_fetch 的行為差異" do
      it "safe_fetch 視 Proc 為字面值（不展開）" do
        my_proc = -> { "lazy" }
        expect(instance.safe_fetch(my_proc)).to be(my_proc)
      end

      it "safe_fetch_local 展開 Proc" do
        expect(instance.safe_fetch_local(-> { "lazy" })).to eq("lazy")
      end
    end
  end

  # =============================================
  # Class Method（透過 extend）
  # =============================================
  describe "作為 class method 使用" do
    it "safe_const 可作為 class method 呼叫" do
      expect(self.class::TestSafeConst.safe_const(:MY_CONST)).to eq("const_value")
    end

    it "safe_fetch 可作為 class method 呼叫" do
      expect(self.class::TestSafeConst.safe_fetch(:MY_CONST)).to eq("const_value")
    end
  end
end
