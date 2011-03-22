module Mnemosyne
  module Helper
    def epoch(n, length)
      (Time.now.to_i / length) - n
    end

    def epoch_name(namespace, n, length)
      "mneme-#{namespace}-#{epoch(n, length)}"
    end
  end
end
