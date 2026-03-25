# frozen_string_literal: true

require "test_helper"
WebMock.allow_net_connect!

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

    refute_includes rates, "ERR"
  end

  def test_get_currency_rate_returns_truncated_value
    CbrConverter.stub :current_currency_rates, { "USD" => BigDecimal("78.9514") } do
      rate = CbrConverter.get_currency_rate("USD")

      assert_kind_of BigDecimal, rate
      assert_equal BigDecimal("78.9514"), rate
    end
  end

  def test_get_currency_rate_for_rub
    CbrConverter.stub :current_currency_rates, { "RUB" => BigDecimal("1.0") } do
      rate = CbrConverter.get_currency_rate("RUB")
      assert_equal BigDecimal("1.0"), rate
    end
  end

  def test_get_currency_rate_for_non_existent
    CbrConverter.stub :current_currency_rates, {} do
      assert_raises CbrConverter::Error do
        CbrConverter.get_currency_rate("ERR")
      end
    end
  end

  def test_compare_currencies_returns_truncated_ratio
    rates = { "USD" => BigDecimal("84.0"), "EUR" => BigDecimal("96.0") }

    CbrConverter.stub :current_currency_rates, rates do
      ratio = CbrConverter.compare_currencies("USD", "EUR")
      assert_equal BigDecimal("0.875"), ratio
    end
  end

  def test_available_currencies_returns_correct_hash
    rates = { "USD" => BigDecimal("84.0"), "EUR" => BigDecimal("96.0"), "RUB" => BigDecimal("1.0") }

    CbrConverter.stub :current_currency_rates, rates do
      keys = CbrConverter.available_currencies
      assert_equal ["EUR", "RUB", "USD"], keys
    end
  end

  def test_available_currencies_returns_empty_hash
    CbrConverter.stub :current_currency_rates, {} do
      keys = CbrConverter.available_currencies
      assert_equal [], keys
    end
  end

  def test_refresh_rates_instance_variable_set_to_nil
    CbrConverter.instance_variable_set(:@current_currency_rates, { "USD" => BigDecimal("86.1764") })
    CbrConverter.refresh_rates!
    assert_nil CbrConverter.instance_variable_get(:@current_currency_rates)
  end
end
