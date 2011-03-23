module CEML
  class Bid < Struct.new :cast, :value, :incident_id
    def guys
      cast.folks.map{ |guy| guy[:id] }
    end
  end

  class Castable < Struct.new :matching, :radius, :timewindow, :roles, :bytecode

    def queries guys
      # use the guys to gen a list of queries
      # run all queries and gather all matching guys
    end

    # an O(n*^2) alg for now.  can do much better
    def cast_from guys
      # see if we can build a cast out of them and bid on the casts
      possible_casts = guys.map{ |guy| Cast.new self, guy }.select(&:star)
      guys.each{ |guy| possible_casts.each{ |cast| cast.cast guy }}
      cast = possible_casts.first(&:complete?)
      Bid.new(cast, 1.0)
    end



    def left_to_cast(cast)
      roles.map{ |r| r.range.min - cast[r.name].size }.
        select{ |n| n > 0 }.inject(0, &:+)
    end

    def urgency(cast)
      # a function of time left in timewindow and cast uncasted:
      # ->the likelihood that if this person is uncast, the mission won't go off,
      #   but if they are, it will.  for now, the differences in the poisson
      #   probability distribution

      remaining = left_to_cast(cast)
      return 0 if remaining == 0  # zero if fully cast

      # poisson magic
      avails_per_second = 0.2  # this is made up
      star = cast.values.flatten.first
      seconds_left = star ? star[:ts] + timewindow : 30*60
      n = remaining
      rate = seconds_left * avails_per_second
      Math.exp(-rate) * (rate**n) / n.downto(1).inject(:*)
    end
  end
end
