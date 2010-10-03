module Tryst
  module Instructions
    def validate!(allowed_roles)
      extra_roles = roles - allowed_roles
      raise "unrecognized rolenames: #{extra_roles.inspect}" unless extra_roles.empty?

      # max one tell per role
      roles.each{ |r| tell([r]) }
    end

    def roles
      elements.map{ |s| s.role.to_sym }.uniq
    end

    def for(roles)
      elements.select{ |s| roles.include?(s.role.to_sym) }
    end

    def asks(roles)
      elements.select do |s|
        s.text_value =~ /^ask/ && roles.include?(s.role.to_sym)
      end
    end

    def tell(roles)
      ss = elements.select{ |s| s.text_value =~ /^tell/ && roles.include?(s.role.to_sym) }
      raise "multiple assignments for role: #{role}" if ss.size > 1
      ss.first
    end
  end
end
