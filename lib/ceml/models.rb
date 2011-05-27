require 'redis'
require 'redis/objects'

Redis::Objects.redis = Redis.new

require 'ceml/models/cast'
require 'ceml/models/castable'
require 'ceml/models/incident'
require 'ceml/models/audition'
require 'ceml/models/incident_model'
require 'ceml/models/incident_role_slot'
require 'ceml/models/player'
require 'ceml/models/waiting_room'
require 'ceml/models/queue'
require 'ceml/models/bundle'

