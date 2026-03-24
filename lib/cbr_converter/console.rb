# frozen_string_literal: true

module CbrConverter
  class CLI
    def initialize
      @running = true
      @commands = {
        "1" => -> { show_currency_rates },
        "2" => ->(currency = nil) { show_currency_rate(currency) },
        "3" => ->(first = nil, second = nil) { compare_currencies(first, second) },
        "4" => -> { show_currencies },
        "5" => ->(amount = nil, from = nil, to = nil) { convert_currency(amount, from, to) },
        "6" => -> { refresh_currency_rates },
        "7" => -> { show_metals_rates },
        "8" => ->(metal = nil) { show_metal_rate(metal) },
        "9" => ->(first = nil, second = nil) { compare_metals(first, second) },
        "10" => -> { show_metals },
        "11" => ->(amount = nil, from = nil, to = nil) { convert_metals(amount, from, to) },
        "12" => -> { refresh_metals_rates },
        "13" => -> { show_help },
        "14" => -> { exit_console }
      }
    end

    def self.start
      new.start
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
      args = parts[1..]

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
      puts "Команды для валют:"
      puts "  1.                      - Показать все курсы валют"
      puts "  2. <код валюты>         - Показать курс конкретной валюты"
      puts "  3. <валюта1> <валюта2>  - Сравнить две валюты"
      puts "  4.                      - Показать список доступных валют"
      puts "  5. <сумма> <из> <в>     - Конвертировать сумму из одной валюты в другую"
      puts "  6.                      - Обновить курсы валют"
      puts "Команды для металлов:"
      puts "  7.                      - Показать все курсы металлов"
      puts "  8. <код металла>        - Показать конкретный металл"
      puts "  9. <металл1> <металл2>  - Сравнить два металла"
      puts "  10.                     - Показать список доступных металлов"
      puts "  11. <вес> <из> <в>      - Конвертировать вес из одного металла другой"
      puts "  12.                     - Обновить курсы металлов"
      puts "Дополнительные команды:"
      puts "  13.                     - Показать справку"
      puts "  14.                     - Выйти из программы"
      puts "\nПримеры:"
      puts "  2 USD"
      puts "  3 USD EUR"
      puts "  5 100 USD RUB"
      puts "  5 50.5 EUR USD"
      puts "  11 1.1 gold silver"
      puts "  8 gold"
    end

    def show_currency_rates
      puts "\nТекущие курсы валют (1 единица валюты в рублях):"
      puts "-" * 50

      rates = CbrConverter.current_currency_rates
      rates = rates.sort_by { |currency, _| currency }.to_h

      rates.each_key do |currency|
        next if currency == "RUB"

        value = CbrConverter.get_currency_rate(currency)
        puts "  #{currency.ljust(5)}: #{format_rate(value)} руб."
      end

      puts "\n  RUB  : 1.00 руб."
      puts "-" * 50
      puts "Всего валют: #{rates.size - 1}"
      puts "Данные от: #{Time.now.strftime("%d.%m.%Y %H:%M")}"
    end

    def show_currency_rate(currency)
      if currency.nil?
        puts "Использование: 2 <код валюты>"
        puts "Пример: 2 USD"
        return
      end

      currency = currency.upcase
      rate = CbrConverter.get_currency_rate(currency)

      puts "\nКурс #{currency}:"
      puts "  1 #{currency} = #{format_rate(rate)} руб."
    rescue CbrConverter::Error
      puts "Валюта '#{currency}' не найдена. Используйте 4 для просмотра доступных валют."
    end

    def compare_currencies(first, second)
      if first.nil? || second.nil?
        puts "Использование: 3 <валюта1> <валюта2>"
        puts "Пример: 3 USD EUR"
        return
      end

      first = first.upcase
      second = second.upcase

      ratio = CbrConverter.compare_currencies(first, second)

      puts "\nСравнение #{first} и #{second}:"
      puts "  1 #{first} = #{format_rate(ratio)} #{second}"

      reverse_ratio = 1.0 / ratio
      puts "  #{format("%.4f", reverse_ratio).gsub(/\.?0+$/, "")} #{first} = 1 #{second}"
    rescue CbrConverter::Error => e
      puts "Ошибка: #{e.message}"
    end

    def show_currencies
      currencies = CbrConverter.available_currencies
      currencies.delete("RUB")

      puts "\nДоступные валюты (#{currencies.size}):"
      puts "-" * 50

      currencies.each_slice(10) do |slice|
        puts "  #{slice.join("  ")}"
      end
    end

    def convert_currency(amount, from, to)
      if amount.nil? || from.nil? || to.nil?
        puts "Использование: 5 <сумма> <из валюты> <в валюту>"
        puts "Пример: 5 100 USD RUB"
        puts "Пример: 5 50.5 EUR USD"
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
      result = BigDecimal(result_in_rub / to_rate).to_s

      puts "\nРезультат конвертации:"
      puts "  #{format_number(amount)} #{from} = #{format_number(result)} #{to}"
      puts "  Курс: 1 #{from} = #{format_rate(from_rate)} руб."
      puts "  Курс: 1 #{to} = #{format_rate(to_rate)} руб."
    rescue CbrConverter::Error => e
      puts "Ошибка: #{e.message}"
    end

    def refresh_currency_rates
      puts "Обновление курсов валют..."
      CbrConverter.refresh_rates!
      puts "Курсы успешно обновлены!"
    end

    def show_metals_rates
      puts "\nТекущие курсы металлов (1 единица валюты в рублях):"
      puts "-" * 50

      rates = CbrConverter.current_metal_rates
      rates = rates.sort_by { |metal, _| metal }.to_h

      rates.each_key do |metal|
        value = CbrConverter.get_metal_rate(metal)
        puts "  #{metal.to_s.ljust(11)}: #{format_rate(value)} руб."
      end

      puts "-" * 50
      puts "Всего металлов: #{rates.size - 1}"
      puts "Данные от: #{Time.now.strftime("%d.%m.%Y %H:%M")}"
    end

    def show_metal_rate(metal)
      if metal.nil?
        puts "Использование: 8 <код металла>"
        puts "Пример: 8 gold"
        return
      end

      metal = metal.downcase
      rate = CbrConverter.get_metal_rate(metal)

      puts "\nКурс #{metal}:"
      puts "  1г. #{metal} = #{format_rate(rate)} руб."
    rescue CbrConverter::Error
      puts "Металл '#{metal}' не найден. Используйте 10 для просмотра доступных металлов."
    end

    def compare_metals(first, second)
      if first.nil? || second.nil?
        puts "Использование: 9 <металл1> <металл2>"
        puts "Пример: 9 gold silver"
        return
      end

      first = first.downcase
      second = second.downcase

      ratio = CbrConverter.compare_metals(first, second)

      puts "\nСравнение #{first} и #{second}:"
      puts "  1г. #{first} = #{format_rate(ratio)} #{second}"

      reverse_ratio = 1.0 / ratio
      puts "  #{format("%.4f", reverse_ratio).gsub(/\.?0+$/, "")} #{first} = 1г. #{second}"
    rescue CbrConverter::Error => e
      puts "Ошибка: #{e.message}"
    end

    def show_metals
      metals = CbrConverter.available_metals
      puts "\nДоступные металлы (#{metals.size}):"
      puts "-" * 50

      metals.each_slice(5) do |slice|
        puts "  #{slice.join("  ")}"
      end
    end

    def convert_metals(amount, from, to)
      if amount.nil? || from.nil? || to.nil?
        puts "Использование: 1 <вес> <из металла> <в металл>"
        puts "Пример: 11 10 gold silver"
        puts "Пример: 11 27.5 silver gold"
        return
      end

      begin
        amount = Float(amount)
      rescue ArgumentError
        puts "Ошибка: вес должна быть числом"
        return
      end

      from = from.downcase
      to = to.downcase

      from_rate = CbrConverter.get_metal_rate(from)
      to_rate = CbrConverter.get_metal_rate(to)

      result_in_rub = amount * from_rate
      result = BigDecimal(result_in_rub / to_rate).to_s

      puts "\nРезультат конвертации:"
      puts "  #{format_number(amount)}г. #{from} = #{format_number(result)}г. #{to}"
      puts "  Курс: 1г. #{from} = #{format_rate(from_rate)} руб."
      puts "  Курс: 1г. #{to} = #{format_rate(to_rate)} руб."
    rescue CbrConverter::Error => e
      puts "Ошибка: #{e.message}"
    end

    def refresh_metals_rates
      puts "Обновление курсов металлов..."
      CbrConverter.refresh_rates!
      puts "Металлы успешно обновлены!"
    end

    def exit_console
      puts "\nДо свидания!"
      @running = false
    end

    def format_rate(rate)
      rate.to_s("F")
    end

    def format_number(number)
      if number.is_a?(BigDecimal)
        formatted = number.to_s("F")
      else
        formatted = format("%.4f", number)
        formatted.gsub!(/\.?0+$/, "")
      end
      formatted
    end
  end

  # Запуск приложения
  if __FILE__ == $PROGRAM_NAME
    console = CbrConverterConsole.new
    console.start
  end
end
