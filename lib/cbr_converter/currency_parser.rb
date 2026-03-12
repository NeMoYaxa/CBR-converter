# frozen_string_literal: true

require "net/http"
require "uri"
require "nokogiri"
require "bigdecimal"

module CbrConverter
  class CurrencyParser
    URL = "http://www.cbr.ru/scripts/XML_daily.asp"

    def fetch_rates
      response = Net::HTTP.get_response(URI.parse(URL))

      raise Error, "Сервер ЦБ не доступен: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def parse_rates
      doc = Nokogiri::XML(fetch_rates)
      rates = {}

      doc.xpath("//Valute").each do |valute_node|
        char_code, rate = extract_rate(valute_node)
        rates[char_code] = rate if char_code
      end

      rates
    end

    private

    def extract_rate(node)
      char_code = node.at_xpath("CharCode")&.text
      value_text = node.at_xpath("Value")&.text
      nominal_text = node.at_xpath("Nominal")&.text

      return nil if [char_code, value_text, nominal_text].any?(&:nil?)

      value = BigDecimal(value_text.gsub(",", "."))
      nominal = BigDecimal(nominal_text)

      return nil if nominal.zero?

      [char_code, value / nominal]
    end
  end
end
