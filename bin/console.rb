#!/usr/bin/env ruby
# frozen_string_literal: true


require "cbr_converter"
class CbrConverterConsole
  def initialize
    @running = true
    @commands = {
      "help" => -> { show_help },
      "rates" => -> { show_rates },
      "rate" => ->(currency = nil) { show_rate(currency) },
      "compare" => ->(first = nil, second = nil) { compare_currencies(first, second) },
      "currencies" => -> { show_currencies },
      "refresh" => -> { refresh_rates },
      "convert" => ->(amount = nil, from = nil, to = nil) { convert_currency(amount, from, to) },
      "exit" => -> { exit_console },
      "quit" => -> { exit_console }
    }
  end

  def start
    puts "CBR Converter - Консольное приложение"
    puts "Курсы валют ЦБ РФ"
    show_help
    run
  end

  private

  def run
    while @running
      print "\n> "
      input = gets.chomp.strip
      parse_and_execute(input)
    end
  end

  def parse_and_execute(input)
    return if input.empty?

    parts = input.split
    command = parts[0].downcase
    args = parts[1..-1]

    if @commands.key?(command)
      @commands[command].call(*args)
    else
      puts "Неизвестная команда: #{command}"
      puts "Введите 'help' для списка доступных команд"
    end
  rescue CbrConverter::Error => e
    puts "Ошибка: #{e.message}"
  rescue StandardError => e
    puts "Произошла ошибка: #{e.message}"
  end

  def show_help
    puts "\nДоступные команды:"
    puts "  rates                    - Показать все курсы валют"
    puts "  rate <код валюты>        - Показать курс конкретной валюты"
    puts "  compare <валюта1> <валюта2> - Сравнить две валюты"
    puts "  currencies               - Показать список доступных валют"
    puts "  convert <сумма> <из> <в> - Конвертировать сумму из одной валюты в другую"
    puts "  refresh                  - Обновить курсы валют"
    puts "  help                     - Показать эту справку"
    puts "  exit / quit              - Выйти из программы"
    puts "\nПримеры:"
    puts "  rate USD"
    puts "  compare USD EUR"
    puts "  convert 100 USD RUB"
    puts "  convert 50.5 EUR USD"
  end

  def show_rates
    puts "\nТекущие курсы валют (1 единица валюты в рублях):"
    puts "-" * 50

    rates = CbrConverter.current_currency_rates
    rates = rates.sort_by { |currency, _| currency }

    rates.each do |currency, rate|
      next if currency == "RUB"

      puts "  #{currency.ljust(5)}: #{format_rate(rate)} руб."
    end

    puts "\n  RUB   : 1.00 руб."
    puts "-" * 50
    puts "Всего валют: #{rates.size - 1}"
    puts "Данные от: #{Time.now.strftime('%d.%m.%Y %H:%M')}"
  end

  def show_rate(currency)
    if currency.nil?
      puts "Использование: rate <код валюты>"
      puts "Пример: rate USD"
      return
    end

    currency = currency.upcase
    rate = CbrConverter.get_currency_rate(currency)

    puts "\nКурс #{currency}:"
    puts "  1 #{currency} = #{format_rate(rate)} руб."
  rescue CbrConverter::Error
    puts "Валюта '#{currency}' не найдена. Используйте 'currencies' для просмотра доступных валют."
  end

  def compare_currencies(first, second)
    if first.nil? || second.nil?
      puts "Использование: compare <валюта1> <валюта2>"
      puts "Пример: compare USD EUR"
      return
    end

    first = first.upcase
    second = second.upcase

    ratio = CbrConverter.compare_currencies(first, second)

    puts "\nСравнение #{first} и #{second}:"
    puts "  1 #{first} = #{format_rate(ratio)} #{second}"
    puts "  #{format_rate(1.0 / ratio)} #{first} = 1 #{second}"
  rescue CbrConverter::Error => e
    puts "Ошибка: #{e.message}"
  end

  def show_currencies
    currencies = CbrConverter.available_currencies
    currencies.delete("RUB")

    puts "\nДоступные валюты (#{currencies.size}):"
    puts "-" * 50

    currencies.each_slice(10) do |slice|
      puts "  #{slice.join('  ')}"
    end
  end

  def refresh_rates
    puts "Обновление курсов валют..."
    CbrConverter.refresh_rates!
    puts "Курсы успешно обновлены!"
  end

  def convert_currency(amount, from, to)
    if amount.nil? || from.nil? || to.nil?
      puts "Использование: convert <сумма> <из валюты> <в валюту>"
      puts "Пример: convert 100 USD RUB"
      puts "Пример: convert 50.5 EUR USD"
      return
    end

    begin
      amount = Float(amount)
    rescue ArgumentError
      puts "Ошибка: сумма должна быть числом"
      return
    end

    from = from.upcase
    to = to.upcase

    from_rate = CbrConverter.get_currency_rate(from)
    to_rate = CbrConverter.get_currency_rate(to)

    result_in_rub = amount * from_rate
    result = result_in_rub / to_rate

    puts "\nРезультат конвертации:"
    puts "  #{format_number(amount)} #{from} = #{format_number(result)} #{to}"
    puts "  Курс: 1 #{from} = #{format_rate(from_rate)} руб."
    puts "  Курс: 1 #{to} = #{format_rate(to_rate)} руб."
  rescue CbrConverter::Error => e
    puts "Ошибка: #{e.message}"
  end

  def exit_console
    puts "\nДо свидания!"
    @running = false
  end

  def format_rate(rate)
    rate.to_s("F").gsub(/\B(?=(\d{3})+(?!\d))/, ",")
  end

  def format_number(number)
    if number.is_a?(BigDecimal)
      number = number.to_f
    end
    sprintf("%.2f", number).gsub(/\B(?=(\d{3})+(?!\d))/, ",")
  end
end

# Запуск приложения
if __FILE__ == $PROGRAM_NAME
  console = CbrConverterConsole.new
  console.start
end