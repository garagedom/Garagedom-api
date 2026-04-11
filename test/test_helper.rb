ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

OmniAuth.config.test_mode = true
Geocoder.configure(lookup: :test)
Geocoder::Lookup::Test.set_default_stub(
  [ { "coordinates" => [ -23.1896, -46.8956 ] } ]
)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
