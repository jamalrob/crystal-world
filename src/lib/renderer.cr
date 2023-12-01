module CrystalWorld::TemplateRenderer
  extend self

  def render_and_out(
    ctx : HTTP::Server::Context,
    data : Hash,
    template_path : String
  )
    if LOCAL
      # In development, get a fresh string to append
      # to static file URLs on every request
      data.put("cachebust", Time.monotonic.to_s.split(".")[-1]) { "update" }
    else
      # Or, for production, use the value generated
      # at compile time
      data.put("cachebust", CACHEBUST) { "update" }
    end
    if ctx.request.cookies.has_key?("csrftoken")
      data.put("csrftoken", ctx.request.cookies["csrftoken"].value) { "update" }
    end
    if !data.has_key?("user_authenticated")
      u = Data.authenticated_user(ctx)
      if u
        data.put("user_authenticated", "true") { "update" }
      end
    end
    tengine = Crinja.new
    tengine.loader = Crinja::Loader::FileSystemLoader.new(TEMPLATE_FOLDER)
    template = tengine.get_template(template_path)
    final_html = template.render(data)
    ctx.response.print final_html
  end

  def render_basic(
    ctx : HTTP::Server::Context,
    template_path : String
  )
    tengine = Crinja.new
    tengine.loader = Crinja::Loader::FileSystemLoader.new(TEMPLATE_FOLDER)
    template = tengine.get_template(template_path)
    final_html = template.render()
    ctx.response.print final_html
  end

end