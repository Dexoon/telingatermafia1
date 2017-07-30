class User < ApplicationRecord
  has_many :players
  scope :online, -> { where(online: true) }
  scope :available, ->(game) { where.not(id: game.players.map(&:user_id)) }
  def to_s(options = {})
    options.reverse_merge!(
      'name' => true,
      'surname' => true,
      'pending_fouls' => false
    )
    pending_fouls_char = 'x' # ⦶
    str = ''
    str += name + ' ' if options['name']
    str += surname + ' ' if options['surname']
    pending_fouls.times { str += pending_fouls_char } if options['pending_fouls']
    str
  end

  def write_message(_method = 'telegram', _text)
    user_bot = TelegramBot.new(token: '315066645:AAGd2SdpVLnTPNgoC8CQKVBdFIubDGqriC4')
  end

  def self.find_by_str(str)
    vk_api = VkontakteApi::Client.new
    if /vk.com/.match(str)
      vk_address = /\/.*$/.match(/vk\.com\/\w+/.match(str)[0])[0][1..-1]
      vk_res = vk_api.users.get(user_ids: vk_address)
      if vk_res.count.zero?
        user = nil
      else
        id_vk = vk_res.first.uid
        user = User.find_by(vk: id_vk)
      end
    else
      user = User.find_by(surname: str.split(' ')[0], name: str.split(' ')[1]) if str.split(' ').count==2
      user = User.find_by(surname: str.split(' ')[0], name: str.split(' ')[1]) if str.split(' ').count==2 && user.nil?
      user = User.find_by(surname: str) if user.nil?
    end
    user
  end

  def change_online_status
    update(online: !online)
    reply = "Обновлено. #{surname} #{name} теперь"
    reply += if online
               ' на игре'
             else
               ' не на игре'
             end
    reply
  end

  def add_points(category = 'pending_fouls', value)
    case category
    when 'pending_fouls'
      update(pending_fouls: [0, pending_fouls + value].max)
    end
  end
end
