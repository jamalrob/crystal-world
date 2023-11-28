require "http/server"
require "./controllers.cr"
require "./lib/handlers.cr"

module CrystalWorld
  extend self

  SLUG_PATTERN = "[a-z0-9]+(?:[_-][a-z0-9]+)*"

  server = HTTP::Server.new([
    HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
    HTTP::CompressHandler.new,
    CrystalWorld::HttpHandler.new,
  ]) do |ctx|

    puts "Request for #{ctx.request.path}"

    case ctx.request.path
    when "/"
      Controllers.home_page ctx
    when "/tags"
      Controllers.tags_page ctx
    when .index "/tag/"
      Controllers.tag_page ctx
    when "/about"
      Controllers.about_page ctx
    when "admin/signup"
      # Probably not implementing here / see dump
    when "/admin/login"
      Controllers.login_page ctx
    when "/admin/logout"
      Controllers.do_logout ctx
    when "/admin/login/auth"
      Controllers.do_login ctx
    when "/admin", "/admin/articles"
      Controllers.admin_articles ctx
    when "/admin/pages"
      Controllers.admin_pages ctx
    when "/admin/customize"
      Controllers.admin_customize ctx
    when "/admin/authors"
      Controllers.admin_authors ctx
    when "/admin/settings"
      Controllers.admin_settings ctx
    when .match /^\/admin\/edit\/#{SLUG_PATTERN}$/
      Controllers.admin_edit_article ctx
    when .match /^\/admin\/edit\/#{SLUG_PATTERN}\/preview$/
      Controllers.admin_edit_preview ctx
    when .match /^\/#{SLUG_PATTERN}$/
      Controllers.article_page ctx
    else
      Controllers.error_404 ctx
    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
