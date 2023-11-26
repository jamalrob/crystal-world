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
    ]) do |ctx|

        puts "REQUEST at " + Time.local.to_s("%H:%M:%S")

        # ---------------------
        # ROUTES
        # ---------------------
        #p! ctx.request

        case ctx.request.path

            when "admin/signup"
                # Probably not implementing here
                # On successful signup:
                # sessionid = Random::Secure.hex(16)
                # csrf_token = Random::Secure.hex(16)
                # create database user
            when "/admin/login"
                # The login page
                ctx.response.cookies["sessionid"] = "HELLO"
                self.render_and_out(
                    ctx: ctx,
                    data: {
                        "title" => "Sign in to admin"
                    },
                    template: "admin/login.html"
                )
            when "/admin/login/auth"
                if ctx.request.body
                    params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
                    username = params["username"]?
                    password = params["password"]?
                    u = DataLib.get_user(username, password)
                    if u
                        # Set a new CSRF for this session
                        sessionid = Random::Secure.hex(16)
                        csrftoken = Random::Secure.hex(16)
                        DataLib.update_user_session(
                            id: u["id"],
                            sessionid: sessionid,
                            new_csrf_token: csrftoken,
                        )
                        ctx.response.cookies["sessionid"] = sessionid
                        ctx.response.cookies["csrftoken"] = csrftoken
                        ctx.response.cookies["sessionid"].http_only = true
                        ctx.response.cookies["csrftoken"].http_only = true
                        #usercookie = HTTP::Cookie.new("usertoken", result["data"]["sessionid"].to_s, "/", Time.utc + 24.hours)
                        #usercookie.http_only = true
                        #ctx.response.headers["Set-Cookie"] = usercookie.to_set_cookie_header
                        ctx.response.status_code = 200
                        ctx.response.content_type = "text/html; charset=UTF-8"
                        ctx.response.headers["HX-Redirect"] = "/admin/dashboard"
                        #ctx.response.close # ****** WHEN IS THIS NEEDED?? ******
                    else
                        # Adding an error status to the response here trips up
                        # the HTMX replacement, so we don't do it
                        ctx.response.content_type = "text/html; charset=UTF-8"
                        ctx.response.print "Your credentials were not recognized."
                    end
                end
            when "/admin/dashboard"
                self.render_and_out(
                    ctx: ctx,
                    data: {
                        "title" => "Admin dashboard"
                    },
                    template: "admin/dashboard.html"
                )
            when "/createarticle"
                #headers = HTTP::Headers.new
                if hd = ctx.request.headers["Authorization"]?
                    credstring = hd.split("Basic ")[1]?
                    if credstring
                        creds = Base64.decode_string(credstring).split(":")
                        if creds[0] == env["USERNAME"] && creds[1] == env["PASSWORD"]
                            ctx.response.status_code = 200
                            self.render_and_out(
                                ctx: ctx,
                                data: {
                                    "title" => "About me"
                                },
                                template: "about.html"
                            )
                            next
                        end
                    end
                end
                ctx.response.status_code = 401
                ctx.response.headers["WWW-Authenticate"] = "Basic realm=\"Login Required\""
                self.render_and_out(
                    ctx: ctx,
                    data: {
                        "error_msg" => "Login required"
                    },
                    template: "errors/401.html"
                )
            when "/"
                articles = DataLib.get_articles
                self.render_and_out(
                    ctx: ctx,
                    data: {
                        "articles" => articles,
                        "title" => "My Crystal World"
                    },
                    template: "home.html"
                )

            when "/tags"
                tags = DataLib.get_tags
                self.render_and_out(
                    ctx: ctx,
                    data: {
                        "tags" => tags,
                        "title" => "Tags"
                    },
                    template: "tags.html"
                )

            when .index("/tag/")
                urlbits = ctx.request.path.split('/', limit: 3, remove_empty: true)
                tag = urlbits[1]?
                articles = DataLib.get_articles_for_tag(tag)
                if !articles.empty?
                    self.render_and_out(
                        ctx: ctx,
                        data: {
                            "articles" => articles,
                            "tag" => tag,
                            "title" => "Articles tagged with " + tag.to_s
                        },
                        template: "tag.html"
                    )
                else
                    ctx.response.status = HTTP::Status.new(404)
                    self.render_and_out(
                        ctx: ctx,
                        data: {
                            "error_msg" => "Nothing found for that tag",
                        },
                        template: "errors/404.html",
                    )
                end

            when "/about"
                self.render_and_out(
                    ctx: ctx,
                    data: {
                        "title" => "About me"
                    },
                    template: "about.html"
                )

            when .match(/[a-zA-Z]/)
                puts ".match(/[a-zA-Z]/)"
                urlbits = ctx.request.path.split('/', limit: 2, remove_empty: true)
                slug = urlbits[0]?
                article = DataLib.get_article(slug: slug)
                if article
                    options = Markd::Options.new(smart: true, safe: true)
                    html = Markd.to_html(article["md"].as(String), options)
                    article["html"] = html.gsub("/bucket/", IMGBUCKET)
                    self.render_and_out(
                        ctx: ctx,
                        data: {
                            "article" => article,
                            "title" => article["title"],
                        },
                        template: "article.html",
                    )
                else
                    ctx.response.status = HTTP::Status.new(404)
                    self.render_and_out(
                        ctx: ctx,
                        data: {
                            "error_msg" => "Page not found",
                        },
                        template: "errors/404.html",
                    )
                end
        end # case
    end

    def render_and_out(ctx, data, template)
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
        ctx.response.content_type = "text/html; charset=UTF-8"
        ctx.response.print final_html
    end

    address = server.bind_tcp 8123
    puts "Listening on http://#{address}"
    server.listen

end