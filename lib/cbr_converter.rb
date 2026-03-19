# frozen_string_literal: true


require_relative "cbr_converter/version"
require_relative "cbr_converter/currency_parser"

module CbrConverter
  class Error < StandardError; end

  def self.current_currency_rates
    @current_currency_rates ||= begin
      parser = CurrencyParser.new.parse_rates
      parser["RUB"] = BigDecimal("1.0")
      parser
    end
  end

  def self.get_currency_rate(currency)
    rates = current_currency_rates

    raise Error, "Валюта (#{currency}) не найдена в данных ЦБ" unless rates[currency]

    rates[currency].truncate(2)
  end

  def self.compare_currencies(first_currency, second_currency)
    first_rate = get_currency_rate(first_currency)
    second_rate = get_currency_rate(second_currency)

    (first_rate / second_rate).truncate(2)
  end

  def self.available_currencies
    current_currency_rates.keys.sort
  end

  def self.refresh_rates!
    @current_currency_rates = nil
  end
end
