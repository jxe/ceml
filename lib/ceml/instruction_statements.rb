module CEML
  module InstructionStatements
    def list
        [instruction_stmt] + more.elements.map(&:instruction_stmt)
    end

    def instructions
      self
    end

    def validate_instructions!(allowed_roles)
      extra_roles = roles - allowed_roles
      raise "unrecognized rolenames: #{extra_roles.inspect}" unless extra_roles.empty?
    end

    def roles
      list.map{ |s| s.role.to_sym }.uniq
    end

    def for(roles)
      list.select{ |s| roles.include?(s.role.to_sym) }
    end

    def i_asks(roles)
      list.select do |s|
        s.text_value =~ /^ask/ && roles.include?(s.role.to_sym)
      end
    end

    def i_tell(roles)
      ss = list.select{ |s| s.text_value =~ /^tell/ && roles.include?(s.role.to_sym) }
      raise "multiple assignments for role: #{role}" if ss.size > 1
      ss.first
    end
  end
end
