lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'http_api/version'

Gem::Specification.new do |spec|
  spec.name        = "http_api"
  spec.version     = HttpApi::VERSION
  spec.summary     = "Customized http"
  spec.authors     = ["Junil Jacob"]
  spec.email       = ["juniljacob124@gmail.com"]
  spec.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.homepage    = "https://github.com/Healthicity/http_api"
  spec.license     = "MIT"
  spec.add_dependency 'http', '~> 3.3'
  spec.add_dependency 'activesupport', '>= 6.0.0', '< 7'
  spec.add_development_dependency 'webmock', '~> 3'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'test-unit'
end