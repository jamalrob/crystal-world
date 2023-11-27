module CrystalWorld

  LOCAL     = @@env["ENV"] == "local" || false
  CACHEBUST = Time.monotonic.to_s.split(".")[-1]

  module TemplateRenderer
    extend self

    def render_and_out(ctx : HTTP::Server::Context, data : Hash, template_path : String)
      if LOCAL
        # In development, get a fresh string to append
        # to static file URLs on every request
        data.put("cachebust", Time.monotonic.to_s.split(".")[-1]) { "update" }
      else
        # Or, for production, use the value generated
        # at compile time
        data.put("cachebust", CACHEBUST) { "update" }
      end
      tengine = Crinja.new
      tengine.loader = Crinja::Loader::FileSystemLoader.new("src/templates/")
      template = tengine.get_template(template_path)
      final_html = template.render(data)
      ctx.response.content_type = "text/html; charset=UTF-8"
      ctx.response.print final_html
    end

  end
end