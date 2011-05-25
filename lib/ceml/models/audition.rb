module CEML

  class Audition < Struct.new(:id)  # "#{code}:#{player_id}"
    include Redis::Objects
    set :rooms

    def list_in_rooms(da_rooms)
      # p "Listing in rooms #{da_rooms.map(&:id)}"
      da_rooms.each{ |room| self.rooms << room.id; room.add(id) }
    end

    def clear_from_all_rooms(*extra_rooms)
      rooms_to_clear = rooms.members + extra_rooms
      redis.multi do
        rooms_to_clear.each do |r|
          WaitingRoom.new(r).waiting_auditions.delete(id)
        end
        redis.del rooms.key
      end
    end

    def self.consume(ids, extra_rooms = [])
      roomsets = ids.map{ |id| Audition.new(id).rooms }
      rooms = (roomsets.map(&:members) + extra_rooms).flatten.uniq
      # puts "Consuming ids #{ids.inspect} from rooms #{rooms.inspect}"
      # TODO: install new redis and re-enable watchlist
      # redis.watch(*roomsets.map(&:key))
      # redis.multi do
        # rooms = roomsets.first.union(roomsets[1,-1]) || []
        rooms.each do |r|
          # puts "PROCESSING ROOM #{r.key}"
          ids.each do |id|
            # puts "DELETING #{id} from room #{r}"
            WaitingRoom.new(r).waiting_auditions.delete(id)
          end
        end
        roomsets.map(&:clear)
      # end
      true
    end

    def self.from_rooms(room_ids)
      players = {}
      rooms = room_ids.map{ |r| WaitingRoom.new(r) }
      auditions = rooms.map{ |r| r.waiting_auditions.members }.flatten

      # clear old style
      auditions.each do |a|
        next unless a =~ /:/
        Audition.new(a).rooms.clear
        rooms.each{ |r| r.waiting_auditions.delete(a) }
      end

      puts "Auditions found: #{auditions.inspect}"
      auditions.each do |audition|
        # next if audition =~ /:/
        # code, player_id = audition.split(':')
        player_id = audition
        players[player_id] ||= audition
      end
      players
    end
  end

end
