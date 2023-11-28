require "http/server"
require "./controllers.cr"
require "./lib/handlers.cr"

module CrystalWorld
  extend self

  server = HTTP::Server.new([
    HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
    HTTP::CompressHandler.new,
    CrystalWorld::HttpHandler.new,
  ]) do |ctx|

    puts "Request for #{ctx.request.path}"

    case ctx.request.path
    when "admin/signup"
      # Probably not implementing here
      # See dump
    when "/admin/login"
      Controllers.login_page(ctx)
    when "/admin/logout"
      Controllers.do_logout(ctx)
    when "/admin/login/auth"
      Controllers.do_login(ctx)
    when "/admin", "/admin/articles"
      Controllers.admin_articles(ctx)
    when .match(/\/admin\/edit\/[a-zA-Z0-9]/)
      Controllers.admin_edit_article(ctx)
    when "/"
      Controllers.home_page(ctx)
    when "/tags"
      Controllers.tags_page(ctx)
    when .index("/tag/")
      Controllers.tag_page(ctx)
    when "/about"
      Controllers.about_page(ctx)
    when .match(/[a-zA-Z0-9]/)
      Controllers.article_page(ctx)
    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
