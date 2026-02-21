module RacketM8
  class MatchFinder
    DEFAULT_NEARBY_SUBURBS = {
      "Marrickville" => %w[Marrickville Dulwich\ Hill Newtown Stanmore Enmore Petersham Camperdown Tempe Sydenham Erskineville],
      "Surry Hills"  => %w[Surry\ Hills Moore\ Park Redfern Darlinghurst Waterloo Paddington],
      "Newtown"      => %w[Newtown Enmore Stanmore Camperdown Erskineville Marrickville],
      "Enmore"       => %w[Enmore Newtown Marrickville Stanmore Petersham],
      "Petersham"    => %w[Petersham Stanmore Marrickville Dulwich\ Hill Enmore Lewisham],
      "Ashfield"     => %w[Ashfield Summer\ Hill Haberfield Leichhardt Petersham]
    }.freeze

    attr_reader :suburb, :utr, :level_label, :time_text, :players_needed, :singles_only

    def initialize(suburb:, utr: nil, level_label: nil, time_text: nil, players_needed: 1, singles_only: false)
      @suburb = normalize_suburb(suburb)
      @utr = utr
      @level_label = level_label
      @time_text = time_text
      @players_needed = players_needed.to_i
      @singles_only = singles_only
    end

    def call
      {
        filters: filters_used,
        players: matched_players,
        courts: matched_courts,
        notes: notes
      }
    end

    private

    def filters_used
      {
        suburb: suburb,
        nearby_suburbs: nearby_suburbs,
        utr: utr,
        level_label: level_label,
        time_text: time_text,
        players_needed: players_needed,
        singles_only: singles_only
      }
    end

    def nearby_suburbs
      DEFAULT_NEARBY_SUBURBS[suburb] || [suburb]
    end

    def matched_players
      scope = Player.where(suburb: nearby_suburbs)

      if utr.present?
        scope = scope.where(utr: ((utr - 0.4)..(utr + 0.4)))
      elsif level_label.present?
        # Soft matching by text if UTR isn't supplied
        scope = scope.where("LOWER(level_label) LIKE ?", "%#{level_label.downcase}%")
      end

      # Demo-friendly ordering: nearest suburb first, then closeness to UTR if provided
      players = scope.to_a

      players.sort_by! do |p|
        suburb_rank = nearby_suburbs.index(p.suburb) || 999
        utr_distance = utr.present? ? (p.utr.to_f - utr.to_f).abs : 0
        [suburb_rank, utr_distance]
      end

      players.first(limit_players)
    end

    def matched_courts
      scope = Court.where(suburb: nearby_suburbs)

      if evening_time?
        # Prefer lights for evening demos
        lit_first = scope.order(Arel.sql("CASE WHEN lights THEN 0 ELSE 1 END"), :suburb, :name)
        lit_first.to_a.first(3)
      else
        scope.order(:suburb, :name).limit(3)
      end
    end

    def limit_players
      # Singles = usually 1 partner; doubles planning may need more
      if players_needed >= 4
        6
      elsif players_needed >= 2
        4
      else
        3
      end
    end

    def evening_time?
      return false if time_text.blank?

      text = time_text.downcase
      text.include?("pm") || text.match?(/\b(18|19|20|21|22):?\d{0,2}\b/)
    end

    def notes
      notes = []
      notes << "Mock inventory only (demo mode), not live availability."
      notes << "Evening query detected, prioritising courts with lights." if evening_time?
      notes
    end

    def normalize_suburb(value)
      return "" if value.blank?

      value.to_s.strip.split.map(&:capitalize).join(" ")
    end
  end
end
