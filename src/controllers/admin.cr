module CrystalWorld::Controllers::Admin
  extend self

  def get_image(ctx)
    # Currently not used
    urlbits = ctx.request.path.split('/', remove_empty: true)
    file = urlbits[-1]?
    html = "<img src=\"https://ik.imagekit.io/alistairrobinson/blog/tr:w-150/#{file}\">"
    ctx.response.print html
  end

  def get_image_item(ctx, imgkit_url, filename)
    TemplateRenderer.render_partial(
      ctx: ctx,
      data: {
        "img_url"   => imgkit_url,
        "filename"  => filename
      },
      template_path: "admin/_image.html"
    )
  end

  def upload_image(ctx)
    #
    # TODO: sanitize against malicious uploads
    #
    # - Don't allow any other file types apart from images.
    #   (For example: only accept files with content-type: image/png, image/jpg, image/jpeg, image/gif)
    # - Always, save the file using an appropriate extension, never allow the user to control the extension of the filename.
    #   (You can save the file using a completely randomname to mitigate this, use GUID/UUID to generate a random name for the image)
    # - Set the HTTP Response's content type to image/<type>.
    #   (Browsers won't execute any javascript if the content type is image/*)
    # - Only use <img src="[path-to-img]"> tag to render the image and don't allow the user to control any values of HTML here.
    # - Use CSP to prevent XSS (Optional, better if you can implement)
    #
    #
    begin
      HTTP::FormData.parse(ctx.request) do |part|
        case part.name
        when "imageUpload"
          fname = part.filename.to_s
          p! fname
          temp_file_path = File.join(TEMP_IMAGES_FOLDER, fname)

          File.write(temp_file_path, part.body)

          # Ensure the file exists before proceeding
          unless File.exists?(temp_file_path)
            ctx.response.status_code = 500
            ctx.response.print "Failed to save the uploaded file."
            return
          end

          content_type = MIME.from_filename?(fname)
          if content_type
            puts "Content-Type: #{content_type}"
          else
            puts "Unknown content-type"
          end

          file = File.open(temp_file_path)

          req = Crest::Request.new(
            :post,
            url: "https://upload.imagekit.io/api/v1/files/upload",
            user: IMAGEKIT_PRIVATE_KEY,
            password: "",
            form: {
              "file"      => file,
              "fileName"  => fname,
              "type"      => content_type,
              "folder"    => "blog"
            },
          )
          res = req.execute

          if res.status_code != 200
            ctx.response.status_code = res.status_code
            ctx.response.print "Image upload to ImageKit failed."
            return
          end

          res_parsed = JSON.parse(res.body)
          imgkit_url = res_parsed["url"]
          filename = res_parsed["name"]

          # Ensure the temporary file is deleted after upload
          File.delete(temp_file_path)

          #ctx.response.headers["HX-Trigger-After-Settle"] = "uploadComplete"
          self.get_image_item(ctx, imgkit_url, filename)
        end
      end
    rescue e
      ctx.response.status_code = 500
      ctx.response.print "An error occurred during file upload: #{e.message}"
    end
  end

  def get_images(ctx)
    res = Crest.get(
      "https://api.imagekit.io/v1/files?path=blog",
      user: IMAGEKIT_PRIVATE_KEY,
      password: "",
      params: {
        "sort" => "DESC_CREATED"
      }
    )
    images = JSON.parse(res.body)
    TemplateRenderer.render_partial(ctx: ctx,
      data: {
        "images" => images,
      },
      template_path: "admin/_images.html"
    )
  end

  def images(ctx)
    if u = self.authenticated_user ctx
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "title"               => "Admin: images",
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
      return Data::Users.get_authenticated_user(sessionid, csrftoken)
    end
  end

  def articles(ctx)
    if u = self.authenticated_user ctx
      articles = Data::Articles.get_articles(
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
      articles = Data::Articles.get_deleted_articles(order_by: "date_created DESC")
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
          "title"               => "Admin: settings",
          "admin_section"       => "Admin: settings",
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
      users = Data::Users.get_users()
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "title"               => "Admin: authors",
          "admin_section"       => "Admin: authors",
          "authors"             => users,
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

  def new_author_form(ctx)
    if ctx.request.method == "POST"
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      invite_key = Random::Secure.hex(16)
      result = Data::Users.create_user(
        username: params["username"],
        first_name: params["firstName"],
        last_name: params["lastName"],
        invite_key: invite_key
      )
      p! result

      # Send email to params["username"] with a link to
      # "#{HOST}/admin/register?invite_key=#{invite_key}"
      #email = EMail::Message.new
      #email.from    "your_addr@example.com"
      #email.to      "to@example.com"
      #email.subject "Subject of the mail"
      #email.message <<-EOM
      #  Message body of the mail.
      #  --
      #  Your Signature
      #  EOM
      #config = EMail::Client::Config.new("your.mx.example.com", 25, helo_domain: "your.host.example.com")
      #client = EMail::Client.new(config)
      #client.start do
      #  send(email)
      #end

      ctx.response.print %(An email has been sent to #{params["username"]})
    else
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "title"               => "Admin: authors",
          "admin_section"       => "Admin: authors",
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
        },
        template_path: "admin/new_author_form.html"
      )
    end
  end

  def do_create_author(username, first_name, last_name)
  end

  def customize(ctx)
    if u = self.authenticated_user ctx
      settings = Data.get_settings
      TemplateRenderer.render_page(
        ctx: ctx,
        data: {
          "title"               => "Admin: customize",
          "admin_section"       => "Admin: customize",
          "user_authenticated"  => true,
          "sidebar_collapsed"   => self.sidebar_collapsed_classname(ctx),
          "admin"               => true,
          "settings"            => settings
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
        Data::Articles.delete_article(id)
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
      if article = Data::Articles.get_article(id: id.to_i)
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
      Controllers::Public.error_404 ctx
      return
    end
    ctx.response.redirect "/"
  end

  def article_properties(ctx)
    urlbits = ctx.request.path.split('/', remove_empty: true)
    id = urlbits[2]
    article = Data::Articles.get_article(id: id.to_i)
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
      article = Data::Articles.get_article(id: id.to_i)
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
      newid = Data::Articles.create_draft()
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

      # TODO:
      # WE HAVE THE ID IN THE url NOW SO THERES NO NEED TO GET IT FROM PARAMS
      # OR SEND IT IN PARAMS
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      if article_id = params["article_id"].to_i?

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

        publish = Data::Articles.publish_article(
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
        ctx.response.print %({
          "validation_results": #{validation_results.to_json},
          "published": true
        })
        return
      end
      Controllers::Public.error_404 ctx
    end
  end

  def unpublish_article(ctx)


    # WE HAVE THE ID IN THE url NOW SO THERES NO NEED TO GET IT FROM PARAMS
    # OR SEND IT IN PARAMS

    if u = self.authenticated_user ctx
      params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
      if article_id = params["article_id"].to_i?
        Data::Articles.unpublish_article(article_id)
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
