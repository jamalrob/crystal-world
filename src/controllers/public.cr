module CrystalWorld::PublicControllers
  extend self

  def home_page(ctx)
    articles = Data.get_articles
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
    urlbits = ctx.request.path.split('/', remove_empty: true)
    slug = urlbits[0]?
    if article = Data.get_article(slug: slug, return_draft: false)
      options = Markd::Options.new(smart: true, safe: true)
      html = Markd.to_html(article["md"].as(String), options)
      article["html"] = html.gsub("/bucket/", IMGBUCKET)
      TemplateRenderer.render_and_out(
        ctx: ctx,
        data: {
          "article" => article,
          "title"   => article["title"],
        },
        template_path: "article.html"
      )
      return
    end
    PublicControllers.error_404 ctx
  end

  def tags_page(ctx)
    tags = Data.get_tags
    TemplateRenderer.render_and_out(ctx: ctx,
      data: {
        "tags"  => tags,
        "title" => "Tags",
      },
      template_path: "tags.html"
    )
  end

  def tag_page(ctx)
    urlbits = ctx.request.path.split('/', remove_empty: true)
    tag = urlbits[1]?
    articles = Data.get_articles_for_tag(tag)
    if articles
      TemplateRenderer.render_and_out(ctx: ctx,
        data: {
          "articles" => articles,
          "tag"      => tag,
          "title"    => "Articles tagged with #{tag.to_s}",
        },
        template_path: "tag.html"
      )
      return
    end
    PublicControllers.error_404 ctx
  end

  def login_page(ctx)
    TemplateRenderer.render_and_out(ctx: ctx,
      data: {
        "title" => "Sign in to admin",
      },
      template_path: "admin/login.html"
    )
  end

  def error_404(ctx)
    puts "404 not found"
    ctx.response.status = HTTP::Status.new(404)
    TemplateRenderer.render_basic(
      ctx: ctx,
      template_path: "errors/404.html"
    )
  end
end
