# frozen_string_literal: true

require "test_helper"

class TestCbrConverter < Minitest::Test
  ORIGINAL_GET_RESPONSE = Net::HTTP.method(:get_response)

  def setup
    @parser = CbrConverter::CurrencyParser.new
  end

  def test_raise_error_on_500
    mock_http_response(Net::HTTPInternalServerError.new("1.1", "500", "Internal Error")) do
      assert_raises(CbrConverter::Error) do
        @parser.fetch_rates
      end
    end
  end

  def test_raise_error_on_400
    mock_http_response(Net::HTTPBadRequest.new("1.1", "400", "Bad Request")) do
      assert_raises(CbrConverter::Error) do
        @parser.fetch_rates
      end
    end
  end

  def test_returns_xml_200
    fake_xml = "<ValCurs><Valute><Value>75,12</Value></Valute></ValCurs>"
    response = Net::HTTPOK.new("1.1", "200", "OK")

    response.instance_variable_set("@body", fake_xml)
    response.instance_variable_set("@read", true)

    mock_http_response(response) do
      assert_equal fake_xml, @parser.fetch_rates
    end
  end

  private

  def mock_http_response(mock_response)
    Net::HTTP.define_singleton_method(:get_response) { |_uri| mock_response }
    yield
  ensure
    Net::HTTP.define_singleton_method(:get_response, &ORIGINAL_GET_RESPONSE)
  end
end
