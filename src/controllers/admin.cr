module CrystalWorld::AdminControllers
  extend self

  def get_image(ctx)
    urlbits = ctx.request.path.split('/', remove_empty: true)
    file = urlbits[-1]?
    html = "<img src=\"https://ik.imagekit.io/alistairrobinson/blog/tr:w-150/#{file}\">"
    ctx.response.print html
  end

  def upload_image(ctx)

    p! ctx.request.body

    HTTP::FormData.parse(ctx.request) do |part|
      p! part.name
      case part.name
      when "imageUpload"
        fname = part.filename.to_s
        p! fname

        File.write("#{TEMP_IMAGES_FOLDER}/#{fname}", part.body)
        #tempfile = File.tempfile(fname, dir: TEMP_IMAGES_FOLDER)

        file = File.open("/home/user/Pictures/#{fname}")
        req = Crest::Request.new(
          :post,
          url: "https://upload.imagekit.io/api/v1/files/upload",
          user: IMAGEKIT_PRIVATE_KEY,
          password: "",
          form: {
            "file" => file,
            #"type" => "image/png",
            "fileName" => fname,
            "folder" => "blog"
          },
        )
        res = req.execute
        #ctx.response.headers["HX-Trigger"] = "uploadComplete"
        ctx.response.headers["HX-Trigger-After-Settle"] = "uploadComplete"
        #ctx.response.headers["HX-Trigger-After-Swap"] = "uploadComplete"
        #ctx.response.print res.status
        deleted = File.delete?("#{TEMP_IMAGES_FOLDER}/#{fname}")
        #tempfile.delete
        #tempfile.delete
        #content = File.open("/home/user/websites/crystal-world/#{fname}") do |f|
        #end
      end
    end
    self.get_images(ctx)
    #ctx.response.headers["HX-Trigger-After-Swap"] = "uploadComplete"
  end

  def get_images(ctx)
    img_arr = [] of String
    if LOCAL
      res = Crest.get(
        "https://api.imagekit.io/v1/files?path=blog",
        user: IMAGEKIT_PRIVATE_KEY,
        password: "",
        params: {
          "sort" => "DESC_CREATED"
        }
      )
      #
      # TODO: find out how to do this parsing and looping properly
      # --- cos `ims.each do |im|` doesn't work
      #
      ims = JSON.parse(res.body)
      i = 0
      array_has_ended = false
      while !array_has_ended
        begin
          img_arr.push(ims[i]["name"].to_s)
        rescue IndexError
          array_has_ended = true
        end
        i += 1
      end
    else

      # Use a fixture so as to avoid calling the
      # ImageKit API
      # https://ik.imagekit.io/alistairrobinson/blog
      # https://ik.imagekit.io/alistairrobinson/blog/tr:w-150
      img_arr = [
        "crash-by-jg-ballard.jpg",
        "mynah.png",
        "logicomix-an-epic-search.jpg",
        "profile.jpg",
        "_House-of-New-Life.jpg",
        "great-moscow-state-circus.jpg",
        "me-in-kazakhstan.jpg",
        "metro-ulitsa-1905.jpg",
        "post-war-soviet-modernist-architecture.jpg",
        "jg-ballards-crash-is-it-science-fiction.jpg",
        "nova-by-samuel-r-delany-1968.jpg",
        "_Gorky-Art-Theatre-A-Savin-WikiCommons.jpg",
        "profile2_J9se4LBCU.jpg",
        "mynah3.png",
        "logomynah3_W9qR2Ve9Z.png",
        "duckrabbit_large.png",
        "perceptual-constancy_large.jpg",
        "bird1.png",
        "trouble-on-triton-samuel-r-delany-1976.jpg",
      ]
    end

    TemplateRenderer.render_partial(ctx: ctx,
      data: {
        "images" => img_arr,
      },
      template_path: "admin/_images.html"
    )
  end

  def images(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          #"images"              => img_arr,
          "admin_section"       => "Admin: images",
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/images.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

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

  def articles(ctx)
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

  def bin(ctx)
    if u = self.authenticated_user ctx
      articles = Data.get_deleted_articles(order_by: "date_created DESC")
      TemplateRenderer.render_page(
        ctx: ctx,
        data: {
          "title"               => "Admin: bin",
          "admin_section"       => "Admin: bin",
          "articles"            => articles,
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/bin.html"
      )
      return
    end
    ctx.response.redirect "/"
  end

  def settings(ctx)
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

  def authors(ctx)
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

  def customize(ctx)
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

  def pages(ctx)
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
      id = urlbits[2]?
      begin
        Data.delete_article(id)
        self.articles(ctx)
      rescue e
        p! e
        return e.message
      end
    end
  end

  def edit_article_page(ctx)
    if u = self.authenticated_user ctx
      urlbits = ctx.request.path.split('/', remove_empty: true)
      id = urlbits[2]
      if article = Data.get_article(id: id.to_i)
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
    id = urlbits[2]
    article = Data.get_article(id: id.to_i)
    if article
      ctx.response.headers["HX-Trigger-After-Settle"] = "doSetupArticle"
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

  def markdown_cheatsheet(ctx)
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
      id = urlbits[2]
      article = Data.get_article(id: id.to_i)
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
      newid = Data.create_draft()
      ctx.response.headers["HX-Location"] = %({"path": "/admin/articles/#{newid}/edit", "target": "body"})
    end
  end

  def validate_slug_inline(ctx)
    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      TemplateRenderer.render_partial(
        ctx: ctx,
        data: Validators.validate_slug(params["slug"], params["article_id"]),
        template_path: "admin/_validate_slug.html"
      )
    end
  end

  def validate_date_inline(ctx)
    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      TemplateRenderer.render_partial(
        ctx: ctx,
        data: Validators.validate_date(params["date"], params["article_id"]),
        template_path: "admin/_validate_date.html"
      )
    end
  end

  def publish_article(ctx)
    if u = self.authenticated_user ctx

      # WE HAVE THE ID IN THE url NOW SO THERES NO NEED TO GET IT FROM PARAMS
      # OR SEND IT IN PARAMS
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      if article_id = params["article_id"].to_i?
        #
        # FINAL VALIDATION
        #
        validation_results = [
          Validators.validate_date(
            value: params["date"],
            article_id: params["article_id"]
          ),
          Validators.validate_slug(
            value: params["slug"],
            article_id: params["article_id"]
          ),
          #Validators.validate_tags(
          #  value: params["tags"]
          #)
        ]

        validation_results.each do |res|
          if res["publish"] == false
            ctx.response.print %({
              "validation_results": #{validation_results.to_json}
            })
            return
          end
        end

        #
        # Should return the value or an amended value from
        # every validator, but not necessarily any errors.
        # Only if there are errors should we return / prevent publication
        #
        # Should return this from validators instead of current:
        # Example:

        # hash = {
        #   "name" => "slug",
        #   "value" => "#{value}-#{Random.new.hex(8)}",
        #   "error" => {
        #     "error_message" => "Duplicate slug found and unique ID added",
        #     "show_as_error" => false
        #   }
        # }
        #

        puts "NO ERRORS"
        #params.each do |pm|
        #  if pm[0] != "md"
        #    pp pm
        #  end
        #end

        publish = Data.publish_article(
          article_id: article_id,
          slug: params["slug"],
          title: params["title"],
          date: params["date"],
          tags: params["tags"],
          #main_image: params["main_image"],
          main_image: "",
          image_class: params["imageClass"],
          md: params["md"]
        )
        #ctx.response.print %({"result": "Published"})
        ctx.response.print %({
          "validation_results": #{validation_results.to_json},
          "published": true
        })
        return
      end
      PublicControllers.error_404 ctx
    end
  end

  def unpublish_article(ctx)


    # WE HAVE THE ID IN THE url NOW SO THERES NO NEED TO GET IT FROM PARAMS
    # OR SEND IT IN PARAMS

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
