require 'telegram/bot'
require 'json'
require 'date'
require 'net/http'

def request(day)
  if day != 1 && day != 2
    return "Неправильное значение day. Используйте 1 для сегодня или 2 для завтра."
  end

  target_date = Date.today + (day - 1)
  target_date_str = target_date.strftime("%d.%m.%Y")

  uri = URI('https://sevsu.samrzhevsky.ru/api/schedule?v=2&institute=0&term=0&group=%D0%9F%D0%98%D0%9D%2F%D0%B1-20-1-%D0%BE&week=7')
  res = Net::HTTP.get_response(uri)
  parsed_data = JSON.parse(res.body)

  matching_data = parsed_data["schedule"].select { |item| Date.parse(item["date"]) == target_date }

  if matching_data.empty?
    return "На #{target_date_str} нет занятий."
  else
    schedule_text = "Список предметов на #{target_date_str}:\n"
    matching_data.each do |item|
      schedule_text += "время: #{timeStart(item)}\n"
      schedule_text += "аудитория: #{item['location']}\n"
      schedule_text += "#{item['teacher']}\n"
      schedule_text += "#{item['lesson']}\n\n"
    end
    return schedule_text
  end
end

def timeStart(item)
  time_intervals = {
    1 => '8:30-10:00',
    2 => '10:10-11:40',
    3 => '11:50-13:20',
    4 => '14:00-15:30',
    5 => '15:40-17:10',
    6 => '17:20-18:50',
    7 => '19:00-20:30',
    8 => '20:40-22:10'
  }

  lesson_number = item["n"]
  time_interval = time_intervals[lesson_number]
  return time_interval
end
 answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [
            [{ text: '/сегодня' }],[{ text: '/завтра' }],[{ text: '/stop' }]

          ],
          one_time_keyboard: true
        )
token = ''
Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|

    case message.text
    when "/start"
      bot.api.sendMessage(chat_id: message.chat.id, text: "Привет! Здесь можно посмотреть расписание для группы ПИН/б-20-1-о.", reply_markup: answers)
    when '/сегодня'
      response = request(1)
      bot.api.sendMessage(chat_id: message.chat.id, text: response, reply_markup: answers)
    when '/завтра'
      response = request(2)
      bot.api.sendMessage(chat_id: message.chat.id, text: response, reply_markup: answers)
    when '/stop'
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      bot.api.send_message(chat_id: message.chat.id, text: 'НУ и ходи без расписания', reply_markup: kb)
    end
  end
end
