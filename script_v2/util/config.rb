require 'yaml'

SET_JSON_FILE_PATH =    File.expand_path('../../../data_v2/sets.json', __FILE__)
CARD_JSON_FILE_PATH =   File.expand_path('../../../data_v2/sets', __FILE__)
FLAVOR_TEXT_FILE_PATH = File.expand_path('../../data/flavor_text_overrides.yml', __FILE__)

%w[
  excluded_sets
  excluded_multiverse_ids
  set_code_overrides
  set_name_overrides
  card_json_overrides
  collector_num_overrides
  flavor_text_overrides
  illustrator_overrides
  subtitle_display_overrides
  split_card_names
  mana_cost_symbols
].each do |config|
  path = File.expand_path "../../data/#{config}.yml", __FILE__
  self.class.const_set config.upcase, YAML.load_file(path)
end

EXCLUDED_TOKEN_NAMES = ['Goblin', 'Soldier', 'Kraken', 'Spirit']
SUPERTYPES = ['Basic', 'Legendary', 'World', 'Snow']
BASIC_LAND_SYMBOLS = {'Plains'   => '{W}', 'Island' => '{U}', 'Swamp'  => '{B}',
                      'Mountain' => '{R}', 'Forest' => '{G}', 'Wastes' => '{C}'}
