require "http/server"
require "ecr"
require "markd"
require "front_matter"
require "poncho"
require "sqlite3"
require "./datalib.cr"
require "./renderlib.cr"

poncho = Poncho.from_file ".env"
imgbucket = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
#val = poncho["SECRET"]

module CrystalWorld

    server = HTTP::Server.new([
        HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
        HTTP::CompressHandler.new,
    ]) do |ctx|

        case ctx.request.path
        when "/createarticle"

            # TESTING DB CREATE ARTICLE
            # ONLY GETS THE DATA FROM A FILE FOR TESTING PURPOSES
            FrontMatter.open("content/crash-by-jg-ballard.md", skip_newlines: false) { |front_matter, content_io|
                fm = RenderLib.parse_frontmatter(front_matter)
                md = content_io.gets_to_end.as(String)
                #options = Markd::Options.new(smart: true, safe: true)
                #html = Markd.to_html(md, options).gsub("/bucket/", imgbucket)
                #render_article ctx, "src/templates/home.ecr", resource, fm["title"], html

                DataLib.create_article(
                    slug: "crash-by-jg-ballard",
                    title: fm["title"],
                    tags: fm["tags"],
                    date: "2023-10-10 00:00:00.000",
                    image: true,
                    imageClass: "mainImageSmaller",
                    draft: true,
                    content: md
                )
            }
        when "/"
            # FOR FILES
            #d = Dir.new("content")
            #files = d.each_child
            #render ctx, "src/templates/home.ecr", "The Crystal World"

            # FOR DB
            articles = DataLib.get_articles
            RenderLib.render_page ctx, "src/templates/home.ecr", "The Crystal World"
        when "/tags"
            #
        when "/about"
            RenderLib.render_page ctx, "src/templates/about.ecr", "About me"
        when .match(/[a-zA-Z]/)
            urlbits = ctx.request.path.split('/', limit: 2, remove_empty: true)
            resource    = urlbits[0]?

            # USING DB:
            article = DataLib.get_article(resource)
            options = Markd::Options.new(smart: true, safe: true)
            if article
                md = article["md"].as(String)
                html = Markd.to_html(md, options).gsub("/bucket/", imgbucket)
                #render_article ctx: ctx, slug: resource, title: article["title"], html: html
                article["html"] = html
                RenderLib.render_article ctx: ctx, article: article
            else
                RenderLib.render_error ctx, "Page not found", HTTP::Status.new(404)
            end
        end
    end

    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end