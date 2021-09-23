Dir.glob(File.expand_path('util/*.rb', __dir__)).sort.each(&method(:require))
