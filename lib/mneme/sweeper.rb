module Mnemosyne
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