require File.join(File.dirname(__FILE__), '../lib/', 'mneme')
require 'goliath/test_helper'

describe Mneme do
  include Goliath::TestHelper

  let(:err) { Proc.new { fail "API request failed" } }

  it 'responds to hearbeat' do
    with_api(Mneme) do
      get_request({path: '/status'}, err) do |c|
        c.response.should match('OK')
      end
    end
  end

  it 'should return 404 on missing key' do
    with_api(Mneme) do
      get_request({:query => {:key => 'missing2'}}, err) do |c|
        c.response_header.status.should == 404
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'not found'
      end
    end
  end

  it 'should insert key into bloomfilter' do
    with_api(Mneme) do
      post_request({:body => {key: 'abc'}}, err) do |c|
        c.response_header.status.should == 201

        get_request({:query => {:key => 'abc'}}, err) do |c|
          c.response_header.status.should == 200
          b = Yajl::Parser.parse(c.response)
          b['response'].should == 'found'
        end

      end
    end
  end

end
