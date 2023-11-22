require "http/server"
require "ecr"
require "markd"
require "poncho"

poncho = Poncho.from_file ".env"
#val = poncho["SECRET"]

module CrystalWorld

    macro render_template(ctx, page_template, title, html="")
        page_title = {{title}}
        if {{html}} == ""
            content = ECR.render({{page_template}})
        else
            content = {{html}}
        end
        header = ECR.render "src/templates/components/header.ecr"
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
            render_template ctx, "src/templates/home.ecr", "The Crystal World"
        when "/tags"
            #
        when "/about"
            render_template(ctx, "src/templates/about.ecr", "About me")
        else
            urlbits = ctx.request.path.split('/', limit: 2, remove_empty: true)
            resource    = urlbits[0]?

            md = File.read("content/#{resource}.md")
            options = Markd::Options.new(smart: true, safe: true)
            html = Markd.to_html(md, options)
            render_template ctx, "src/templates/home.ecr", "The Crystal World", html: html

        end
    end

    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end