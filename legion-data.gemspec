# frozen_string_literal: true

require_relative 'lib/legion/data/version'

Gem::Specification.new do |spec|
  spec.name = 'legion-data'
  spec.version       = Legion::Data::VERSION
  spec.authors       = ['Esity']
  spec.email         = %w[matthewdiverson@gmail.com ruby@optum.com]

  spec.summary       = 'Manages the connects to the backend database'
  spec.description   = 'A LegionIO gem to connect to a persistent data store'
  spec.homepage      = 'https://github.com/Optum/legion-data'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.5'
  spec.require_paths = ['lib']
  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files        = spec.files.select { |p| p =~ %r{^test/.*_test.rb} }
  spec.extra_rdoc_files  = %w[README.md LICENSE CHANGELOG.md]
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/Optum/legion-data/issues',
    'changelog_uri' => 'https://github.com/Optum/legion-data/src/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/Optum/legion-data',
    'homepage_uri' => 'https://github.com/Optum/LegionIO',
    'source_code_uri' => 'https://github.com/Optum/legion-data',
    'wiki_uri' => 'https://github.com/Optum/legion-data/wiki'
  }

  spec.add_dependency 'legion-logging'
  spec.add_dependency 'legion-settings'
  spec.add_dependency 'mysql2'
  spec.add_dependency 'sequel'
end
