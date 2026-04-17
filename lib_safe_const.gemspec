# frozen_string_literal: true

require_relative "lib/lib_safe_const/version"

Gem::Specification.new do |spec|
  spec.name = "lib_safe_const"
  spec.version = LibSafeConst::VERSION
  spec.authors = ["Ohm Kao"]
  spec.email = ["ohm.kao@gmail.com"]

  spec.summary = "安全地存取物件內部常數、實例變數與方法的輕量 Ruby 模組"
  spec.description = <<~DESC
    LibSafeConst 提供 safe_const 與 safe_fetch 兩個方法，
    允許在不事先確認常數/實例變數/方法是否存在的情況下安全地取值，
    支援多來源 fallback 語法。純 Ruby 實作、無任何外部依賴。
  DESC
  spec.homepage = "https://github.com/ohmkao/lib_safe_const"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.13"
end
