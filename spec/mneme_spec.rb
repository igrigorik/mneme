require 'lib/mneme'
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

  it 'should require an error if no key is provided' do
    with_api(Mneme) do
      get_request({}, err) do |c|
        b = Yajl::Parser.parse(c.response)
        b.should include 'error'
      end
    end
  end

  context 'single key' do
    it 'should return 404 on missing key' do
      with_api(Mneme) do
        get_request({:query => {:key => 'missing'}}, err) do |c|
          c.response_header.status.should == 404
          b = Yajl::Parser.parse(c.response)
          b['missing'].should include 'missing'
        end
      end
    end

    it 'should insert key into filter' do
      with_api(Mneme) do
        post_request({:query => {key: 'abc'}}) do |c|
          c.response_header.status.should == 201

          get_request({:query => {:key => 'abc'}}, err) do |c|
            c.response_header.status.should == 200
            b = Yajl::Parser.parse(c.response)
            b['found'].should include 'abc'
          end
        end
      end
    end
  end

  context 'multiple keys' do

    it 'should return 404 on missing keys' do
      with_api(Mneme) do
        get_request({:query => {:key => ['a', 'b']}}, err) do |c|
          c.response_header.status.should == 404
          b = Yajl::Parser.parse(c.response)

          b['found'].should be_empty
          b['missing'].should include 'a'
          b['missing'].should include 'b'
        end
      end
    end

    it 'should return 200 on found keys' do
      with_api(Mneme) do
        post_request({:query => {key: ['abc1', 'abc2']}}) do |c|
          c.response_header.status.should == 201

          get_request({:query => {:key => ['abc1', 'abc2']}}, err) do |c|
            c.response_header.status.should == 200
          end
        end
      end
    end

    it 'should return 206 on mixed keys' do
      with_api(Mneme) do
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
