# frozen_string_literal: true

require_relative "lib_safe_const/version"

# ===-===-===-------------------------------------===-===-===
# ===-=== Summary & Description ===-===
# Name:
#   LibSafeConst
# Description:
#   <safe_const>
#     - 使用物件內部的常數或方法, 無需先行確認是否存在，只能用  Symbol + 『全大寫』
#   <safe_fetch>
#     - 依序取得 args 內容，如果是 nil 就跳過
#     - 如果是 Symbol +『全大寫』就檢查是否有定義『常數（constant）』
#     - 如果是 Symbol +『__xxx__』雙底線前後綴就呼叫方法 (try)
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
    # 依據 args 順序挑選 arg 不是 nil 就輸出
    def safe_fetch(*args)
      args.push(NilClass).each do |arg|
        out_ =
          if arg.is_a?(Symbol) && arg.to_s =~ /^@.*/
            instance_variable_get(arg.to_s)
          # 如果是 Symbol +『全大寫』就檢查是否有定義常數
          elsif arg.is_a?(Symbol) && arg.to_s.upcase == arg.to_s
            safe_const(arg)
          # 如果是 Symbol + __xxx__ 格式就嘗試呼叫方法
          elsif arg.is_a?(Symbol) && arg.to_s.match?(/\A__[a-z_]+__\z/)
            method_name = arg.to_s.gsub(/\A__|__\z/, "").to_sym
            respond_to?(method_name) ? send(method_name) : nil
          else
            arg
          end
        break out_ unless out_.nil?
        break nil if arg.is_a?(NilClass)
      end
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
    def safe_const(const_name, obj = self)
      const_name_ = const_name.to_s.upcase
      self_klass = %w[Class Module].include?(obj.class.name) ? obj : obj.class
      self_klass.const_get(const_name_) if self_klass.const_defined?(const_name_)
    end
  end
end
