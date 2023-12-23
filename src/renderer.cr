module CrystalWorld::TemplateRenderer
  extend self

  private def _render(data, template_path)
    tengine = Crinja.new
    tengine.loader = Crinja::Loader::FileSystemLoader.new(TEMPLATE_FOLDER)
    template = tengine.get_template(template_path)
    template.render(data)
  end

  def render_page(
    ctx : HTTP::Server::Context,
    data : Hash,
    template_path : String
    )

    # CACHEBUSTER
    #
    if LOCAL
      # In development, get a fresh string to append
      # to static file URLs on every request
      data.put("cachebust", Time.monotonic.to_s.split(".")[-1]) { "update" }
      data.put("local", "true") { "update" }
    else
      # Or, for production, use the value generated
      # at compile time
      data.put("cachebust", CACHEBUST) { "update" }
    end

    # CSRF
    #
    if ctx.request.cookies.has_key?("csrftoken")
      data.put("csrftoken", ctx.request.cookies["csrftoken"].value) { "update" }
    end

    # USER
    #
    if !data.has_key?("user_authenticated")
      if u = Controllers::Admin.authenticated_user(ctx)
        data.put("user_authenticated", "true") { "update" }
      end
    end

    ctx.response.print self._render(data, template_path)

  end

  def render_basic(
    ctx : HTTP::Server::Context,
    data = nil,
    template_path : String = ""
    )
    # FOR PARTIALS, ERRORS, ETC

    ctx.response.print self._render(data, template_path)
  end

end