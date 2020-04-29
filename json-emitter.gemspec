require_relative 'lib/json-emitter/version'

Gem::Specification.new do |s|
  s.name = 'json-emitter'
  s.version = JsonEmitter::VERSION
  s.licenses = ['MIT']
  s.summary = 'Efficiently generate tons of JSON'
  s.description = 'Generates and outputs JSON in well-sized chunks'
  s.date = '2020-04-29'
  s.authors = ['Jordan Hollinger']
  s.email = 'jordan.hollinger@gmail.com'
  s.homepage = 'https://jhollinger.github.io/json-emitter/'
  s.require_paths = ['lib']
  s.files = [Dir.glob('lib/**/*'), 'README.md'].flatten
  s.required_ruby_version = '>= 2.3.0'
  s.add_runtime_dependency 'multi_json', '~> 1.0'
end
