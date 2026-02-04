Dir.glob(File.expand_path('util/*.rb', __dir__)).each(&method(:require))
