# frozen_string_literal: true

require "test_helper"

class TestMetalsConverter < Minitest::Test
  def setup
    @parser = CbrConverter::MetalsParser.new
    # Базовый URL без параметров для стаббинга
    @base_url = /#{Regexp.escape(CbrConverter::MetalsParser::BASE_URL)}/
  end

  def test_fetch_rates_returns_xml_on_success
    fake_xml = <<~XML
      <Metall>
        <Record Date="23.03.2026" Code="1"><Buy>7000,50</Buy><Sell>7500,00</Sell></Record>
      </Metall>
    XML

    stub_request(:get, @base_url).to_return(status: 200, body: fake_xml)
    assert_equal fake_xml, @parser.fetch_rates
  end

  def test_parse_rates_returns_correct_hash
    fake_xml = <<~XML
      <Metall>
        <Record Code="1"><Buy>7000,50</Buy></Record>
        <Record Code="2"><Buy>80,25</Buy></Record>
      </Metall>
    XML

    stub_request(:get, @base_url).to_return(status: 200, body: fake_xml)
    
    rates = @parser.parse_rates
    assert_equal BigDecimal("7000.50"), rates[:gold]
    assert_equal BigDecimal("80.25"), rates[:silver]
  end

  def test_get_metal_rate_returns_truncated_value
    CbrConverter.stub :current_metal_rates, { gold: BigDecimal("7123.4567") } do
      rate = CbrConverter.get_metal_rate(:gold)
      assert_equal BigDecimal("7123.4567"), rate
    end
  end

  def test_compare_metals_ratio
    rates = { gold: BigDecimal("7000.0"), silver: BigDecimal("70.0") }
    CbrConverter.stub :current_metal_rates, rates do
      ratio = CbrConverter.compare_metals(:gold, :silver)
      assert_equal BigDecimal("100.0"), ratio
    end
  end

  def test_refresh_metals_clears_cache
    CbrConverter.instance_variable_set(:@current_metal_rates, { gold: 500 })
    CbrConverter.refresh_metals!
    assert_nil CbrConverter.instance_variable_get(:@current_metal_rates)
  end
end