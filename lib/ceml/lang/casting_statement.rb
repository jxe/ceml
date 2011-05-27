module CEML

  module CastingStatement
    extend Forwardable
    def_delegators :roles, :names, :[], :min
    alias_method :rolenames, :names

    def casting_spec
      return nil unless live_casting?
      matching = []
      matching << matching_text.to_sym if matching_text
      matching += [:city] if radius
      rolespecs = roles.list.map do |r|
        RoleSpec.new(r.name, Tagspec.new(r.qualifiers,[]), r.min..r.max)
      end
      [type, stanza_name, matching, radius, timewindow, rolespecs]
    end

    def type
      elements[1].text_value.split.first.to_sym
    end

    def live_casting?
      [:await, :accept].include?(type)
    end

    def max
      roles.max
    end

    def stanza_name
      return nil if stanza_marker.empty?
      stanza_marker and stanza_marker.name and stanza_marker.name.text_value
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
