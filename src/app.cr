require "http/server"
require "ecr"
require "markd"
require "front_matter"
require "poncho"

poncho = Poncho.from_file ".env"
imgbucket = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-80/"
#val = poncho["SECRET"]

module CrystalWorld

    def self.get_value(fm, name)
        find = "#{name}:"
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

    macro render_article(ctx, page_template, title, html)
        article = {{html}}
        title = {{title}}
        header = ECR.render "src/templates/components/header.ecr"
        content = ECR.render "src/templates/components/article.ecr"
        populated_layout = ECR.render "src/templates/layouts/base.ecr"
        ctx.response.content_type = "text/html; charset=UTF-8"
        ctx.response.print populated_layout
    end


    server = HTTP::Server.new([
        HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
        HTTP::CompressHandler.new,
    ]) do |ctx|
        case ctx.request.path
        when "/"
            d = Dir.new("content")
            files = d.each_child
            render ctx, "src/templates/home.ecr", "The Crystal World"
        when "/tags"
            #
        when "/about"
            render ctx, "src/templates/about.ecr", "About me"
        when .match(/[a-zA-Z]/)
            urlbits = ctx.request.path.split('/', limit: 2, remove_empty: true)
            resource    = urlbits[0]?
            FrontMatter.open("content/#{resource}.md", skip_newlines: false) { |front_matter, content_io|
                fm = parse_frontmatter(front_matter)
                md = content_io.gets_to_end.as(String)
                options = Markd::Options.new(smart: true, safe: true)
                html = Markd.to_html(md, options).gsub("/bucket/", imgbucket)
                render_article ctx, "src/templates/home.ecr", fm["title"], html
            }

        end
    end

    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end