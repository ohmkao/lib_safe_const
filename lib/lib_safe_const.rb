# frozen_string_literal: true

require_relative "lib_safe_const/version"

# ===-===-===-------------------------------------===-===-===
# ===-=== Summary & Description ===-===
# Name:
#   LibSafeConst
# Description:
#   <safe_const>
#     - 使用物件內部的常數或方法, 無需先行確認是否存在，只能用  Symbol + 『全大寫』
#     - 支援 inherit: 關鍵字參數（預設 true）；inherit: false 僅查當前類別不走祖先鏈
#   <safe_fetch>
#     - 依序取得 args 內容，如果是 nil 就跳過
#     - 如果是 Symbol +『全大寫』就檢查是否有定義『常數（constant）』
#     - 如果是 Symbol +『__xxx__』雙底線前後綴就呼叫方法 (try)
#   <safe_fetch_local> (v1.2.0+)
#     - safe_fetch 的精確版：常數查找使用 inherit: false（僅當前類別，不走祖先鏈）
#     - 支援 Proc / Lambda fallback（自動 .call，實現 lazy evaluation）
#     - 適用於「內部程式邏輯 + 需精確常數來源 + 有昂貴 fallback」的場景
#     - safe_fetch 本身行為不變（inherit: true、Proc 視為字面值）
#
# ===-=== Setup & Use ===-===
# Setup:
#   include LibSafeConst
# Use:
#   AAA = 1
#   def bbb
#    'BoBo'
#   end
#   @CCC = { a: 1, b: 2 }
#
#   safe_fetch(:AAA, :__bbb__, :@CCC, 'DDD', :ef_value)
#
# ===-===-===-------------------------------------===-===-===
module LibSafeConst
  def self.included(base)
    base.extend(SafeConstMethods)
    base.include(SafeConstMethods)
  end

  module SafeConstMethods
    # 依據 args 順序挑選，回傳第一個非 nil 的值
    # 預設 inherit: true（常數走祖先鏈）、Proc 視為字面值（不 .call）
    def safe_fetch(*args)
      _do_safe_fetch(args, inherit: true, lazy: false)
    end

    # safe_fetch 的精確版（v1.2.0+）
    # - 常數查找使用 inherit: false（僅當前類別）
    # - 遇 Proc / Lambda 自動 .call（避免 eager evaluation 副作用）
    # 使用情境：內部程式邏輯需精確常數來源 + 具昂貴 fallback 的場景
    def safe_fetch_local(*args)
      _do_safe_fetch(args, inherit: false, lazy: true)
    end

    # 安全式取得 CONST，不會因為沒定義而噴掉
    # Example:
    #   -->
    #     const_name: :XXXX_YYYY
    #     ==>
    #       檢查常數 XXXX_YYYY 是否被定義
    #   <--
    #      XXXX_YYYY  #// 如果有定義
    #      nil        #// 如果沒定義
    #
    # inherit 參數（v1.1.0+）：
    #   - inherit: true  （預設）沿祖先鏈查找，與 Ruby 原生 const_defined?/const_get 預設行為一致
    #   - inherit: false 僅查當前類別自身定義，適用於「不想誤收繼承常數」的場景
    def safe_const(const_name, obj = self, inherit: true)
      const_name_ = const_name.to_s.upcase
      self_klass = %w[Class Module].include?(obj.class.name) ? obj : obj.class
      self_klass.const_get(const_name_, inherit) if self_klass.const_defined?(const_name_, inherit)
    end

    private

    # safe_fetch / safe_fetch_local 共用底層：
    # 按順序解析 args，遇到第一個非 nil 的解析結果即回傳；全無值時回傳 nil
    # @param args [Array]
    # @param inherit [Boolean] 常數查找是否沿祖先鏈
    # @param lazy [Boolean] Proc/Lambda 是否自動 .call（true = 視為 lazy fallback）
    # @note v1.2.0 移除 NilClass sentinel pattern，修正 all-nil 時錯回 NilClass class 物件（truthy）的 bug
    def _do_safe_fetch(args, inherit:, lazy:)
      args.each do |arg|
        out_ =
          if arg.is_a?(Symbol) && arg.to_s =~ /^@.*/
            instance_variable_get(arg.to_s)
          # 如果是 Symbol +『全大寫』就檢查是否有定義常數
          elsif arg.is_a?(Symbol) && arg.to_s.upcase == arg.to_s
            safe_const(arg, inherit: inherit)
          # 如果是 Symbol + __xxx__ 格式就嘗試呼叫方法
          elsif arg.is_a?(Symbol) && arg.to_s.match?(/\A__[a-z_]+__\z/)
            method_name = arg.to_s.gsub(/\A__|__\z/, "").to_sym
            respond_to?(method_name) ? send(method_name) : nil
          # lazy mode: Proc / Lambda 自動 .call（Proc 的 is_a? 涵蓋 Lambda）
          elsif lazy && arg.is_a?(Proc)
            arg.call
          else
            arg
          end
        return out_ unless out_.nil?
      end
      nil
    end
  end
end
