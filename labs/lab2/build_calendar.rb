
teams = {}
date_str_1 = ARGV[1]

puts "Парсинг файла: "
File.foreach('teams.txt') do |line|
  # Убираем перевод строки и пробелы по краям
  line = line.chomp.strip

  next if line.empty?
  team_name, city = line.split(' — ')

  if team_name && city
    # Убираем номер
    team_name = team_name.sub(/^\d+\.\s*/, '')

    teams[team_name] = city
    puts "Добавлено: #{team_name} -> #{city}"
  else
    puts "Ошибка в строке: #{line}"
  end
end


pattern = /^\d{2}\.\d{2}\.\d{4}$/
if date_str_1.match?(pattern)
  day_str_1, month_str_1, year_str_1 = date_str_1.split('.')
  day_1 = day_str_1.to_i
  month_1 = month_str_1.to_i
  year_1 = year_str_1.to_i
else
  raise ArgumentError, "Неверный формат даты. Ожидается dd.mm.yyyy"
end

if day_1 < 1 || day_1 > 31
  raise ArgumentError, "Неверно введен день"
end

if month_1 < 1 || month_1 > 12
  raise ArgumentError, "Неверно введен месяц"
end

if year_1 < 0 || year_1 > 2026
  raise ArgumentError, "Неверно введен год"
end

