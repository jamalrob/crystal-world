require "http/server"
require "sqlite3"
require "markd"
require "front_matter"
require "poncho"
require "crinja"
require "crystal-argon2"
require "sanitize"
require "./controllers/*"
require "./*"

module CrystalWorld
  extend self

  @@env : Poncho::Parser
  @@env = Poncho.from_file ".env"
  IMGBUCKET       = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
  LOCAL           = @@env["ENV"] == "local"
  CACHEBUST       = Time.monotonic.to_s.split(".")[-1]
  TEMPLATE_FOLDER = "src/templates/"
  SLUG_PATTERN    = "[a-z0-9-]+"

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

    when .match /\/tag\/#{SLUG_PATTERN}$/
      PublicControllers.tag_page(ctx)

    when "/about"
      PublicControllers.about_page(ctx)

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

    when .match /^\/api\/save_sidebar_state\/[a-z]*$/
      AdminControllers.save_sidebar_state(ctx)

    when .match /^\/admin\/articles\/new$/
      AdminControllers.new_article_page(ctx)

    when .match /^\/admin\/articles\/#{SLUG_PATTERN}\/delete$/
      AdminControllers.delete_article(ctx)

    when .match /^\/api\/admin\/articles\/#{SLUG_PATTERN}\/publish$/
      AdminControllers.publish_article(ctx)

    when .match /^\/admin\/validate_date$/
      AdminControllers.validate_date_inline(ctx)

    when .match /^\/admin\/validate_slug$/
      AdminControllers.validate_slug_inline(ctx)

    when .match /^\/admin\/articles\/#{SLUG_PATTERN}\/unpublish$/
      AdminControllers.unpublish_article(ctx)

    when .match /^\/admin\/articles\/#{SLUG_PATTERN}\/preview$/
      AdminControllers.get_preview_html(ctx)

    when .match /^\/admin\/articles\/#{SLUG_PATTERN}\/properties$/
      AdminControllers.article_properties(ctx)

    when .match /^\/admin\/articles\/#{SLUG_PATTERN}\/edit$/
      AdminControllers.edit_article_page(ctx)

    when .match /^\/#{SLUG_PATTERN}$/
      PublicControllers.article_page(ctx)

    else
      PublicControllers.error_404(ctx)

    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
