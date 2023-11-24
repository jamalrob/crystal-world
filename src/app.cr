require "http/server"
require "ecr"
require "markd"
require "front_matter"
require "poncho"
require "sqlite3"
require "./datalib.cr"
require "./front_matter_parser.cr"
require "crinja"


module CrystalWorld
    extend self

    poncho = Poncho.from_file ".env"
    imgbucket = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"

    # Get a fresh string to append to static
    # file URLs on at least every compile
    cachebust = Time.monotonic.to_s().split(".")[-1]

    server = HTTP::Server.new([
        HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
        HTTP::CompressHandler.new,
    ]) do |context|

        is_running_local = poncho["ENV"] == "local" || false

        # ROUTES

        case context.request.path

        when "/createarticle"
            #
        when "/"
            articles = DataLib.get_articles
            self.render_and_out(
                context: context,
                data: {
                    "articles" => articles,
                    "title" => "My Crystal World",
                    "cachebust" => cachebust
                },
                template: "home.html",
                local: is_running_local
            )

        when "/tags"
            tags = DataLib.get_tags
            self.render_and_out(
                context: context,
                data: {
                    "tags" => tags,
                    "title" => "Tags",
                    "cachebust" => cachebust
                },
                template: "tags.html",
                local: is_running_local
            )

        when "/about"
            tags = DataLib.get_tags
            self.render_and_out(
                context: context,
                data: {
                    "title" => "About me",
                    "cachebust" => cachebust
                },
                template: "about.html",
                local: is_running_local
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
                        "cachebust" => cachebust
                    },
                    template: "article.html",
                    local: is_running_local
                )
            else
                context.response.status = HTTP::Status.new(404)
                self.render_and_out(
                    context: context,
                    data: {
                        "error_msg" => "Page not found",
                        "cachebust" => cachebust
                    },
                    template: "errors/404.html",
                    local: is_running_local
                )
            end
        end
    end

    def render_and_out(context, data, template, local=false)
        tengine = Crinja.new
        tengine.loader = Crinja::Loader::FileSystemLoader.new("src/templates/")
        template = tengine.get_template(template)
        template.render(data)

        if local
            # In development, get a fresh string to append
            # to static file URLs on every request
            data.put("cachebust", Time.monotonic.to_s().split(".")[-1]) {"update"}
        end

        context.response.content_type = "text/html; charset=UTF-8"
        context.response.print template.render(data)
    end

    # RUN SERVER
    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end