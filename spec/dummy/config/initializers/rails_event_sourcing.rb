# frozen_string_literal: true

# Preload dispatchers classes
Rails.root.join('app').glob('**/*_dispatcher.rb').sort.each do |path|
  require(path.to_s)
end
