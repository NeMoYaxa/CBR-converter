# frozen_string_literal: true

require_relative "cbr_converter/version"
require_relative "cbr_converter/currency_parser"
require_relative "cbr_converter/metal_parser" # Не забудь добавить require

module CbrConverter
  class Error < StandardError; end

  def self.current_metal_rates
    @current_metal_rates ||= MetalsParser.new.parse_rates
  end

  def self.get_metal_rate(metal)
    rates = current_metal_rates
    metal_sym = metal.to_sym

    raise Error, "Металл (#{metal}) не найден в данных ЦБ" unless rates[metal_sym]

    rates[metal_sym].truncate(2)
  end

  def self.compare_metals(first_metal, second_metal)
    first_rate = get_metal_rate(first_metal)
    second_rate = get_metal_rate(second_metal)

    (first_rate / second_rate).truncate(2)
  end

  def self.available_metals
    current_metal_rates.keys.sort
  end

  def self.refresh_metals!
    @current_metal_rates = nil
  end
end
