task start: :environment do
  # BACKGROUND=y PIDFILE=daemon.pid LOG_LEVEL=info bundle exec rake start
  Rails.logger       = Logger.new(Rails.root.join('log', 'daemon.log'))
  Rails.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'info').upcase)
  user_bot = TelegramBot.new(token: '315066645:AAGd2SdpVLnTPNgoC8CQKVBdFIubDGqriC4')
  vk_api = VkontakteApi::Client.new
  Process.daemon(true, true) if ENV['BACKGROUND']

  File.open(ENV['PIDFILE'], 'w') { |f| f << Process.pid } if ENV['PIDFILE']

  Signal.trap('TERM') { abort }

  Rails.logger.info 'Start daemon...'

  loop do
    user_bot.get_updates(fail_silently: true) do |message|
      puts "@#{message.from.username}: #{message.text}"
      if message.forward_from.nil?
        if /vk.com/.match(message.text)
          vk_address = /\/.*$/.match(/vk\.com\/\w+/.match(message.text)[0])[0][1..-1]
          vk_res = vk_api.users.get(users_ids: vk_address)
          if vk_res.count.zero?
            @user = nil
          else
            id_vk = vk_res.first.uid
            @user = User.find_by(vk: id_vk)
          end
        else
          @user = User.find_by(telegram: message.from.id)
        end
      else
        @user = User.find_by(telegram: message.forward_from.id)
      end
      # command = message.get_command_for(bot)

      message.reply do |reply|
        if @user.nil?
          reply.text = 'Пользователь не зарегестрирован. Напишите 0дмену'
        else
          @user.update(online: !@user.online)
          reply.text = "Обновлено. #{@user.surname} #{@user.name} теперь"
          reply.text += if @user.online
                          ' на игре'
                        else
                          ' не на игре'
                        end
        end
        reply.send_with(user_bot)
      end
    end
    sleep ENV['INTERVAL'] || 1
  end
end
