
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'micro/case/version'

Gem::Specification.new do |spec|
  spec.name          = 'u-case'
  spec.version       = Micro::Case::VERSION
  spec.authors       = ['Rodrigo Serradura']
  spec.email         = ['rodrigo.serradura@gmail.com']

  spec.summary       = %q{Represent use cases in a simple and powerful way while writing modular, expressive and sequentially logical code.}
  spec.description   = %q{Represent use cases in a simple and powerful way while writing modular, expressive and sequentially logical code.}
  spec.homepage      = 'https://github.com/serradura/u-case'
  spec.license       = 'MIT'

  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|assets|benchmarks|comparisons|examples)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency 'kind', '>= 5.6', '< 6.0'
  spec.add_runtime_dependency 'u-attributes', '>= 2.7', '< 3.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 13.0'
end
