require "http/server"
require "ecr"
require "markd"
require "front_matter"
require "poncho"
require "sqlite3"
require "./datalib.cr"

poncho = Poncho.from_file ".env"
imgbucket = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
#val = poncho["SECRET"]

module CrystalWorld

    def self.get_value(fm, name)
        find = "#{name}:"
        if !fm.index(find)
            return nil
        end
        value_start = fm.index(find).as(Int32) + find.size
        value_end = fm.index("\n", offset: value_start)
        if !value_end.nil?
            value = fm[value_start..value_end].strip('\n').strip.strip('\'')
        end
        value
    end

    def self.parse_frontmatter(fm)
        title = self.get_value(fm, "title")
        date = self.get_value(fm, "date")
        tags = self.get_value(fm, "tags")
        image = self.get_value(fm, "image")
        imageclass = self.get_value(fm, "imageClass")

        parsed = {
            "title" => title,
            "date" => date,
            "tags" => tags,
            "image" => image,
            "imageclass" => imageclass,
        }
        parsed
    end

    macro render(ctx, page_template, title)
        title = {{title}}
        content = ECR.render({{page_template}})
        header = ECR.render "src/templates/components/header.ecr"
        populated_layout = ECR.render "src/templates/layouts/base.ecr"
        ctx.response.content_type = "text/html; charset=UTF-8"
        ctx.response.print populated_layout
    end

    def self.render_article(ctx, article)
        error_msg = nil
        content = ECR.render "src/templates/components/article.ecr"
        title = article["title"]
        header = ECR.render "src/templates/components/header.ecr"
        populated_layout = ECR.render "src/templates/layouts/base.ecr"
        ctx.response.content_type = "text/html; charset=UTF-8"
        ctx.response.print populated_layout
    end

    macro error(ctx, msg, status)
        title = {{msg}}
        error_msg = {{msg}}
        content = "Sorry about that."
        header = ECR.render "src/templates/components/header.ecr"
        populated_layout = ECR.render "src/templates/layouts/base.ecr"
        ctx.response.content_type = "text/html; charset=UTF-8"
        ctx.response.status = {{status}}
        ctx.response.print populated_layout
    end


    server = HTTP::Server.new([
        HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
        HTTP::CompressHandler.new,
    ]) do |ctx|

        error_msg = nil
        case ctx.request.path
        when "/createarticle"

            # TESTING DB CREATE ARTICLE
            # ONLY GETS THE DATA FROM A FILE FOR TESTING PURPOSES
            FrontMatter.open("content/sanatorium.md", skip_newlines: false) { |front_matter, content_io|
                fm = parse_frontmatter(front_matter)
                md = content_io.gets_to_end.as(String)
                #options = Markd::Options.new(smart: true, safe: true)
                #html = Markd.to_html(md, options).gsub("/bucket/", imgbucket)
                #render_article ctx, "src/templates/home.ecr", resource, fm["title"], html

                DataLib.create_article(
                    slug: "sanatorium",
                    title: fm["title"],
                    tags: fm["tags"],
                    date: "2023-10-23 00:00:00.000",
                    image: true,
                    imageClass: "",
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
            render ctx, "src/templates/home.ecr", "The Crystal World"
        when "/tags"
            #
        when "/about"
            render ctx, "src/templates/about.ecr", "About me"
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
                render_article ctx: ctx, article: article
            else
                error ctx, "Page not found", HTTP::Status.new(404)
            end
        end
    end

    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end