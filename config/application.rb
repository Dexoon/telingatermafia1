require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TelingaterMafiaBot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

module TelegramBot
  class Message
    attribute :forward_from, User
  end
end

class Array
  def to_2_dim(column_size)
    newarray = []
    (0..size - 1).step(column_size) do |x|
      layer = []
      (0..column_size - 1).to_a.each do |y|
        layer += [self[x + y]] if x + y < size
      end
      newarray += [layer]
    end
    newarray
  end
end

class Integer
  def to_roman
    roman_arr = {
      1000 => 'M',
      900 => 'CM',
      500 => 'D',
      400 => 'CD',
      100 => 'C',
      90 => 'XC',
      50 => 'L',
      40 => 'XL',
      10 => 'X',
      9 => 'IX',
      5 => 'V',
      4 => 'IV',
      1 => 'I'
    }
    num = self

    roman_arr.reduce('') do |res, (arab, roman)|
      whole_part, num = num.divmod(arab)
      res << roman * whole_part
    end
  end

  def to_circled
    to_s.tr('0123456789', '⓪①②③④⑤⑥⑦⑧⑨')
  end
end

class String
  def nest(char = '`')
    char + self + char
  end

  def decode
    key_list = %w[game_id user_id value position]
    query_types = {
      'task' => %w[start_game end_game set_result delete_game delete_last randomize
                   add_player new_game add_points load_game change_rating next
                   set_result game_over],
      'point_type' => %w[score fouls pending_fouls],
      'sure' => [false, true]
    }
    encode_hash = {}
    query_types.each do |query_type, array_of_values|
      key_list += [query_type]
      encode_hash[query_type] = {}
      array_of_values.each_with_index { |value, index| encode_hash[query_type][value] = index }
    end
    decode_hash = {}
    encode_hash.each { |key, value| decode_hash[key] = value.invert }
    query = {}
    split(',').map { |x| x == '' ? x.squeeze! : x.to_i }.each_with_index do |value, i|
      unless value.nil?
        query[key_list[i]] = decode_hash[key_list[i]].nil? ? value : decode_hash[key_list[i]][value]
      end
    end
    query
  end
end

class Hash
  def encode
    key_list = %w[game_id user_id value position]
    query_types = {
      'task' => %w[start_game end_game set_result delete_game delete_last randomize
                   add_player new_game add_points load_game change_rating next
                   set_result game_over],
      'point_type' => %w[score fouls pending_fouls],
      'sure' => [false, true]
    }
    encode_hash = {}
    query_types.each do |query_type, array_of_values|
      key_list += [query_type]
      encode_hash[query_type] = {}
      array_of_values.each_with_index { |value, index| encode_hash[query_type][value] = index }
    end
    str = ''
    key_list.each do |key|
      unless self[key].nil?
        str += encode_hash[key].nil? ? self[key].to_s : encode_hash[key][self[key]].to_s
      end
      str += ','
    end
    str.chomp(',')
  end
end
