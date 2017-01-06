class GathererStandardCard
  extend Memoizer
  attr_accessor :multiverse_id, :page

  def initialize(multiverse_id, page)
    self.multiverse_id = multiverse_id
    self.page = page
  end

  memo def parse_name
    name_str = page.css('[id$="subtitleDisplay"]').text.strip
    SUBTITLE_DISPLAY_OVERRIDES[multiverse_id] || name_str
  end

  memo def parse_collector_num
    COLLECTOR_NUM_OVERRIDES[multiverse_id] || labeled_row(:number)
  end

  memo def parse_types
    types = labeled_row(:type).split("—").map(&:strip)[0].split(' ') - SUPERTYPES
    supertypes = labeled_row(:type).split("—").map(&:strip)[0].split(' ') & SUPERTYPES
    subtypes = labeled_row(:type).split("—").map(&:strip)[1].gsub("’", "'").split(' ') rescue []
    { types: types, supertypes: supertypes, subtypes: subtypes }
  end

  memo def parse_set_name
    set_name_str = labeled_row(:set)
    SET_NAME_OVERRIDES[set_name_str] || set_name_str
  end

  memo def parse_mana_cost
    container.css('[id$="manaRow"] .value img').map do |symbol|
      Gatherer.translate_mana_symbol(symbol)
    end.join
  end

  memo def parse_oracle_text
    # Override oracle text for basic lands.
    if parse_types[:supertypes].include?('Basic')
      return  ["({T}: Add #{BASIC_LAND_SYMBOLS[parse_name]} to your mana pool.)"]
    end

    textboxes = container.css('[id$="textRow"] .cardtextbox')
    textboxes.map do |textbox|
      textbox.css(:img).each do |img|
        img_alt = img.attr(:alt).strip
        symbol = MANA_COST_SYMBOLS[img_alt] || img_alt
        symbol = "{#{symbol}}" unless symbol.match(/^{/)
        img.replace(symbol)
      end
      # Gatherer messes up {10} formatting, resulting in {1}0
      textbox.text.strip.gsub('{1}0', '{10}')
    end.select(&:present?)
  end

  memo def parse_flavor_text
    return FLAVOR_TEXT_OVERRIDES[multiverse_id] if FLAVOR_TEXT_OVERRIDES[multiverse_id]
    textboxes = container.css('[id$="flavorRow"] .flavortextbox')
    textboxes.map{|t| t.text.strip}.select(&:present?).join("\n").presence
  end

  memo def parse_pt
    if parse_types[:types].include?('Planeswalker')
      { loyalty: labeled_row(:pt) }
    elsif parse_types[:types].include?('Creature')
      { power:     labeled_row(:pt).split('/')[0].strip,
        toughness: labeled_row(:pt).split('/')[1].strip }
    else
      {}
    end
  end

  ILLUSTRATOR_REPLACEMENTS = {
    "Brian Snoddy" => "Brian Snõddy",
    "Parente & Brian Snoddy" => "Parente & Brian Snõddy",
    "ROn Spencer" => "Ron Spencer",
    "s/b Lie Tiu" => "Lie Tiu"
  }
  memo def parse_illustrator
    artist_str = labeled_row(:artist)
    ILLUSTRATOR_OVERRIDES[multiverse_id] ||
      ILLUSTRATOR_REPLACEMENTS[artist_str] || artist_str
  end

  RARITY_REPLACEMENTS = {'Basic Land' => 'Land'}
  memo def parse_rarity
    rarity_str = labeled_row(:rarity)
    RARITY_REPLACEMENTS[rarity_str] || rarity_str
  end

  def parse_color_indicator
    color_indicator_str = labeled_row(:colorIndicator).presence
    color_indicator_str.split(', ').join(' ') if color_indicator_str
  end

  CARD_NAME_OVERRIDES = {
    91 => 'Will-O\'-The-Wisp',
    386 => 'Will-O\'-The-Wisp',
    688 => 'Will-O\'-The-Wisp',
    1187 => 'Will-O\'-The-Wisp',
    2138 => 'Will-O\'-The-Wisp',
  }
  def as_json(options={})
    return if parse_types[:types].include?('Token') ||
                parse_name.in?(EXCLUDED_TOKEN_NAMES)
    {
      'name'                => CARD_NAME_OVERRIDES[multiverse_id] || parse_name,
      'set_name'            => parse_set_name,
      'collector_num'       => parse_collector_num,
      'illustrator'         => parse_illustrator,
      'types'               => parse_types[:types],
      'supertypes'          => parse_types[:supertypes],
      'subtypes'            => parse_types[:subtypes],
      'rarity'              => parse_rarity,
      'mana_cost'           => parse_mana_cost.presence,
      'converted_mana_cost' => labeled_row(:cmc).to_i,
      'oracle_text'         => parse_oracle_text,
      'flavor_text'         => parse_flavor_text,
      'power'               => parse_pt[:power],
      'toughness'           => parse_pt[:toughness],
      'loyalty'             => parse_pt[:loyalty],
      'multiverse_id'       => multiverse_id,
      'other_part'          => nil,
      'color_indicator'     => parse_color_indicator,
    }
  end

  # Grab the .cardComponentContainer that corresponds with this card. Flip,
  # split, and transform cards can have multiple containers on the page and
  # may need to be handled differently
  def container
    containers.find do |container|
      subtitleDisplay = SUBTITLE_DISPLAY_OVERRIDES[multiverse_id] ||
                          page.css('[id$="subtitleDisplay"]').text.strip
      container.css('[id$="nameRow"] .value').text.strip == subtitleDisplay
    end || containers.first
  end

  def containers
    page.css('.cardComponentContainer')
  end

  memo def labeled_row(label)
    container.css("[id$=\"#{label}Row\"] .value").text.strip
  end
end