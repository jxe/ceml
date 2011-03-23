module CEML

  module CastingStatement
    extend Forwardable
    def_delegators :roles, :names, :[], :min
    alias_method :rolenames, :names

    def casting_spec
      return nil unless type == :await
      matching = []
      matching << matching_text.to_sym if matching_text
      matching += [:city] if radius
      rolespecs = roles.list.map do |r|
        RoleSpec.new(r.name, Tagspec.new(r.qualifiers,[]), r.min..r.max)
      end
      [matching, radius, timewindow, rolespecs]
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
