module CEML
  module CastingStatement
    extend Forwardable
    def_delegators :roles, :names, :[], :min
    alias_method :rolenames, :names

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
