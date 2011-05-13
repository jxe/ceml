module CEML
  class Queue
    def id; 'ceml_q'; end
    include Redis::Objects
    list :calls, :marshal => true

    def run(klass)
      p = klass.new
      while call = calls.shift; p.send(*call); end
    end
  end
end
