require "http/server"
require "http/client"
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

    def env
        return Poncho.from_file ".env"
    end

    IMGBUCKET = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
    LOCAL = env["ENV"] == "local" || false
    CACHEBUST = Time.monotonic.to_s().split(".")[-1]


    server = HTTP::Server.new([
        HTTP::StaticFileHandler.new(public_dir = "./public", fallthrough = true, directory_listing = false),
        HTTP::CompressHandler.new,
    ]) do |context|

        puts "REQUEST"

        # ---------------------
        # ROUTES
        # ---------------------
        case context.request.path

            when "/quicktestapi"
                username = ""
                if context.request.body
                    if hd = context.request.headers["Authorization"]?
                        credstring = hd.split("Basic ")[1]?
                        if credstring
                            creds = Base64.decode_string(credstring).split(":")
                            puts creds
                        end
                    end
                end
                context.response.status_code = 200
                #context.response.headers["HX-Redirect"] = "/about"
            when "/testapi"
                if hd = context.request.headers["Authorization"]?
                    credstring = hd.split("Basic ")[1]?
                    if credstring
                        creds = Base64.decode_string(credstring).split(":")
                        if creds[0] == env["USERNAME"] && creds[1] == env["PASSWORD"]
                            context.response.status_code = 200
                            context.response.print "ok"
                            context.response.headers["HX-Redirect"] = "/about"
                            context.response.redirect "/admin"
                            next
                        end
                    end
                end
                context.response.status_code = 401
                context.response.headers["WWW-Authenticate"] = "Basic realm=\"Login Required\""


                #context.response.content_type = "application/json"
                #context.response.headers["Access-Control-Request-Headers"] = "Content-Type, application/json"
                #context.response.headers["Access-Control-Allow-Origin"] = "http://127.0.0.1:8080"
                #context.response.headers["Access-Control-Allow-Credentials"] = "true"
                #context.response.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
                #context.response.headers["Access-Control-Allow-Content-Type"] = "application/json"
                #context.response.headers["Access-Control-Allow-Headers"] = "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With"

                #if context.request.method == "POST"# && context.request.headers["HX-Request"]?
                #    context.response.status_code = 200
                #    context.response.print json_text = %({"status": "ok"})
                #end

                #next



            when "/admin/login"
                # The login page
                puts "admin/login"
                self.render_and_out(
                    context: context,
                    data: {
                        "title" => "Sign in to admin"
                    },
                    template: "admin/login.html"
                )
            when "/admin/login/auth"
                # The API authentication route

                context.response.content_type                                   = "application/json"
                context.response.headers["Access-Control-Request-Headers"]      = "Content-Type, application/json"
                context.response.headers["Access-Control-Allow-Origin"]         = "http://127.0.0.1:8080"
                context.response.headers["Access-Control-Allow-Credentials"]    = "true"
                context.response.headers["Access-Control-Allow-Methods"]        = "POST, GET, OPTIONS"
                context.response.headers["Access-Control-Allow-Content-Type"]   = "application/json"
                context.response.headers["Access-Control-Allow-Headers"]        = "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With"

                if hd = context.request.headers["Authorization"]?
                    credstring = hd.split("Basic ")[1]?
                    if credstring
                        creds = Base64.decode_string(credstring).split(":")
                        if creds[0] == env["USERNAME"] && creds[1] == env["PASSWORD"]
                            context.response.status_code = 200
                            context.response.print "ok"
                            context.response.redirect "/admin"
                            next
                        end
                    end
                end
                context.response.status_code = 401
                context.response.headers["WWW-Authenticate"] = "Basic realm=\"Login Required\""
            when "/admin"
                # Admin dashboard
            when "/createarticle"
                #headers = HTTP::Headers.new
                if hd = context.request.headers["Authorization"]?
                    credstring = hd.split("Basic ")[1]?
                    if credstring
                        creds = Base64.decode_string(credstring).split(":")
                        if creds[0] == env["USERNAME"] && creds[1] == env["PASSWORD"]
                            context.response.status_code = 200
                            self.render_and_out(
                                context: context,
                                data: {
                                    "title" => "About me"
                                },
                                template: "about.html"
                            )
                            next
                        end
                    end
                end
                context.response.status_code = 401
                context.response.headers["WWW-Authenticate"] = "Basic realm=\"Login Required\""
                self.render_and_out(
                    context: context,
                    data: {
                        "error_msg" => "Login required"
                    },
                    template: "errors/401.html"
                )
            when "/"
                articles = DataLib.get_articles
                self.render_and_out(
                    context: context,
                    data: {
                        "articles" => articles,
                        "title" => "My Crystal World"
                    },
                    template: "home.html"
                )

            when "/tags"
                tags = DataLib.get_tags
                self.render_and_out(
                    context: context,
                    data: {
                        "tags" => tags,
                        "title" => "Tags"
                    },
                    template: "tags.html"
                )

            when .index("/tag/")
                urlbits = context.request.path.split('/', limit: 3, remove_empty: true)
                tag = urlbits[1]?
                articles = DataLib.get_articles_for_tag(tag)
                if !articles.empty?
                    self.render_and_out(
                        context: context,
                        data: {
                            "articles" => articles,
                            "tag" => tag,
                            "title" => "Articles tagged with " + tag.to_s
                        },
                        template: "tag.html"
                    )
                else
                    context.response.status = HTTP::Status.new(404)
                    self.render_and_out(
                        context: context,
                        data: {
                            "error_msg" => "Nothing found for that tag",
                        },
                        template: "errors/404.html",
                    )
                end

            when "/about"
                self.render_and_out(
                    context: context,
                    data: {
                        "title" => "About me"
                    },
                    template: "about.html"
                )

            when .match(/[a-zA-Z]/)
                puts ".match(/[a-zA-Z]/)"
                urlbits = context.request.path.split('/', limit: 2, remove_empty: true)
                slug = urlbits[0]?
                article = DataLib.get_article(slug: slug)
                if article
                    options = Markd::Options.new(smart: true, safe: true)
                    html = Markd.to_html(article["md"].as(String), options)
                    article["html"] = html.gsub("/bucket/", IMGBUCKET)
                    self.render_and_out(
                        context: context,
                        data: {
                            "article" => article,
                            "title" => article["title"],
                        },
                        template: "article.html",
                    )
                else
                    context.response.status = HTTP::Status.new(404)
                    self.render_and_out(
                        context: context,
                        data: {
                            "error_msg" => "Page not found",
                        },
                        template: "errors/404.html",
                    )
                end
        end # case
    end

    def render_and_out(context, data, template)
        if LOCAL
            # In development, get a fresh string to append
            # to static file URLs on every request
            data.put("cachebust", Time.monotonic.to_s().split(".")[-1]) {"update"}
        else
            # Or, for production, use the value generated
            # at compile time
            data.put("cachebust", CACHEBUST) {"update"}
        end
        tengine = Crinja.new
        tengine.loader = Crinja::Loader::FileSystemLoader.new("src/templates/")
        template = tengine.get_template(template)
        final_html = template.render(data)
        context.response.content_type = "text/html; charset=UTF-8"
        context.response.print final_html
    end

    address = server.bind_tcp 8080
    puts "Listening on http://#{address}"
    server.listen

end