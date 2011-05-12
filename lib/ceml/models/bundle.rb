module CEML
  class Bundle < Struct.new(:id)
    include Redis::Objects
    value :castables, :marshal => true
  end
end
