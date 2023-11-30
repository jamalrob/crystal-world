module CrystalWorld

  module AdminControllers
    extend self

    def sidebar_collapsed_classname(ctx)
      if ctx.request.cookies.has_key?("sidebar_collapsed")
        return ctx.request.cookies["sidebar_collapsed"].value
      end
      return "normal"
    end

    def admin_articles(ctx)
      if u = AuthControllers.authenticated_user ctx
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

    def admin_settings(ctx)
      if u = AuthControllers.authenticated_user ctx
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
      if u = AuthControllers.authenticated_user ctx
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
      if u = AuthControllers.authenticated_user ctx
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
      if u = AuthControllers.authenticated_user ctx
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

    def admin_edit_preview(ctx)
      # *********************************
      # CURRENTLY NOT USED
      #
      if u = AuthControllers.authenticated_user ctx
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

    def article_properties(ctx)
      urlbits = ctx.request.path.split('/', remove_empty: true)
      slug = urlbits[1]?
      p! slug
      article = DataLib.get_article slug
      if article
        TemplateRenderer.render_and_out ctx: ctx,
          data: {
            "article" => article,
            "title"   => "Article properties",
            "imagekit_bucket" => IMGBUCKET
          },
          template_path: "admin/article_properties.html"
      end
    end

    def get_preview_html(ctx)
      # Using because showdown.js doesn't do smart quotes etc
      if u = AuthControllers.authenticated_user(ctx) && ctx.request.body
        urlbits = ctx.request.path.split('/', remove_empty: true)
        slug = urlbits[2]?
        article = DataLib.get_article slug
        if article
          params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
          if params.has_key?("markdown")
            md = params["markdown"]
            options = Markd::Options.new(smart: true, safe: true)
            html = Markd.to_html(md, options)
            html = html.gsub("/bucket/", IMGBUCKET)
            TemplateRenderer.render_and_out ctx: ctx,
              data: {
                "article" => article,
                "html" => html,
                "admin_preview" => true
              },
              template_path: "admin/article_preview.html"
            return
          end
        end
      end
      ctx.response.status = HTTP::Status.new(403)
    end

    def save_sidebar_state(ctx)
      if u = AuthControllers.authenticated_user ctx
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
        return
      end
      ctx.response.status = HTTP::Status.new(403)
    end

    def edit_article_page(ctx)
      if u = AuthControllers.authenticated_user ctx
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

  end
end