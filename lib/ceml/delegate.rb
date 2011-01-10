module Kernel
  def gen_code(size = 8)
    rand(36**size).to_s(36)
  end
end

module CEML
  class Delegate
    LOCATIONS = {}
    PLAYERS   = {}

    # yields thing w. #keys, #each, #[], #[]=
    def with_players id
      yield PLAYERS[id] ||= {}
    end

    # yields a thing with #each and #<<
    def with_locations script
      yield LOCATIONS[script] ||= []
      LOCATIONS[script].delete_if{ |loc| loc.cast and Incident.new(script, loc.cast).run }
    end

    def method_missing(meth, *args, &blk)
      puts "#{meth}: #{args.map(&:to_s).join(', ')}"
    end

  end
end
