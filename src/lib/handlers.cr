module CrystalWorld

  class HttpHandler
      include HTTP::Handler

      def call(context)
          if context.request.path.starts_with?("/api/")
              context.response.content_type = "application/json"
              context.response.headers["Access-Control-Request-Headers"] = "Content-Type, application/json"
              context.response.headers["Access-Control-Allow-Origin"] = "http://127.0.0.1:8123"
              context.response.headers["Access-Control-Allow-Credentials"] = "true"
              context.response.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
              context.response.headers["Access-Control-Allow-Content-Type"] = "application/json"
              context.response.headers["Access-Control-Allow-Headers"] = "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With"
          else
              context.response.content_type = "text/html; charset=UTF-8"
          end
          call_next(context)
      end
  end

end