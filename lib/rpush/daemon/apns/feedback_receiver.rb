module Rpush
  module Daemon
    module Apns
      class FeedbackReceiver
        include Reflectable
        include Loggable

        TUPLE_BYTES = 38
        HOSTS = {
          production: ['feedback.push.apple.com', 2196],
          development: ['feedback.sandbox.push.apple.com', 2196], # deprecated
          sandbox: ['feedback.sandbox.push.apple.com', 2196]
        }

        def initialize(app)
          @app = app
          @host, @port = HOSTS[@app.environment.to_sym]
          @certificate = app.certificate
          @password = app.password
          @interruptible_sleep = InterruptibleSleep.new(Rpush.config.feedback_poll)
        end

        def start
          return if Rpush.config.push
          log_info("APNs Feedback Receiver started.")
          @interruptible_sleep.start

          @thread = Thread.new do
            loop do
              break if @stop
              check_for_feedback
              @interruptible_sleep.sleep
            end

            Rpush::Daemon.store.release_connection
          end
        end

        def stop
          @stop = true
          @interruptible_sleep.stop
          @thread.join if @thread
        end

        def check_for_feedback
          connection = nil
          begin
            connection = Rpush::Daemon::TcpConnection.new(@app, @host, @port)
            connection.connect
            tuple = connection.read(TUPLE_BYTES)

            while tuple
              timestamp, device_token = parse_tuple(tuple)
              create_feedback(timestamp, device_token)
              tuple = connection.read(TUPLE_BYTES)
            end
          rescue StandardError => e
            log_error(e)
            reflect(:error, e)
          ensure
            connection.close if connection
          end
        end

        protected

        def parse_tuple(tuple)
          failed_at, _, device_token = tuple.unpack("N1n1H*")
          [Time.at(failed_at).utc, device_token]
        end

        def create_feedback(failed_at, device_token)
          formatted_failed_at = failed_at.strftime("%Y-%m-%d %H:%M:%S UTC")
          log_info("[FeedbackReceiver] Delivery failed at #{formatted_failed_at} for #{device_token}.")

          feedback = Rpush::Daemon.store.create_apns_feedback(failed_at, device_token, @app)
          reflect(:apns_feedback, feedback)
        end
      end
    end
  end
end
