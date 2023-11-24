require "http/server"
require "ecr"
require "markd"
require "front_matter"
require "poncho"
require "sqlite3"
require "./datalib.cr"
require "./front_matter_parser.cr"
require "crinja"


poncho = Poncho.from_file ".env"
imgbucket = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"


module CrystalWorld

    server = HTTP::Server.new([
        HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
        HTTP::CompressHandler.new,
    ]) do |context|

        # ROUTES

        case context.request.path

        when "/createarticle"
            #
        when "/"
            articles = DataLib.get_articles
            data = {
                "articles" => articles,
                "title" => "My Crystal World",
            }
            self.render_and_out(context: context, data: data, template: "home.html")

        when "/tags"
            tags = DataLib.get_tags
            self.render_and_out(
                context: context,
                data: {
                    "tags" => tags,
                    "title" => "Tags",
                },
                template: "tags.html")

        when "/about"
            tags = DataLib.get_tags
            self.render_and_out(
                context: context,
                data: { "title" => "About me" },
                template: "about.html"
            )

        when .match(/[a-zA-Z]/)
            urlbits = context.request.path.split('/', limit: 2, remove_empty: true)
            resource = urlbits[0]?
            article = DataLib.get_article(resource)
            if article
                options = Markd::Options.new(smart: true, safe: true)
                html = Markd.to_html(article["md"].as(String), options)
                article["html"] = html.gsub("/bucket/", imgbucket)
                self.render_and_out(
                    context: context,
                    data: {
                        "article" => article,
                        "title" => article["title"],
                    },
                    template: "article.html"
                )
            else
                context.response.status = HTTP::Status.new(404)
                self.render_and_out(
                    context: context,
                    data: {"error_msg" => "Page not found"},
                    template: "errors/404.html"
                )
            end
        end
    end

    def self.render_and_out(context, data, template)
        tengine = Crinja.new
        tengine.loader = Crinja::Loader::FileSystemLoader.new("src/templates/")
        template = tengine.get_template(template)
        template.render(data)
        data.put("cachebust", Time.monotonic.to_s().split(".")[-1]) {"ok"}
        context.response.content_type = "text/html; charset=UTF-8"
        context.response.print template.render(data)
    end

    # RUN SERVER
    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end