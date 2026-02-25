require 'date'
input_file = ARGV[0]
date_str_1 = ARGV[1]
date_str_2 = ARGV[2]
output_file = ARGV[3]

teams = {}
if File.exist?(input_file)
  File.foreach(input_file) do |line|
    line = line.chomp.strip

    next if line.empty?
    team_name, city = line.split(' — ')

    if team_name && city
      team_name = team_name.sub(/^\d+\.\s*/, '')

      teams[team_name] = city
    else
      puts "Ошибка в строке: #{line}"
    end
  end
else
  raise ArgumentError, "Файл не найден!"
end

pattern = /^\d{2}\.\d{2}\.\d{4}$/
if date_str_1.match?(pattern) and date_str_2.match?(pattern)
  date_1 = Date.strptime(date_str_1, "%d.%m.%Y")
  date_2 = Date.strptime(date_str_2, "%d.%m.%Y")
else
  raise ArgumentError, "Неверный формат даты. Ожидается dd.mm.yyyy"
end

if date_1 > date_2
  puts "Даты были расположены в хронологическом порядке"
  date_1, date_2 = date_2, date_1
end

all_matches = []
team_names = teams.keys

team_names.each do |home_team|
  team_names.each do |away_team|
    if home_team != away_team
      match = {
        home: home_team,
        away: away_team,
        city: teams[home_team]
      }
      all_matches << match
    end
  end
end

#перемешивание команд
n = all_matches.length
(n - 1).downto(1) do |i|
  j = rand(i + 1)
  all_matches[i], all_matches[j] = all_matches[j], all_matches[i]
end

game_days = []
current = date_1
while current <= date_2
  if current.friday? || current.saturday? || current.sunday?
    game_days << current
  end
  current += 1
end

if game_days.empty?
  puts "В этот период нет выходных дней!"
  exit
end

cnt_all_matches = all_matches.length
if cnt_all_matches < 2
  raise "Кол-во команд должно быть не меньше двух!"
end
cnt_game_days = game_days.length

if cnt_game_days == 0
  puts "В данном периоде нет игровых дней!"
  exit
end

if cnt_all_matches > cnt_game_days * 6
  puts "Слишком много игр для данного диапазона!"
  exit
end

def cnt_games_for_day(total_games, total_days)
  cnt_base = total_games / total_days
  cnt_extra = total_games % total_days

  counts = []

  k = 0
  while k < total_days
    counts << cnt_base
    k += 1
  end

  # Равномерно добавляем "лишние" игры
  acc = 0
  cur_d = 0
  while cur_d < total_days
    acc += cnt_extra
    if acc >= total_days
      counts[cur_d] = counts[cur_d] + 1
      acc -= total_days
    end
    cur_d += 1
  end

  counts
end

def matches_for_day(all_matches, count_needed)
  matches_today = []
  teams_busy = []

  match_ind = 0
  while matches_today.length < count_needed && match_ind < all_matches.length
    match = all_matches[match_ind]

    home_team = match[:home]
    away_team = match[:away]

    is_home_busy = teams_busy.include?(home_team)
    is_away_busy = teams_busy.include?(away_team)

    if !is_home_busy && !is_away_busy
      matches_today << all_matches.delete_at(match_ind)

      teams_busy << home_team
      teams_busy << away_team
    else
      match_ind = match_ind + 1
    end
  end
  matches_today
end

def distribute_slots(matches_today)
  slots = { "12:00" => [], "15:00" => [], "18:00" => [] }
  times = ["12:00", "15:00", "18:00"]

  time_index = 0
  matches_today.each do |match|
    current_time = times[time_index % 3]

    while slots[current_time].length >= 2
      time_index += 1
      current_time = times[time_index % 3]
    end

    slots[current_time] << match
    time_index += 1
  end
  slots
end

day_counts = cnt_games_for_day(all_matches.length, game_days.length)

calendar = []

game_days.each_with_index do |day_date, i|
  #кол-во матчей в данный день
  needed_count = day_counts[i]

  if needed_count > 0
    today_matches = matches_for_day(all_matches, needed_count)
    today_slots = distribute_slots(today_matches)
    day_info = {
      :date => day_date,
      :slots => today_slots,
      :total => today_matches.length
    }
    calendar << day_info
  end
end

File.open(output_file, 'w') do |file|
  file.puts "Расписание игр в период #{date_str_1} - #{date_str_2}"

  calendar.each do |day|
    date_str = day[:date].strftime("%d.%m.%Y")
    #название дня недели на английском
    day_name = day[:date].strftime("%A")

    file.puts "#{date_str} (#{day_name})"

    ["12:00", "15:00", "18:00"].each do |t|
      games_in_slot = day[:slots][t]

      games_in_slot.each do |m|
        file.puts "  #{t}  #{m[:home]} vs #{m[:away]} - #{m[:city]}"
      end
    end
  end
end
