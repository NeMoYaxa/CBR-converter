# frozen_string_literal: true

require_relative "lib/cbr_converter/version"

Gem::Specification.new do |spec|
  spec.name = "cbr_converter"
  spec.version = CbrConverter::VERSION
  spec.authors = ["Batuev Yakov Denisovich"]
  spec.email = ["batuev@sfedu.ru"]

  spec.summary = "Библиотека для конвертации валют и драгоценных металлов по курсам ЦБ РФ."
  spec.description = "Позволяет получать актуальные данные XML с сайта Центрального Банка РФ и выполнять конвертацию."
  spec.homepage = "https://github.com/NeMoYaxa/CBR-converter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "nokogiri", "~> 1.15"
end
