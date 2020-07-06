# frozen_string_literal: true

require_relative 'lib/sidekiq_status/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq_status'
  spec.version       = SidekiqStatus::VERSION
  spec.authors       = ['Campbell Allen']
  spec.email         = ['campbell.allen@gmail.com']

  spec.summary       = 'Status of your sidekiq system - useful for Kubernetes liveness probes'
  spec.description   = 'Status of your sidekiq system - useful for Kubernetes liveness probes'
  spec.homepage      = 'https://github.com/camallen/sidekiq_status'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end