# frozen_string_literal: true

require "test_helper"

class TestCbrConverter < Minitest::Test
  def setup
    @parser = CbrConverter::CurrencyParser.new
    @url = CbrConverter::CurrencyParser::URL
  end

  def test_fetch_rates_raise_error_on_500
    stub_request(:get, @url).to_return(status: 500)

    assert_raises(CbrConverter::Error) do
      @parser.fetch_rates
    end
  end

  def test_fetch_rates_raise_error_on_400
    stub_request(:get, @url).to_return(status: 400)

    assert_raises(CbrConverter::Error) do
      @parser.fetch_rates
    end
  end

  def test_fetch_rates_returns_xml_200
    fake_xml = <<~XML
      <ValCurs Date="11.03.2026">
        <Valute>
          <CharCode>USD</CharCode>
          <Nominal>1</Nominal>
          <Value>91,4500</Value>
        </Valute>
      </ValCurs>
    XML

    stub_request(:get, @url).to_return(status: 200, body: fake_xml)

    assert_equal fake_xml, @parser.fetch_rates
  end

  def test_parse_rates_returns_correct_hash
    fake_xml = <<~XML
      <ValCurs Date="11.03.2026">
        <Valute>
          <CharCode>USD</CharCode>
          <Nominal>1</Nominal>
          <Value>91,4500</Value>
        </Valute>
        <Valute>
          <CharCode>KZT</CharCode>
          <Nominal>100</Nominal>
          <Value>20,1500</Value>
        </Valute>
      </ValCurs>
    XML

    stub_request(:get, @url).to_return(status: 200, body: fake_xml)

    rates = @parser.parse_rates

    expected_rates = {
      "USD" => BigDecimal("91.45"),
      "KZT" => BigDecimal("0.2015")
    }

    assert_equal expected_rates, rates
  end

  def test_parse_rates_returns_empty_hash
    fake_xml = <<~XML
      <ValCurs Date="11.03.2026">
      </ValCurs>
    XML

    stub_request(:get, @url).to_return(status: 200, body: fake_xml)

    assert_empty @parser.parse_rates
  end

  def test_parse_rates_zero_nominal
    fake_xml = <<~XML
      <ValCurs>
        <Valute>
          <CharCode>ERR</CharCode>
          <Nominal>0</Nominal>
          <Value>10,00</Value>
        </Valute>
      </ValCurs>
    XML

    stub_request(:get, @url).to_return(status: 200, body: fake_xml)

    rates = @parser.parse_rates

    assert rates["ERR"].infinite?
  end
end
