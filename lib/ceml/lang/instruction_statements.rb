module CEML
  module InstructionStatements
    def list
      [instruction_stmt.basic_statement] + more.elements.map{ |x| x.instruction_stmt.basic_statement }
    end

    def bytecode
      # p list
      list.map(&:bytecode)
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
  end
end
