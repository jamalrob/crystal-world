require "http/client"
require "markd"
require "front_matter"
require "poncho"
require "crinja"
require "crystal-argon2"
require "http/server"
require "sqlite3"
require "./*"
require "./lib/*"

module CrystalWorld
  extend self

  @@env : Poncho::Parser
  @@env = Poncho.from_file ".env"
  IMGBUCKET = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
  SLUG_PATTERN = "[a-z0-9]+(?:[_-][a-z0-9]+)*"
  LOCAL     = @@env["ENV"] == "local"
  CACHEBUST = Time.monotonic.to_s.split(".")[-1]
  TEMPLATE_FOLDER = "src/templates/"

  server = HTTP::Server.new([
    HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
    HTTP::CompressHandler.new,
    CrystalWorld::HttpHandler.new,
  ]) do |ctx|

    puts "Request for #{ctx.request.path}"

    case ctx.request.path

    when "/"
      PublicControllers.home_page(ctx)

    when "/tags"
      PublicControllers.tags_page(ctx)

    when .starts_with? "/tag/"
      PublicControllers.tag_page(ctx)

    when "/about"
      PublicControllers.about_page(ctx)

    when "/admin/signup"
      # Probably not implementing here / see dump

    when "/admin/login"
      PublicControllers.login_page(ctx)

    when "/admin/logout"
      AuthControllers.do_logout(ctx)

    when "/admin/login/auth"
      AuthControllers.do_login(ctx)

    when "/admin", "/admin/articles"
      AdminControllers.admin_articles(ctx)

    when "/admin/pages"
      AdminControllers.admin_pages(ctx)

    when "/admin/customize"
      AdminControllers.admin_customize(ctx)

    when "/admin/authors"
      AdminControllers.admin_authors(ctx)

    when "/admin/settings"
      AdminControllers.admin_settings(ctx)

    when "/admin/markdown-cheatsheet"
      AdminControllers.admin_markdown_cheatsheet(ctx)

    when .starts_with? "/api/save_sidebar_state"
      AdminControllers.save_sidebar_state(ctx)

    when .match /^\/admin\/article\/#{SLUG_PATTERN}\/publish$/
      AdminControllers.publish_article(ctx)

    when .match /^\/admin\/article\/#{SLUG_PATTERN}\/unpublish$/
      AdminControllers.unpublish_article(ctx)

    when .match /^\/admin\/edit\/#{SLUG_PATTERN}\/preview$/
      AdminControllers.get_preview_html(ctx)

    when .match /^\/admin\/#{SLUG_PATTERN}\/properties$/
      AdminControllers.article_properties(ctx)

    when .match /^\/admin\/#{SLUG_PATTERN}\/publish$/
      AdminControllers.save_article(ctx)

    when .match /^\/admin\/#{SLUG_PATTERN}\/unpublish$/
      AdminControllers.save_article(ctx)

    when .match /^\/admin\/#{SLUG_PATTERN}\/save_draft$/
      AdminControllers.save_article(ctx)

    when .match /^\/admin\/edit\/#{SLUG_PATTERN}$/
      AdminControllers.edit_article_page(ctx)

    #when .match /^\/admin\/edit\/#{SLUG_PATTERN}\/preview$/
    #  Controllers.admin_edit_preview(ctx)

    when .match /^\/#{SLUG_PATTERN}$/
      PublicControllers.article_page(ctx)

    else
      Controllers.error_404(ctx)

    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
