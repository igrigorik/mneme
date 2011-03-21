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

  def options_parser(opts, options)
    options['mneme'] = {
      'namespace' => 'default',

      'periods' => 3,
      'length'  => 60,

      'size'    => 1000,
      'bits'    => 10,
      'hashes'  => 7,
      'seed'    => 30
    }

    opts.on('-c', '--config FILE', "mneme configuration file") do |val|
      options['mneme'].merge! Yajl::Parser.parse(IO.read(val))
    end
  end

  def response(env)
    keys = [params.delete('key') || params.delete('key[]')].flatten.compact
    return [400, {}, {error: 'no key specified'}] if keys.empty?

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
      options['mneme']['periods'].to_i.times do |n|
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
    keys.each { |key| filter(0).insert key }
    [201, {}, '']
  end

  private

    def filter(n)
      period = (Time.now.to_i / options['mneme']['length'].to_i) - n
      period = "mneme-#{options['mneme']['namespace']}-#{period}"

      filter = if env.key? period
        env[period]
      else
        opts = {
          namespace: options['mneme']['namespace'],
          size: options['mneme']['size'].to_i * options['mneme']['bits'].to_i,
          seed: options['mneme']['seed'].to_i,
          hashes: options['mneme']['hashes'].to_i
        }

        env[period] = EventMachine::Synchrony::ConnectionPool.new(size: 10) do
          BloomFilter::Redis.new(opts)
        end

        env[period]
      end

      filter
    end
end
