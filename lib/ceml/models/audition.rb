module CEML

  class Audition < Struct.new(:id)  # "#{code}:#{player_id}"
    include Redis::Objects
    set :rooms

    def list_in_rooms(da_rooms)
      p "Listing in rooms #{da_rooms.map(&:id)}"
      da_rooms.each{ |room| self.rooms << room.id; room.add(id) }
    end

    def self.consume(ids)
      roomsets = ids.map{ |id| Audition.new(id).rooms }
      rooms = roomsets.map(&:members).flatten.uniq
      puts "Consuming ids #{ids.inspect} from rooms #{rooms.inspect}"
      # TODO: install new redis and re-enable watchlist
      # redis.watch(*roomsets.map(&:key))
      redis.multi do
        # rooms = roomsets.first.union(roomsets[1,-1]) || []
        rooms.each{ |r| ids.each{ |id| r.delete(id) } }
        redis.del *roomsets.map(&:key)
        yield
      end
    end

    def self.from_rooms(room_ids)
      players = {}
      rooms = room_ids.map{ |r| WaitingRoom.new(r) }
      auditions = rooms.map{ |r| r.waiting_auditions.members }.flatten

      # tmp hack to clear db
      # auditions.each do |a|
      #   Audition.new(a).rooms.clear
      #   rooms.each{ |r| r.waiting_auditions.delete(a) }
      # end

      p "Auditions found: #{auditions.inspect}"
      auditions.each do |audition|
        next if audition =~ /:/
        # code, player_id = audition.split(':')
        player_id = audition
        players[player_id] ||= audition
      end
      players
    end
  end

end
