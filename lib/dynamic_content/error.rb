module DynamicContent
  class ErrorLoading < RuntimeError
  end

  class Error < RuntimeError
  end

  class DependencyError < ErrorLoading
  end

  class NoStructureFileError < KeyError
  end

  class InvalidStructureError < KeyError
  end

  class GeneratorError < Error
  end
end
