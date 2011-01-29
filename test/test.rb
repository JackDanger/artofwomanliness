# coding: utf-8
ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'active_support'
require 'shoulda'
require 'rack/test'
require File.expand_path File.join(File.dirname(__FILE__), '..', 'app')

class AOWTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context "on GET to /" do
    setup {
      get '/'
    }
    should "return ok" do
      assert last_response.ok?
    end
  end
end