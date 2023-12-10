require "http/server"
require "base64"
require "json"
require "sqlite3"
require "markd"
require "front_matter"
require "poncho"
require "crest"
require "crinja"
require "crystal-argon2"
require "sanitize"
require "./controllers/*"
require "./*"

module CrystalWorld
  extend self

  @@env : Poncho::Parser
  @@env = Poncho.from_file ".env"
  IMGBUCKET             = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
  LOCAL                 = @@env["ENV"] == "local"
  IMAGEKIT_URL_ENDPOINT = @@env["IMAGEKIT_URL_ENDPOINT"]
  IMAGEKIT_PRIVATE_KEY  = @@env["IMAGEKIT_PRIVATE_KEY"]
  CACHEBUST             = Time.monotonic.to_s.split(".")[-1]
  TEMPLATE_FOLDER       = "src/templates/"
  SLUG_PATTERN          = "[a-z0-9-]+"
  ID_PATTERN            = "[0-9]+"

  server = HTTP::Server.new([
    HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
    HTTP::CompressHandler.new,
    CrystalWorld::HttpHandler.new,
  ]) do |ctx|
    puts "Request for #{ctx.request.path}"

    case ctx.request.path
    when "/"
      PublicControllers.home(ctx)

    when "/tags"
      PublicControllers.tags(ctx)

    when .match /\/tag\/#{SLUG_PATTERN}$/
      PublicControllers.tag(ctx)

    when "/about"
      PublicControllers.about(ctx)

    when "/admin/login"
      PublicControllers.login(ctx)

    when "/admin/logout"
      AuthControllers.do_logout(ctx)

    when "/admin/login/auth"
      AuthControllers.do_login(ctx)

    when "/admin", "/admin/articles"
      AdminControllers.articles(ctx)

    when "/admin/pages"
      AdminControllers.pages(ctx)

    when "/admin/customize"
      AdminControllers.customize(ctx)

    when "/admin/authors"
      AdminControllers.authors(ctx)

    when "/admin/settings"
      AdminControllers.settings(ctx)

    when "/admin/images"
      AdminControllers.images(ctx)

    when "/admin/bin"
      AdminControllers.bin(ctx)

    when "/admin/markdown-cheatsheet"
      AdminControllers.markdown_cheatsheet(ctx)

    when .match /^\/api\/save_sidebar_state\/[a-z]*$/
      AdminControllers.save_sidebar_state(ctx)

    when .match /^\/admin\/articles\/new$/
      AdminControllers.new_article_page(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/delete$/
      AdminControllers.delete_article(ctx)

    when .match /^\/api\/admin\/articles\/#{ID_PATTERN}\/publish$/
      AdminControllers.publish_article(ctx)

    when .match /^\/admin\/validate_date$/
      AdminControllers.validate_date_inline(ctx)

    when .match /^\/admin\/validate_slug$/
      AdminControllers.validate_slug_inline(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/unpublish$/
      AdminControllers.unpublish_article(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/preview$/
      AdminControllers.get_preview_html(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/properties$/
      AdminControllers.article_properties(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/edit$/
      AdminControllers.edit_article_page(ctx)

    when .match /^\/#{SLUG_PATTERN}$/
      PublicControllers.article(ctx)

    else
      PublicControllers.error_404(ctx)

    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
