File.expand_path('lib', __dir__).tap do |lib|
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

ruby_version = '~> 3.3'

require 'berkeley_library/util/module_info'

Gem::Specification.new do |spec|
  spec.name = BerkeleyLibrary::Util::ModuleInfo::NAME
  spec.author = BerkeleyLibrary::Util::ModuleInfo::AUTHOR
  spec.email = BerkeleyLibrary::Util::ModuleInfo::AUTHOR_EMAIL
  spec.summary = BerkeleyLibrary::Util::ModuleInfo::SUMMARY
  spec.description = BerkeleyLibrary::Util::ModuleInfo::DESCRIPTION
  spec.license = BerkeleyLibrary::Util::ModuleInfo::LICENSE
  spec.version = BerkeleyLibrary::Util::ModuleInfo::VERSION
  spec.homepage = BerkeleyLibrary::Util::ModuleInfo::HOMEPAGE

  spec.files = `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']

  spec.required_ruby_version = ruby_version

  spec.add_dependency 'berkeley_library-logging', '~> 0.3'
  spec.add_dependency 'rest-client', '~> 2.1'
  spec.add_dependency 'typesafe_enum', '~> 0.3'

  spec.add_development_dependency 'ci_reporter_rspec', '~> 1.0'
  spec.add_development_dependency 'colorize', '~> 1.0'
  spec.add_development_dependency 'dotenv', '~> 2.7'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.78.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.6.0'
  spec.add_development_dependency 'ruby-prof'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'webmock', '~> 3.12'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
