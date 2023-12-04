module CrystalWorld::AdminControllers
  extend self

  def sidebar_collapsed_classname(ctx)
    if ctx.request.cookies.has_key?("sidebar_collapsed")
      return ctx.request.cookies["sidebar_collapsed"].value
    end
    return "normal"
  end

  def authenticated_user(ctx)
    if ctx.request.cookies.has_key?("sessionid") && ctx.request.cookies.has_key?("csrftoken")
      sessionid = ctx.request.cookies["sessionid"].value
      csrftoken = ctx.request.cookies["csrftoken"].value
      return Data.get_authenticated_user(sessionid, csrftoken)
    end
  end

  def admin_articles(ctx)
    if u = self.authenticated_user ctx
      articles = Data.get_articles(
        include_drafts: true,
        order_by: "date_created DESC"
        )
      TemplateRenderer.render_page(
        ctx: ctx,
        data: {
          "title"               => "Admin: articles",
          "admin_section"       => "Admin: articles",
          "articles"            => articles,
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/articles.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def admin_settings(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "title"               => "Admin: articles",
          "admin_section"       => "Admin: articles",
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/settings.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def admin_authors(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "title"               => "Admin: articles",
          "admin_section"       => "Admin: articles",
          # "authors"           => authors,
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/authors.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def admin_customize(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_page(
        ctx: ctx,
        data: {
          "title"               => "Admin: articles",
          "admin_section"       => "Admin: articles",
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/customize.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def admin_pages(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "title"               => "Admin: articles",
          "admin_section"       => "Admin: articles",
          # "articles" => articles,
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/pages.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def delete_article(ctx)
    if u = self.authenticated_user ctx
      urlbits = ctx.request.path.split('/', remove_empty: true)
      slug = urlbits[2]?
      begin
        Data.delete_article(slug)
        self.admin_articles(ctx)
      rescue e
        p! e
        return e.message
      end
    end
  end

  def edit_article_page(ctx)
    if u = self.authenticated_user ctx
      urlbits = ctx.request.path.split('/', remove_empty: true)
      slug = urlbits[2]?
      if article = Data.get_article(slug: slug, return_draft: true)
        options = Markd::Options.new(smart: true, safe: true)
        html = Markd.to_html(article["md"].as(String), options)
        article["html"] = html.gsub("/bucket/", IMGBUCKET)
        TemplateRenderer.render_page(
          ctx: ctx,
          data: {
            "title"               => "Editing: #{article["title"]}",
            "admin_section"       => "Admin: articles",
            "article"             => article,
            "user_authenticated"  => true,
            "admin"               => true,
            "extended_main"       => true,
            "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
            "imagekit_bucket"     => IMGBUCKET,
          },
          template_path: "admin/edit-article.html"
        )
        return
      end
      PublicControllers.error_404 ctx
      return
    end
    ctx.response.redirect "/"
  end

  def article_properties(ctx)
    urlbits = ctx.request.path.split('/', remove_empty: true)
    slug = urlbits[2]?
    article = Data.get_article(slug: slug, return_draft: true)
    if article
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "article"         => article,
          "title"           => "Article properties",
          "imagekit_bucket" => IMGBUCKET,
        },
        template_path: "admin/article_properties.html"
      )
    end
  end

  def admin_markdown_cheatsheet(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_basic(
        ctx: ctx,
        template_path: "admin/markdown-cheatsheet.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def get_preview_html(ctx)
    #
    # Returns the full preview HTML. Done on the server-side because
    # showdown.js doesn't do smart quotes etc.
    #
    if u = self.authenticated_user(ctx) && ctx.request.body
      urlbits = ctx.request.path.split('/', remove_empty: true)
      slug = urlbits[2]?
      article = Data.get_article(slug: slug, return_draft: true)
      if article
        params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
        if params.has_key?("markdown")
          md = params["markdown"]
          options = Markd::Options.new(smart: true, safe: true)
          html = Markd.to_html(md, options)
          html = html.gsub("/bucket/", IMGBUCKET)
          sanitizer = Sanitize::Policy::HTMLSanitizer.common
          sanitizer.valid_classes << /language-.+/
          html = sanitizer.process(html)
          TemplateRenderer.render_page(ctx: ctx,
            data: {
              "article"       => article,
              "html"          => html,
              "admin_preview" => true,
            },
            template_path: "admin/article_preview.html"
          )
          return
        end
      end
    end
    ctx.response.status = HTTP::Status.new(403)
  end

  def new_article_page(ctx)
    if u = self.authenticated_user ctx
      newslug = Data.create_draft()
      #self.edit_article_page(ctx)
      ctx.response.headers["HX-Location"] = %({"path": "/admin/articles/#{newslug}/edit", "target": "body"})
      #TemplateRenderer.render_page(
      #  ctx: ctx,
      #  data: {
      #    "title"               => "Editing: #{article["title"]}",
      #    "admin_section"       => "Admin: articles",
      #    "article"             => article,
      #    "user_authenticated"  => true,
      #    "admin"               => true,
      #    "extended_main"       => true,
      #    "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
      #    "imagekit_bucket"     => IMGBUCKET,
      #  },
      #  template_path: "admin/edit-article.html"
      #)
    end
  end

  def validate_slug(ctx)
    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      user_slug = params["slug"]

      error_message = nil
      if !user_slug.match /^#{SLUG_PATTERN}$/
        error_message = "Only lower case letters, numbers, and hyphens"
      else
        articles = Data.get_articles_by_slug(user_slug)
        if !articles.empty?
          #error_message = "Duplicate slug found. It must be unique."
          r = Random.new
          user_slug = "#{user_slug}-#{r.hex(3)}"
        else
      end

      end

      TemplateRenderer.render_partial(
        ctx: ctx,
        data: {
          "error_message" => error_message,
          "user_slug"     => user_slug
        },
        template_path: "admin/_validate_slug.html"
      )
    end
  end

  def validate_date(ctx)
    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      error_message = nil
      begin
        proper_date = Time.parse_utc(params["date"], "%Y-%m-%d").to_s("%Y-%m-%d")
      rescue Time::Format::Error
        puts "date format error"
        error_message = "Please enter a valid date"
      end
      TemplateRenderer.render_partial(
        ctx: ctx,
        data: {
          "error_message" => error_message,
          "user_date"     => params["date"]
        },
        template_path: "admin/_validate_date.html"
      )
    end
  end

  def publish_article(ctx)
    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      if article_id = params["article_id"].to_i?
        #
        # FINAL VALIDATION
        #
        # Date
        #
        begin
          proper_date = Time.parse_utc(params["date"], "%Y-%m-%d").to_s("%Y-%m-%d")
        rescue Time::Format::Error
          puts "date format error"
          #ctx.response.status_code = 500
          ctx.response.print %({"error": "Date format error"})
          return
        end

        # Sanitize
        #
        # sanitizer = Sanitize::Policy::HTMLSanitizer.common
        # sanitizer.valid_classes << /language-.+/
        # sanitized_md = sanitizer.process(params["md"])
        params.each do |param|
          p! param
        end

        publish = Data.publish_article(
          article_id: article_id,
          slug: params["slug"],
          title: params["title"],
          date: proper_date,
          tags: params["tags"],
          #main_image: params["mainImage"],
          main_image: "",
          image_class: params["imageClass"],
          md: params["md"]
        )
        ctx.response.print %({"result": "Published"})
        return
      end
      PublicControllers.error_404 ctx
    end
  end

  def unpublish_article(ctx)
    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      if article_id = params["article_id"].to_i?
        Data.unpublish_article(article_id)
        json_text = %({"result": "Unpublished"})
        ctx.response.print json_text
        return
      end
    end
  end

  def save_sidebar_state(ctx)
    if u = self.authenticated_user ctx
      urlbits = ctx.request.path.split('/', remove_empty: true)
      state = urlbits[2] # 'collapsed' or 'normal'
      if ctx.request.cookies.has_key?("sidebar_collapsed")
        #
        # Update existing cookie
        #
        # 1: expire the old one
        ck_sidebar_collapsed = HTTP::Cookie.new(
          "sidebar_collapsed", "",
          expires: Time.utc - 1.day
        )
        # 2: create a new one
        ck_sidebar_collapsed = HTTP::Cookie.new(
          name: "sidebar_collapsed",
          value: state,
          path: "/",
          max_age: Time::Span.new(days: 30),
          secure: false,
          samesite: HTTP::Cookie::SameSite.new(1),
          http_only: true,
        )
        ctx.response.headers["Set-Cookie"] = ck_sidebar_collapsed.to_set_cookie_header
      else
        #
        # Create a new cookie
        #
        ctx.response.cookies["sidebar_collapsed"] = HTTP::Cookie.new(
          name: "sidebar_collapsed",
          value: state,
          path: "/",
          max_age: Time::Span.new(days: 30),
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

end
