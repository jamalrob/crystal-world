require "http/server"
require "base64"
require "json"
require "mime"
require "sqlite3"
require "markd"
require "front_matter"
require "poncho"
require "crest"
require "crinja"
require "crystal-argon2"
require "sanitize"
require "email"

require "./controllers/*"
require "./data/*"
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
  FILENAME_PATTERN      = "[\w\-. ]+"
  TEMP_IMAGES_FOLDER    = @@env["TEMP_IMAGES_FOLDER"]

  server = HTTP::Server.new([
    HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
    HTTP::CompressHandler.new,
    CrystalWorld::HttpHandler.new,
  ]) do |ctx|
    puts "Request for #{ctx.request.path}"

    case ctx.request.path
    when "/"
      Controllers::Public.home(ctx)

    when "/tags"
      Controllers::Public.tags(ctx)

    when .match /\/tag\/#{SLUG_PATTERN}$/
      Controllers::Public.tag(ctx)

    when "/about"
      Controllers::Public.about(ctx)

    when "/admin/login"
      Controllers::Public.login(ctx)

    when "/admin/register"
      Controllers::Public.register(ctx)

    when "/admin/logout"
      Controllers::Auth.do_logout(ctx)

    when "/admin/login/auth"
      Controllers::Auth.do_login(ctx)

    when "/admin/register/auth"
      Controllers::Auth.do_register(ctx)

    when "/admin", "/admin/articles"
      Controllers::Admin.articles(ctx)

    when "/admin/pages"
      Controllers::Admin.pages(ctx)

    when "/admin/customize"
      Controllers::Admin.customize(ctx)

    when "/admin/authors"
      Controllers::Admin.authors(ctx)

    when "/admin/settings"
      Controllers::Admin.settings(ctx)

    when "/admin/images"
      Controllers::Admin.images(ctx)

    when "/admin/bin"
      Controllers::Admin.bin(ctx)

    when "/admin/markdown-cheatsheet"
      Controllers::Admin.markdown_cheatsheet(ctx)

    when .match /^\/api\/save_sidebar_state\/[a-z]*$/
      Controllers::Admin.save_sidebar_state(ctx)

    when .match /^\/admin\/articles\/new$/
      Controllers::Admin.new_article_page(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/delete$/
      Controllers::Admin.delete_article(ctx)

    when .match /^\/api\/admin\/articles\/#{ID_PATTERN}\/publish$/
      Controllers::Admin.publish_article(ctx)

    when .match /^\/admin\/validate_date$/
      Controllers::Admin.validate_date_inline(ctx)

    when .match /^\/admin\/validate_slug$/
      Controllers::Admin.validate_slug_inline(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/unpublish$/
      Controllers::Admin.unpublish_article(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/preview$/
      Controllers::Admin.get_preview_html(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/properties$/
      Controllers::Admin.article_properties(ctx)

    when .match /^\/admin\/articles\/#{ID_PATTERN}\/edit$/
      Controllers::Admin.edit_article_page(ctx)

    when .starts_with? "/admin/get_image"
      # Currently not used
      Controllers::Admin.get_image(ctx)

    when "/admin/images/get"
      Controllers::Admin.get_images(ctx)

    when "/admin/images/upload"
      Controllers::Admin.upload_image(ctx)

    when "/admin/authors/new"
      Controllers::Admin.new_author_form(ctx)

    when .match /^\/#{SLUG_PATTERN}$/
      Controllers::Public.article(ctx)

    else
      Controllers::Public.error_404(ctx)

    end
  end

  address = server.bind_tcp 8123
  puts "Listening on http://#{address}"
  server.listen
end
