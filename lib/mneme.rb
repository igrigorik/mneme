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
  LENGTH  = 10

  SIZE = 100
  BITS = 10
  HASHES = 7
  SEED   = 30

  NAMESPACE = 'mneme'

  def response(env)
    logger.info "Processing: #{params}"

    case env[Goliath::Request::REQUEST_METHOD]
      when 'GET' then
        query_filters(env)
      when 'POST' then
        update_filters(env)
    end
  end

  def query_filters(env)
    PERIODS.times do |n|
      if key = filter(n).key?(env.params['key'])
        return [200, {}, {response: 'found'}]
      end

      logger.info "#{n} - #{key}"
    end

    [404, {}, {response: 'not found'}]
  end

  def update_filters(env)
    filter(1).insert params['key']
    [201, {}, '']
  end

  private

    def filter(n)
      env["mneme-#{n}"] ||= BloomFilter::Redis.new(namespace: NAMESPACE, size: SIZE * BITS, seed: SEED, hashes: HASHES)
    end
end
