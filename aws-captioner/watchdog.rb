# frozen_string_literal: true

class Watchdog
  NO_AUTO_RESTART_HOURS = ((0..9).to_a + (21..23).to_a).map { (_1 - 9).then { |jst|  jst < 0 ? 24+jst : jst } }

  def initialize(timeout: 1800, enabled: false)
    @timeout = timeout
    @last = Time.now.utc
    @enabled = enabled
  end

  attr_accessor :enabled

  def alive!
    @last = Time.now.utc
  end

  def start
    @th ||= Thread.new do
      loop do
        sleep 15
        now = Time.now.utc
        if (now - @last) > @timeout
          $stderr.puts "Watchdog engages!"
          next if NO_AUTO_RESTART_HOURS.include?(now.hour)
          if @enabled
            $stderr.puts "doggo shuts down this process"
            raise
          end
        end
      end
    end.tap { _1.abort_on_exception =  true }
  end
end
