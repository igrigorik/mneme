require 'goliath'
require 'yajl'

require 'redis'
require 'redis/connection/synchrony'
require 'bloomfilter-rb'

class Mneme < Goliath::API
  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Render
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::ValidationError

  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)

  def response(env)
    keys = [params.delete('key') || params.delete('key[]')].flatten.compact
    return [400, {}, {error: 'no key specified'}] if keys.empty?

    logger.debug "Processing: #{keys}"
    case env[Goliath::Request::REQUEST_METHOD]
      when 'GET'  then query_filters(keys)
      when 'POST' then update_filters(keys)
    end
  end

  def query_filters(keys)
    found, missing = [], []
    keys.each do |key|

      present = false
      config['periods'].to_i.times do |n|
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
    keys.each do |key|
      filter(0).insert key
      logger.debug "Inserted new key: #{key}"
    end

    [201, {}, '']
  end

  private

    def epoch(n)
      (Time.now.to_i / config['length']) - n
    end

    def filter(n)
      period = "mneme-#{config['namespace']}-#{epoch(n)}"

      filter = if env.key? period
        env[period]
      else
        opts = {
          namespace: config['namespace'],
          size: config['size'] * config['bits'],
          seed: config['seed'],
          hashes: config['hashes']
        }

        # env[period] = EventMachine::Synchrony::ConnectionPool.new(size: 10) do
        env[period] = BloomFilter::Redis.new(opts)
        # end

        env[period]
      end

      filter
    end
end