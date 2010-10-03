module Tryst
  module CastingStatement
    extend Forwardable
    def_delegators :roles_phrase, :roles, :[], :min

    def type
      elements.first.text_value.split.first.to_sym
    end

    def max
      in_teams? ? 10000 : roles_phrase.max
    end

    def radius
      within.empty? ? 1600 * 50 : within.distance.meters
    end

    def in_teams?
      type == :teams
    end

    def nab?
      type == :nab
    end
  end


  module CastingRoles
    def role_nodes
      return [role] if more_roles.empty?
      return [role] + more_roles.roles_phrase.role_nodes
    end

    def roles
      role_nodes.map{ |r| r.name.to_sym }
    end

    def [](x)
      role_nodes.detect{ |r| r.name.to_sym == x }
    end

    def min
      role_nodes.map(&:min).inject(0, &:+)
    end

    def max
      role_nodes.map(&:max).inject(0, &:+)
    end
  end


end
