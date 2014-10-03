module Rpush
  module Daemon
    module Loggable
      def log_info(msg, inline = false)
        Rpush.logger.info(app_prefix(msg), inline)
      end

      def log_warn(msg, inline = false)
        Rpush.logger.warn(app_prefix(msg), inline)
      end

      def log_error(e, inline = false)
        if e.is_a?(Exception)
          Rpush.logger.error(e)
        else
          Rpush.logger.error(app_prefix(e), inline)
        end
      end

      private

      def app_prefix(msg)
        app = instance_variable_get('@app')
        msg = "[#{app.name}] #{msg}" if app
        msg
      end
    end
  end
end
