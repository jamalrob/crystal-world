require "http/server"
require "ecr"
require "markd"
require "front_matter"
require "poncho"
require "sqlite3"
require "./datalib.cr"
require "./front_matter_parser.cr"

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
            content = ECR.render("src/templates/home.ecr")
            self.render_and_out(context, "The Crystal World", content)
        when "/tags"
            # get tags from a tags table
        when "/about"
            content = ECR.render("src/templates/about.ecr")
            self.render_and_out(context, "About me", content)
        when .match(/[a-zA-Z]/)
            urlbits = context.request.path.split('/', limit: 2, remove_empty: true)
            resource = urlbits[0]?
            article = DataLib.get_article(resource)
            if article
                options = Markd::Options.new(smart: true, safe: true)
                html = Markd.to_html(article["md"].as(String), options)
                article["html"] = html.gsub("/bucket/", imgbucket)
                content = ECR.render "src/templates/components/article.ecr"
                self.render_and_out(context, article["title"], content)
            else
                context.response.status = HTTP::Status.new(404)
                content = "Sorry about that."
                self.render_and_out(
                    context: context,
                    title: "Page not found",
                    content: content,
                    error_msg: "Page not found"
                )
            end
        end
    end

    def self.render_and_out(context, title, content, error_msg=nil)
        header = ECR.render "src/templates/components/header.ecr"
        populated_layout = ECR.render "src/templates/layouts/base.ecr"
        context.response.content_type = "text/html; charset=UTF-8"
        context.response.print populated_layout
    end

    # RUN SERVER
    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end