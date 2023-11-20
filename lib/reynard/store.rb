# frozen_string_literal: true

class Reynard
  # Contains Reynard store implementation with various backends.
  module Store
    autoload :Disk, 'reynard/store/disk'
  end
end
