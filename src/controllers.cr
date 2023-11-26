require "http/client"
require "markd"
require "front_matter"
require "poncho"
require "./datalib.cr"
require "crinja"
require "crystal-argon2"

module CrystalWorld
  module Controllers
    extend self

    def env
      return Poncho.from_file ".env"
    end

    IMGBUCKET = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"
    LOCAL     = env["ENV"] == "local" || false
    CACHEBUST = Time.monotonic.to_s.split(".")[-1]

    def home_page(ctx)
      articles = DataLib.get_articles
      self.render_and_out(
        ctx: ctx,
        data: {
          "articles" => articles,
          "title"    => "My Crystal World",
        },
        template: "home.html"
      )
    end

    def about_page(ctx)
      self.render_and_out(
        ctx: ctx,
        data: {
          "title" => "About me",
        },
        template: "about.html"
      )
    end

    def article_page(ctx)
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
            "title"   => article["title"],
          },
          template: "article.html",
        )
        return
      end
      ctx.response.status = HTTP::Status.new(404)
      self.render_and_out(
        ctx: ctx,
        data: {
          "error_msg" => "Page not found",
        },
        template: "errors/404.html",
      )
    end

    def tags_page(ctx)
      tags = DataLib.get_tags
      self.render_and_out(
        ctx: ctx,
        data: {
          "tags"  => tags,
          "title" => "Tags",
        },
        template: "tags.html"
      )
    end

    def tag_page(ctx)
      urlbits = ctx.request.path.split('/', limit: 3, remove_empty: true)
      tag = urlbits[1]?
      articles = DataLib.get_articles_for_tag(tag)
      if !articles.empty?
        self.render_and_out(
          ctx: ctx,
          data: {
            "articles" => articles,
            "tag"      => tag,
            "title"    => "Articles tagged with #{tag.to_s}",
          },
          template: "tag.html"
        )
        return
      end
      ctx.response.status = HTTP::Status.new(404)
      self.render_and_out(
        ctx: ctx,
        data: {
          "error_msg" => "Nothing found for that tag",
        },
        template: "errors/404.html",
      )
    end

    def admin_dashboard(ctx)
      self.render_and_out(
        ctx: ctx,
        data: {
          "title" => "Admin dashboard",
        },
        template: "admin/dashboard.html"
      )
    end

    def login_page(ctx)
      self.render_and_out(
        ctx: ctx,
        data: {
          "title" => "Sign in to admin",
        },
        template: "admin/login.html"
      )
    end

    def do_login(ctx)
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      username = params["username"] || ""
      password = params["password"] || ""
      u = DataLib.get_user(username)
      if u
        begin
          res = Argon2::Password.verify_password(password, u["password"].to_s)
          if res == Argon2::Response::ARGON2_OK
            # Set new sessionid and CSRF for this session
            sessionid = Random::Secure.hex(16)
            csrftoken = Random::Secure.hex(16)
            DataLib.update_user_session(
              id: u["id"],
              sessionid: sessionid,
              new_csrf_token: csrftoken,
            )
            ctx.response.cookies["sessionid"] = HTTP::Cookie.new(
              name: "sessionid",
              value: sessionid,
              path: "/admin",
              max_age: Time::Span.new(hours: 12),
              secure: false,
              samesite: HTTP::Cookie::SameSite.new(1),
              http_only: true
            )
            ctx.response.cookies["csrftoken"] = HTTP::Cookie.new(
              name: "csrftoken",
              value: csrftoken,
              path: "/admin",
              max_age: Time::Span.new(hours: 12),
              secure: false,
              samesite: HTTP::Cookie::SameSite.new(1),
              http_only: true,
            )
            ctx.response.status_code = 200
            ctx.response.content_type = "text/html; charset=UTF-8"
            ctx.response.headers["HX-Redirect"] = "/admin/dashboard"
            return
          end
        rescue ex
          puts "Bad credentials"
        end
      end

      # Adding an error status to the response here trips up
      # the HTMX replacement, so we don't do it
      ctx.response.content_type = "text/html; charset=UTF-8"
      ctx.response.print "Your credentials were not recognized."
    end

    def render_and_out(ctx, data, template)
      if LOCAL
        # In development, get a fresh string to append
        # to static file URLs on every request
        data.put("cachebust", Time.monotonic.to_s.split(".")[-1]) { "update" }
      else
        # Or, for production, use the value generated
        # at compile time
        data.put("cachebust", CACHEBUST) { "update" }
      end
      tengine = Crinja.new
      tengine.loader = Crinja::Loader::FileSystemLoader.new("src/templates/")
      template = tengine.get_template(template)
      final_html = template.render(data)
      ctx.response.content_type = "text/html; charset=UTF-8"
      ctx.response.print final_html
    end

  end
end