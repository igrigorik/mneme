require 'goliath'
require 'bloomfilter-rb'
require 'yajl'

class Mneme < Goliath::API
  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Render
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::ValidationError

  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
  # use Goliath::Rack::Validation::RequiredParam, {:key => 'key'}

  PERIODS = 3
  LENGTH  = 10 # seconds

  SIZE = 100
  BITS = 10
  HASHES = 7
  SEED   = 30

  NAMESPACE = 'test'

  def response(env)
    keys = [params.delete('key') || params.delete('key[]')].flatten
    logger.info "Processing: #{keys}"

    case env[Goliath::Request::REQUEST_METHOD]
      when 'GET'  then query_filters(keys)
      when 'POST' then update_filters(keys)
    end
  end

  def query_filters(keys)
    found, missing = [], []
    keys.each do |key|

      present = false
      PERIODS.times do |n|
        if filter(n).key?(key)
          present = true
          break
        end
      end

      if present
        found << key
      else
        missing << key
      end
    end

    code = case keys.size
      when found.size then 200
      when missing.size then 404
      else 206
    end

    [code, {}, {found: found, missing: missing}]
  end

  def update_filters(keys)
    keys.each { |key| filter(1).insert key }
    [201, {}, '']
  end

  private

    def filter(n)
      period = (Time.now.to_i / LENGTH) - n
      period = "mneme-#{NAMESPACE}-#{period}"

      env[period] ||= BloomFilter::Redis.new(namespace: NAMESPACE, size: SIZE * BITS, seed: SEED, hashes: HASHES)
    end
end
