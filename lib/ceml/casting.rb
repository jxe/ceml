module CEML
  module CastingStatement
    extend Forwardable
    def_delegators :roles, :names, :[], :min
    alias_method :rolenames, :names

    def criteria(script)
      return [] unless type == :await
      group_by = if radius then [:city] else [] end
      criteria_by_qualifiers = Hash.new do |h,k|
        h[k] = CastingCriterion.new(script, k, [], group_by, radius, {})
      end

      roles.list.each{ |r| criteria_by_qualifiers[r.qualifiers].role_counts[r.name] = r.min }
      criteria_by_qualifiers.values
    end

    def type
      elements.first.text_value.split.first.to_sym
    end

    def max
      roles.max
    end

    def radius
      within_phrase.empty? ? 1600 * 50 : within_phrase.distance.meters
    end

    def nab?
      type == :nab
    end
  end
end
