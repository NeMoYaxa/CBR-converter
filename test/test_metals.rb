require_relative '../lib/cbr_converter/metal_parser'

parser = CbrConverter::MetalsParser.new
begin
  rates = parser.parse_rates
  if rates.any?
    puts "Успех! Цены за грамм:"
    rates.each { |metal, price| puts "#{metal.capitalize}: #{price.to_f} руб." }
    
    if rates[:gold] && rates[:silver]
      puts "Золото дороже серебра в #{parser.compare_metals(rates, :gold, :silver).to_f} раз"
    end
  else
    puts "Данные получены, но пустые. Возможно, ЦБ еще не обновил котировки."
  end
rescue => e
  puts "Ошибка: #{e.message}"
end