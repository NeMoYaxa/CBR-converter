# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class TestCbrConverterConsole < Minitest::Test
  def setup

    @console = CbrConverterConsole.new

    @original_stdout = $stdout
    @output = StringIO.new
    $stdout = @output

    # Мок-данные для тестов
    @mock_rates = {
      "USD" => BigDecimal("91.45"),
      "EUR" => BigDecimal("98.76"),
      "GBP" => BigDecimal("115.30"),
      "RUB" => BigDecimal("1.0")
    }
  end

  def teardown
    $stdout = @original_stdout
  end

  def output
    @output.string
  end

  def clear_output
    @output.string = ""
  end


  def test_initialize_sets_running_true
    assert @console.instance_variable_get(:@running)
  end

  def test_initialize_has_all_commands
    commands = @console.instance_variable_get(:@commands)

    assert_includes commands.keys, "1"
    assert_includes commands.keys, "2"
    assert_includes commands.keys, "3"
    assert_includes commands.keys, "4"
    assert_includes commands.keys, "5"
    assert_includes commands.keys, "6"
    assert_includes commands.keys, "7"
    assert_includes commands.keys, "8"
  end

  def test_show_help_displays_help_message
    @console.send(:show_help)

    assert_includes output, "Доступные команды:"
    assert_includes output, "rates"
    assert_includes output, "convert"
  end

  def test_show_rates_displays_all_currencies
    CbrConverter.stub :current_currency_rates, @mock_rates do
      @console.send(:show_rates)

      assert_includes output, "USD  : 91.45 руб."
      assert_includes output, "EUR  : 98.76 руб."
      assert_includes output, "RUB   : 1.00 руб."
    end
  end

  def test_show_rate_without_currency_shows_usage
    @console.send(:show_rate, nil)

    assert_includes output, "Использование: rate <код валюты>"
  end

  def test_show_rate_with_valid_currency
    CbrConverter.stub :get_currency_rate, BigDecimal("91.45") do
      @console.send(:show_rate, "USD")

      assert_includes output, "Курс USD:"
      assert_includes output, "1 USD = 91.45 руб."
    end
  end

  def test_show_rate_with_invalid_currency
    CbrConverter.stub :get_currency_rate, ->(currency) { raise CbrConverter::Error } do
      @console.send(:show_rate, "XXX")

      assert_includes output, "Валюта 'XXX' не найдена"
    end
  end

  def test_compare_currencies_valid
    CbrConverter.stub :compare_currencies, BigDecimal("0.93") do
      @console.send(:compare_currencies, "USD", "EUR")

      assert_includes output, "Сравнение USD и EUR:"
      assert_includes output, "1 USD = 0.93 EUR"
    end
  end

  def test_show_currencies
    CbrConverter.stub :available_currencies, ["USD", "EUR", "GBP"] do
      @console.send(:show_currencies)

      assert_includes output, "Доступные валюты (3):"
      assert_includes output, "USD  EUR  GBP"
    end
  end

  def test_convert_currency_valid
    CbrConverter.stub :get_currency_rate, ->(currency) {
      case currency
      when "USD" then BigDecimal("91.45")
      when "RUB" then BigDecimal("1.0")
      end
    } do
      @console.send(:convert_currency, "100", "USD", "RUB")

      assert_includes output, "Результат конвертации:"
      assert_includes output, "USD ="
      assert_includes output, "RUB"
    end
  end

  def test_convert_currency_with_invalid_amount
    @console.send(:convert_currency, "abc", "USD", "RUB")

    assert_includes output, "Ошибка: сумма должна быть числом"
  end

  def test_refresh_rates
    CbrConverter.stub :refresh_rates!, nil do
      @console.send(:refresh_rates)

      assert_includes output, "Обновление курсов валют..."
      assert_includes output, "Курсы успешно обновлены!"
    end
  end

  def test_exit_console
    @console.send(:exit_console)

    assert_includes output, "До свидания!"
    refute @console.instance_variable_get(:@running)
  end

  def test_parse_and_execute_unknown_command
    @console.send(:parse_and_execute, "unknown")

    assert_includes output, "Неизвестная команда: unknown"
  end

  def test_parse_and_execute_help
    @console.send(:parse_and_execute, "7")

    assert_includes output, "Доступные команды:"
  end

  def test_parse_and_execute_rates
    CbrConverter.stub :current_currency_rates, @mock_rates do
      @console.send(:parse_and_execute, "1")

      assert_includes output, "USD  : 91.45 руб."
    end
  end

  def test_format_rate_with_thousands
    rate = BigDecimal("1234.56")
    formatted = @console.send(:format_rate, rate)

    assert_equal "1234.56", formatted
  end

  def test_format_number_with_bigdecimal
    number = BigDecimal("1234.567")
    formatted = @console.send(:format_number, number)

    assert_equal "1234.567", formatted
  end
end
