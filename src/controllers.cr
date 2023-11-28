require "http/client"
require "markd"
require "front_matter"
require "poncho"
require "./datalib.cr"
require "crinja"
require "crystal-argon2"
require "./lib/renderer.cr"

module CrystalWorld
  extend self

  @@env : Poncho::Parser
  @@env = Poncho.from_file ".env"

  IMGBUCKET = "https://ik.imagekit.io/alistairrobinson/blog/tr:w-800,q-70/"

  module Controllers
    extend self

    def home_page(ctx)
      articles = DataLib.get_articles
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "articles" => articles,
          "title"    => "My Crystal World",
        },
        template_path: "home.html"
      )
    end

    def about_page(ctx)
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "title" => "About me",
        },
        template_path: "about.html"
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
        TemplateRenderer.render_and_out(
          ctx: ctx,
          data: {
            "article" => article,
            "title"   => article["title"],
          },
          template_path: "article.html",
        )
        return
      end
      ctx.response.status = HTTP::Status.new(404)
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "error_msg" => "Page not found",
        },
        template_path: "errors/404.html",
      )
    end

    def tags_page(ctx)
      tags = DataLib.get_tags
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "tags"  => tags,
          "title" => "Tags",
        },
        template_path: "tags.html"
      )
    end

    def tag_page(ctx)
      urlbits = ctx.request.path.split('/', limit: 3, remove_empty: true)
      tag = urlbits[1]?
      articles = DataLib.get_articles_for_tag(tag)
      if !articles.empty?
        TemplateRenderer.render_and_out(
          ctx: ctx,
          data: {
            "articles" => articles,
            "tag"      => tag,
            "title"    => "Articles tagged with #{tag.to_s}",
          },
          template_path: "tag.html"
        )
        return
      end
      ctx.response.status = HTTP::Status.new(404)
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "error_msg" => "Nothing found for that tag",
        },
        template_path: "errors/404.html",
      )
    end

    def admin_dashboard(ctx)
      if ctx.request.cookies.has_key?("sessionid") && ctx.request.cookies.has_key?("csrftoken")
        sessionid = ctx.request.cookies["sessionid"].value
        csrftoken = ctx.request.cookies["csrftoken"].value
        u = DataLib.get_authenticated_user(sessionid, csrftoken)
        if u
          TemplateRenderer.render_and_out(
            ctx: ctx,
            data: {
              "title" => "Admin dashboard",
            },
            template_path: "admin/dashboard.html",
            csrftoken: csrftoken
          )
          return
        end
      end
      ctx.response.redirect "/"
    end

    def login_page(ctx)
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "title" => "Sign in to admin",
        },
        template_path: "admin/login.html"
      )
    end

    def do_logout(ctx)
      if ctx.request.cookies.has_key?("sessionid")  && ctx.request.cookies.has_key?("csrftoken")
        sessionid = ctx.request.cookies["sessionid"].value
        csrftoken = ctx.request.cookies["csrftoken"].value
        if DataLib.get_authenticated_user(sessionid, csrftoken)
          # Setting a cookie's expires in the past prompts the browser to delete it
          session_cookie = HTTP::Cookie.new("sessionid", "", expires: Time.utc - 1.day, samesite: HTTP::Cookie::SameSite.new(1))
          csrf_cookie = HTTP::Cookie.new("csrftoken", "", expires: Time.utc - 1.day, samesite: HTTP::Cookie::SameSite.new(1))
          ctx.response.headers["Set-Cookie"] = [session_cookie.to_set_cookie_header, csrf_cookie.to_set_cookie_header]
          ctx.response.headers["HX-Location"] = %({"path": "/", "target": "body"})
          DataLib.delete_user_session(
            sessionid: sessionid
          )
          return
        end
      end
      ctx.response.redirect "/"
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
            DataLib.update_user_session(
              id: u["id"],
              sessionid: sessionid,
              new_csrf_token: csrftoken,
            )

            # Header for HTMX redirect
            # Obvs only applies when it's an HTMX-only route

            # The following is for a basic redirect
            #ctx.response.headers["HX-Redirect"] = "/admin/dashboard"

            # The following is to replace just a part of the page
            # (new url pushed to the history automatically)
            ctx.response.headers["HX-Location"] = %({"path": "/admin/dashboard", "target": "body"})
            return
          end
        rescue ex
          puts "Bad credentials"
        end
      end

      # Adding an error status to the response here trips up
      # the HTMX replacement, so we don't do it
      ctx.response.print "Your credentials were not recognized."
    end

  end
end
