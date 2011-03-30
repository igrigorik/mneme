require 'goliath'
require 'yajl'

require 'redis'
require 'redis/connection/synchrony'
require 'bloomfilter-rb'

require 'mneme/helper'
require 'mneme/sweeper'

class Mneme < Goliath::API
  include Mnemosyne::Helper
  plugin Mnemosyne::Sweeper

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

    def filter(n)
      period = epoch_name(config['namespace'], n, config['length'])

      filter = if env[Goliath::Constants::CONFIG].key? period
        env[Goliath::Constants::CONFIG][period]
      else
        opts = {
          namespace: config['namespace'],
          size: config['size'] * config['bits'],
          seed: config['seed'],
          hashes: config['hashes']
        }

        pool = config['pool'] || 1
        env[Goliath::Constants::CONFIG][period] = EventMachine::Synchrony::ConnectionPool.new(size: pool) do
          BloomFilter::Redis.new(opts)
        end
      end

      filter
    end
end
