require_relative 'util.rb'
require_relative 'card.rb'

class GathererSet
  attr_accessor :name
  def initialize(name); self.name = name; end
  def self.dump(name); self.new(name).as_json; end

  # Dump each individual card for a given set.
  def card_json
    multiverse_ids = Gatherer.scrape_multiverse_ids(name)
    Worker.distribute(multiverse_ids, GathererCard, :dump).flatten.compact
  end

  def as_json(options={})
    set_page = get Gatherer.url(for_set: self.name)
    set_img = set_page.css('img[src^="../../Handlers/Image.ashx?type=symbol&set="]').first
    set_code = set_img.attr(:src)[/set=(\w+)/, 1].downcase
    { 'name' => SET_NAME_OVERRIDES[self.name] || self.name,
      'code' => SET_CODE_OVERRIDES[set_code] || set_code }
  end

  # Scrape and return the json data for all sets
  def self.as_json(options={})
    set_names = Gatherer.scrape_set_names
    new_set_json = Worker.distribute(set_names, GathererSet, :dump)

    # Merge newly-dumped set data into existing sets.json
    old_set_json = Hash[read(SET_JSON_FILE_PATH).map{|set| [set['name'], set]}]
    new_set_json.each do |set|
      old_set_json[set['name']] = (old_set_json[set['name']] || {}).merge(set)
    end
    old_set_json.values.sort_by{|set| set['name']}
  end
end
