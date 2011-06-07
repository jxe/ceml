module CEML
  class CastingPool < Struct.new :room_ids
    def self.destroy_everywhere(bundle_id, player_id)
      CastingTokens.destroy([player_id])
    end

    def player_ids
      tokens = CastingTokens.all_tokens(room_ids)
      @tokens_by_player_id = tokens.inject({}){ |m,o| m[o]=o; m }
      @tokens_by_player_id.keys
    end

    def hot_players
      player_ids.map{ |id| Player.new(id).data.value }
    end

    def claim(player_ids)
      tokens = @tokens_by_player_id.values_at(*player_ids)
      CastingTokens.collect(tokens)
    end

    def post(bundle_id, player_id)
      CastingTokens.post(bundle_id, player_id, room_ids)
    end
  end
end
