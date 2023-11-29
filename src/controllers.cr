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

    def authenticated_user(ctx)
      if ctx.request.cookies.has_key?("sessionid") && ctx.request.cookies.has_key?("csrftoken")
        sessionid = ctx.request.cookies["sessionid"].value
        csrftoken = ctx.request.cookies["csrftoken"].value
        return DataLib.get_authenticated_user(sessionid, csrftoken)
      end
    end

    def sidebar_collapsed_classname(ctx)
      sidebar_collapsed = nil
      if ctx.request.cookies.has_key?("sidebar_collapsed")
        return ctx.request.cookies["sidebar_collapsed"].value
      end
      return "normal"
    end

    def home_page(ctx)
      articles = DataLib.get_articles
      TemplateRenderer.render_and_out ctx: ctx,
        data: {
          "articles" => articles,
          "title"    => "My Crystal World"
        },
        template_path: "home.html"
    end

    def about_page(ctx)
      TemplateRenderer.render_and_out ctx: ctx,
        data: {
          "title" => "About me",
        },
        template_path: "about.html"
    end

    def article_page(ctx)
      urlbits = ctx.request.path.split('/', remove_empty: true)
      slug = urlbits[0]?
      if article = DataLib.get_article(slug: slug)
        options = Markd::Options.new(smart: true, safe: true)
        html = Markd.to_html(article["md"].as(String), options)
        article["html"] = html.gsub("/bucket/", IMGBUCKET)
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "article" => article,
            "title"   => article["title"],
          },
          template_path: "article.html"
        return
      end
      self.error_404 ctx
    end

    def tags_page(ctx)
      tags = DataLib.get_tags
      TemplateRenderer.render_and_out ctx: ctx,
        data: {
          "tags"  => tags,
          "title" => "Tags",
        },
        template_path: "tags.html"
    end

    def tag_page(ctx)
      urlbits = ctx.request.path.split('/', remove_empty: true)
      tag = urlbits[1]?
      articles = DataLib.get_articles_for_tag tag
      if !articles.empty?
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "articles" => articles,
            "tag"      => tag,
            "title"    => "Articles tagged with #{tag.to_s}",
          },
          template_path: "tag.html"
        return
      end
      self.error_404 ctx
    end

    def admin_settings(ctx)
      if u = self.authenticated_user ctx
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "title" => "Admin: articles",
            "user_authenticated" => true,
            "sidebar_collapsed" => self.sidebar_collapsed_classname(ctx),
            "admin" => true
          },
          template_path: "admin/settings.html"
        return
      end
      ctx.response.redirect "/"
    end

    def admin_authors(ctx)
      if u = self.authenticated_user ctx
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "title" => "Admin: articles",
            #"authors" => authors,
            "user_authenticated" => true,
            "sidebar_collapsed" => self.sidebar_collapsed_classname(ctx),
            "admin" => true
          },
          template_path: "admin/authors.html"
        return
      end
      ctx.response.redirect "/"
    end

    def admin_customize(ctx)
      if u = self.authenticated_user ctx
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "title" => "Admin: articles",
            "user_authenticated" => true,
            "sidebar_collapsed" => self.sidebar_collapsed_classname(ctx),
            "admin" => true
          },
          template_path: "admin/customize.html"
        return
      end
      ctx.response.redirect "/"
    end

    def admin_pages(ctx)
      if u = self.authenticated_user ctx
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "title" => "Admin: articles",
            #"articles" => articles,
            "user_authenticated" => true,
            "sidebar_collapsed" => self.sidebar_collapsed_classname(ctx),
            "admin" => true
          },
          template_path: "admin/pages.html"
        return
      end
      ctx.response.redirect "/"
    end

    def admin_articles(ctx)
      if u = self.authenticated_user ctx
        articles = DataLib.get_articles
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "title" => "Admin: articles",
            "articles" => articles,
            "user_authenticated" => true,
            "sidebar_collapsed" => self.sidebar_collapsed_classname(ctx),
            "admin" => true
          },
          template_path: "admin/articles.html"
        return
      end
      ctx.response.redirect "/"
    end

    def admin_edit_preview(ctx)
      if u = self.authenticated_user ctx
        urlbits = ctx.request.path.split('/', remove_empty: true)
        slug = urlbits[-2]?
        article = DataLib.get_article slug
        if article
          TemplateRenderer.render_and_out ctx: ctx,
            data: {
              "article" => article,
              "title"   => article["title"],
            },
            template_path: "admin/article_preview.html"
          return
        end
        self.error_404 ctx
      end
    end

    def save_sidebar_state(ctx)
      urlbits = ctx.request.path.split('/', remove_empty: true)
      state = urlbits[2] # 'collapsed' or 'normal'
      if ctx.request.cookies.has_key?("sidebar_collapsed")
        # Update existing cookie
        # STEP 1: expire the old one
        ck_sidebar_collapsed = HTTP::Cookie.new(
          "sidebar_collapsed", "",
          expires: Time.utc - 1.day
        )
        # STEP 2: create a new one
        ck_sidebar_collapsed = HTTP::Cookie.new(
          name: "sidebar_collapsed",
          value: state,
          path: "/",
          max_age: Time::Span.new(hours: 12),
          secure: false,
          samesite: HTTP::Cookie::SameSite.new(1),
          http_only: true,
        )
        ctx.response.headers["Set-Cookie"] = ck_sidebar_collapsed.to_set_cookie_header
      else
        # Add new cookie
        ctx.response.cookies["sidebar_collapsed"] = HTTP::Cookie.new(
          name: "sidebar_collapsed",
          value: state,
          path: "/",
          max_age: Time::Span.new(hours: 12),
          secure: false,
          samesite: HTTP::Cookie::SameSite.new(1),
          http_only: true
        )
      end
      json_text = %({"status": "#{state}"})
      ctx.response.print json_text
    end

    def admin_edit_article(ctx)
      if u = self.authenticated_user ctx
        urlbits = ctx.request.path.split('/', remove_empty: true)
        slug = urlbits[-1]?
        article = DataLib.get_article slug
        if article
          options = Markd::Options.new(smart: true, safe: true)
          html = Markd.to_html(article["md"].as(String), options)
          article["html"] = html.gsub("/bucket/", IMGBUCKET)
          TemplateRenderer.render_and_out ctx: ctx,
            data: {
              "title" => "Admin: articles",
              "article" => article,
              "user_authenticated" => true,
              "admin" => true,
              "extended_main" => true,
              "sidebar_collapsed" => self.sidebar_collapsed_classname(ctx),
              "imagekit_bucket" => IMGBUCKET
            },
            template_path: "admin/edit-article.html"
          return
        end
      end
      ctx.response.redirect "/"
    end

    def login_page(ctx)
      TemplateRenderer.render_and_out ctx: ctx,
        data: {
          "title" => "Sign in to admin",
        },
        template_path: "admin/login.html"
    end

    def do_logout(ctx)
      if u = self.authenticated_user(ctx)
        # Setting a cookie's expires in the past prompts the browser to delete it
        session_cookie = HTTP::Cookie.new("sessionid", "", expires: Time.utc - 1.day)
        csrf_cookie = HTTP::Cookie.new("csrftoken", "", expires: Time.utc - 1.day)
        ctx.response.headers["Set-Cookie"] = [session_cookie.to_set_cookie_header, csrf_cookie.to_set_cookie_header]
        ctx.response.headers["HX-Location"] = %({"path": "/", "target": "body"})
        DataLib.delete_user_session(
          sessionid: u["sessionid"]
        )
        return
      end
      ctx.response.redirect "/"
    end

    def do_login(ctx)
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      username = params["username"] || ""
      password = params["password"] || ""
      if u = DataLib.get_user(username)
        begin
          res = Argon2::Password.verify_password(password, u["password"].to_s)
          if res == Argon2::Response::ARGON2_OK
            # Set new sessionid and CSRF for this session
            sessionid = Random::Secure.hex(16)
            csrftoken = Random::Secure.hex(16)
            ctx.response.cookies["sessionid"] = HTTP::Cookie.new(
              name: "sessionid",
              value: sessionid,
              path: "/",
              max_age: Time::Span.new(hours: 12),
              secure: false,
              samesite: HTTP::Cookie::SameSite.new(1),
              http_only: true
            )
            ctx.response.cookies["csrftoken"] = HTTP::Cookie.new(
              name: "csrftoken",
              value: csrftoken,
              path: "/",
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

            # BASIC REDIRECT
            # ctx.response.redirect "/admin/articles"

            # BASIC REDIRECT FOR HTMX REQUEST
            # ctx.response.headers["HX-Redirect"] = "/admin/articles"

            # REDIRECT FOR HTMX REQUEST, REPLACING ONLY A PART OF THE PAGE
            # (new url pushed to the history automatically)
            ctx.response.headers["HX-Location"] = %({"path": "/admin/articles", "target": "body"})
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

    def error_404(ctx)
      ctx.response.status = HTTP::Status.new(404)
      TemplateRenderer.render_and_out ctx: ctx,
        data: {
          "error_msg" => "Page not found",
        },
        template_path: "errors/404.html"
    end

  end
end
