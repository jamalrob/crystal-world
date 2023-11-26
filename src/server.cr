require "http/server"
require "./controllers.cr"

module CrystalWorld
  extend self

  server = HTTP::Server.new([
    HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
    HTTP::CompressHandler.new,
  ]) do |ctx|

    # DEV
    puts "REQUEST at " + Time.local.to_s("%H:%M:%S")

    # ---------------------
    # ROUTES
    # ---------------------

    case ctx.request.path
    when "admin/signup"
      # Probably not implementing here
      # See dump
    when "/admin/login"
      Controllers.login_page(ctx)
    when "/admin/login/auth"
      Controllers.do_login(ctx)
    when "/admin/dashboard"
      Controllers.admin_dashboard(ctx)
    when "/"
      Controllers.home_page(ctx)
    when "/tags"
      Controllers.tags_page(ctx)
    when .index("/tag/")
      Controllers.tag_page(ctx)
    when "/about"
      Controllers.about_page(ctx)
    when .match(/[a-zA-Z]/)
      Controllers.article_page(ctx)
    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
