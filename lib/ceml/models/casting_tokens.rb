module CEML
  class Audition < Struct.new(:id)
    include Redis::Objects
    set :rooms
  end

  module CastingTokens
    def self.post(bundle_id, token, room_ids)
      room_ids << bundle_id
      room_ids.each do |room_id|
        Audition.new(token).rooms << room_id
        WaitingRoom.new(room_id).waiting_auditions << token
      end
    end

    def self.all_tokens(room_ids)
      rooms = room_ids.map{ |r| WaitingRoom.new(r) }
      rooms.map{ |r| r.waiting_auditions.members }.flatten.uniq
    end

    def self.destroy_all(bundle_id)
      all = WaitingRoom.new(bundle_id).waiting_auditions.members
      # puts "DESTROYING tokens: #{all.inspect}"
      destroy(all)
    end

    def self.destroy(tokens)
      roomsets = tokens.map{ |id| Audition.new(id).rooms }
      rooms = roomsets.map(&:members).flatten.uniq
      # puts "Consuming ids #{ids.inspect} from rooms #{rooms.inspect}"
      # TODO: install new redis and re-enable watchlist
      # redis.watch(*roomsets.map(&:key))
      # redis.multi do
      # rooms = roomsets.first.union(roomsets[1,-1]) || []
      rooms.product(tokens).each do |r, id|
        # puts "DELETING #{id} from room #{r}"
        WaitingRoom.new(r).waiting_auditions.delete(id)
      end
      roomsets.map(&:clear)
      # end
      true
    end

    # this one should collect none unless all can be collected
    # using multi/exec
    def self.collect(tokens)
      destroy(tokens)
    end

  end
end
