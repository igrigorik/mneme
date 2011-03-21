require 'goliath'
require 'yajl'

require 'redis'
require 'redis/connection/synchrony'
require 'bloomfilter-rb'

module Mnemosyne
  module Helper
    def epoch(n, length)
      (Time.now.to_i / length) - n
    end

    def epoch_name(namespace, n, length)
      "mneme-#{namespace}-#{epoch(n, length)}"
    end
  end

  class Sweeper
    include Helper

    def initialize(port, config, status, logger)
      @status = status
      @config = config
      @logger = logger
    end

    def run
      config = @config
      logger = @logger

      sweeper = Proc.new do
        current = epoch_name(config['namespace'], 0, config['length'])
        logger.info "Sweeping old filters, current epoch: #{current}"

        conn = Redis.new
        config['periods'].times do |n|
          name = epoch_name(config['namespace'], n + config['periods'], config['length'])

          conn.del(name)
          logger.info "Removed: #{name}"
        end
        conn.client.disconnect
      end

      sweeper.call
      EM.add_periodic_timer(config['length']) { sweeper.call }

      @logger.info "Started Mnemosyne::Sweeper with #{@config['length']}s interval"
    end
  end
end

class Mneme < Goliath::API
  include Mnemosyne::Helper
  plugin Mnemosyne::Sweeper

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

    def filter(n)
      period = epoch_name(config['namespace'], n, config['length'])

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