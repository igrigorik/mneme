require 'lib/mneme'
require 'goliath/test_helper'
require 'em-http/middleware/json_response'

describe Mneme do
  include Goliath::TestHelper

  let(:err) { Proc.new { fail "API request failed" } }
  let(:api_options) { { :config => File.expand_path(File.join(File.dirname(__FILE__), '..', 'config.rb')) } }

  EventMachine::HttpRequest.use EventMachine::Middleware::JSONResponse

  it 'responds to hearbeat' do
    with_api(Mneme, api_options) do
      get_request({path: '/status'}, err) do |c|
        c.response.should match('OK')
      end
    end
  end

  it 'should require an error if no key is provided' do
    with_api(Mneme, api_options) do
      get_request({}, err) do |c|
        c.response.should include 'error'
      end
    end
  end

  context 'single key' do
    it 'should return 404 on missing key' do
      with_api(Mneme, api_options) do
        get_request({:query => {:key => 'missing'}}, err) do |c|
          c.response_header.status.should == 404
          c.response['missing'].should include 'missing'
        end
      end
    end

    it 'should insert key into filter' do
      with_api(Mneme, api_options) do
        post_request({:query => {key: 'abc'}}) do |c|
          c.response_header.status.should == 201

          get_request({:query => {:key => 'abc'}}, err) do |c|
            c.response_header.status.should == 200
            c.response['found'].should include 'abc'
          end
        end
      end
    end
  end

  context 'multiple keys' do

    it 'should return 404 on missing keys' do
      with_api(Mneme, api_options) do
        get_request({:query => {:key => ['a', 'b']}}, err) do |c|
          c.response_header.status.should == 404

          c.response['found'].should be_empty
          c.response['missing'].should include 'a'
          c.response['missing'].should include 'b'
        end
      end
    end

    it 'should return 200 on found keys' do
      with_api(Mneme, api_options) do
        post_request({:query => {key: ['abc1', 'abc2']}}) do |c|
          c.response_header.status.should == 201

          get_request({:query => {:key => ['abc1', 'abc2']}}, err) do |c|
            c.response_header.status.should == 200
          end
        end
      end
    end

    it 'should return 206 on mixed keys' do
      with_api(Mneme, api_options) do
        post_request({:query => {key: ['abc3']}}) do |c|
          c.response_header.status.should == 201

          get_request({:query => {:key => ['abc3', 'abc4']}}, err) do |c|
            c.response_header.status.should == 206
          end
        end
      end
    end

  end

end
