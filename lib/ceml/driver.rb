module CEML
  class Driver
    def to_bytecode bytecode_or_script
      case bytecode_or_script
      when String;       return CEML.parse(:script, bytecode_or_script).bytecode
      when CEML::Script; return bytecode_or_script.bytecode
      when Array;        return bytecode_or_script
      else return nil
      end
    end
  end
end
