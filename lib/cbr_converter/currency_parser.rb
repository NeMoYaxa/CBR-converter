# frozen_string_literal: true

require "net/http"
require "uri"
require 'nokogiri'
require 'bigdecimal'

module CbrConverter
  class CurrencyParser
    URL = "http://www.cbr.ru/scripts/XML_daily.asp"

    def fetch_rates
      response = Net::HTTP.get_response(URI.parse(URL))

      raise Error, "Сервер ЦБ не доступен: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def parse_rates
      xml_data = fetch_rates
      doc = Nokogiri::XML(xml_data)
      rates = {}

      doc.xpath("//Valute").each do |valute|
        char_code = valute.at_xpath("CharCode").text

        value = BigDecimal(valute.at_xpath("Value").text.gsub(",", "."))
        nominal = BigDecimal(valute.at_xpath("Nominal").text)

        rates[char_code] = value / nominal
      end

      rates
    end
  end
end
