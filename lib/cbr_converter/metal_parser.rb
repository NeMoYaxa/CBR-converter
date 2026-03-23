# frozen_string_literal: true

require "net/http"
require "uri"
require "nokogiri"
require "bigdecimal"
require "date"

module CbrConverter
  class MetalsParser
    BASE_URL = "http://www.cbr.ru/scripts/xml_metall.asp"
    METALS = {
      "1" => :gold,
      "2" => :silver,
      "3" => :platinum,
      "4" => :palladium
    }.freeze

    def fetch_rates
      date = Date.today
      attempts = 0

      while attempts < 7
        formatted_date = (date - attempts).strftime("%d/%m/%Y")
        url = "#{BASE_URL}?date_req1=#{formatted_date}&date_req2=#{formatted_date}"

        response = Net::HTTP.get_response(URI.parse(url))

        return response.body if response.is_a?(Net::HTTPSuccess) && contains_data?(response.body)

        attempts += 1
      end
      raise Error, "Не удалось получить данные по металлам за последнюю неделю"
    end

    def parse_rates
      doc = Nokogiri::XML(fetch_rates)
      rates = {}

      doc.xpath("//Record").each do |record_node|
        metal_name, price = extract_metal_data(record_node)
        rates[metal_name] = price if metal_name
      end

      rates
    end

    private

    def contains_data?(xml_body)
      doc = Nokogiri::XML(xml_body)
      doc.xpath("//Record").any?
    end

    def extract_metal_data(node)
      code = node["Code"]
      buy_text = node.at_xpath("Buy")&.text
      return nil if code.nil? || buy_text.nil?

      metal_name = METALS[code]
      price = BigDecimal(buy_text.gsub(",", "."))

      [metal_name, price]
    end
  end
end
