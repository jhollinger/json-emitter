require 'json-emitter'
require 'minitest/autorun'
require 'date'
require 'rack'

Dir.glob('./test/support/*.rb').each { |file| require file }
