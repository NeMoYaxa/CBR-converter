# frozen_string_literal: true

require "net/http"
require "uri"

module CbrConverter
  class CurrencyParser
    URL = "http://www.cbr.ru/scripts/XML_daily.asp"

    def fetch_rates
      response = Net::HTTP.get_response(URI.parse(URL))

      raise Error, "Сервер ЦБ не доступен: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
