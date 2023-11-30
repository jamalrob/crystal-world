module CrystalWorld::Controllers
  extend self

  def error_404(ctx)
    ctx.response.status = HTTP::Status.new(404)
    TemplateRenderer.render_and_out ctx: ctx,
      data: {
        "error_msg" => "Page not found",
      },
      template_path: "errors/404.html"
  end

end