module CEML
  module CastingStatement
    extend Forwardable
    def_delegators :roles, :names, :[], :min
    alias_method :rolenames, :names

    def roles_to_cast(script)
      return [] unless type == :await
      roles.list.map do |r|
        matching = []
        matching << matching_text if matching_text
        matching += [:city] if radius
        c = Criteria.new(r.qualifiers, [], matching, radius, timewindow)
        Role.new r.name, c, r.min..r.max, []
      end
    end

    def type
      elements.first.text_value.split.first.to_sym
    end

    def max
      roles.max
    end

    def within_phrase
      return if modifiers.empty?
      modifiers.elements.select{ |m| m.respond_to? :distance }.first
    end

    def over_phrase
      return if modifiers.empty?
      modifiers.elements.select{ |m| m.respond_to? :duration }.first
    end

    def with_matching_phrase
      return if modifiers.empty?
      modifiers.elements.select{ |m| m.respond_to? :thing }.first
    end

    def matching_text
      with_matching_phrase && with_matching_phrase.thing.text_value
    end

    def timewindow
      over_phrase && over_phrase.duration.seconds
    end

    def radius
      within_phrase && within_phrase.distance.meters
    end

    def nab?
      type == :nab
    end
  end
end
