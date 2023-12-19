module CrystalWorld::Controllers::Public
  extend self

  def home(ctx)
    articles = Data::Articles.get_articles
    #header_pages = Data::Pages.get_header_pages
    TemplateRenderer.render_page(
      ctx: ctx,
      data: {
        "articles"      => articles,
        #"header_pages"  => header_pages,
        "title"         => "My Crystal World",
      },
      template_path: "home.html"
    )
  end

  def about(ctx)
    TemplateRenderer.render_page(
      ctx: ctx,
      data: {
        "title" => "About me",
      },
      template_path: "about.html"
    )
  end

  def article(ctx)
    urlbits = ctx.request.path.split('/', remove_empty: true)
    slug = urlbits[0]
    if article = Data::Articles.get_article(slug: slug, return_draft: false)
      options = Markd::Options.new(smart: true, safe: true)
      html = Markd.to_html(article["md"].as(String), options)
      article["html"] = html.gsub("/bucket/", IMGBUCKET)
      TemplateRenderer.render_page(
        ctx: ctx,
        data: {
          "article" => article,
          "title"   => article["title"],
        },
        template_path: "article.html"
      )
      return
    end
    Controllers::Public.error_404 ctx
  end

  def tags(ctx)
    tags = Data::Articles.get_tags
    TemplateRenderer.render_page(ctx: ctx,
      data: {
        "tags"  => tags,
        "title" => "Tags",
      },
      template_path: "tags.html"
    )
  end

  def tag(ctx)
    urlbits = ctx.request.path.split('/', remove_empty: true)
    tag = urlbits[1]?
    articles = Data::Articles.get_articles_for_tag(tag)
    if articles
      TemplateRenderer.render_page(ctx: ctx,
        data: {
          "articles" => articles,
          "tag"      => tag,
          "title"    => "Articles tagged with #{tag.to_s}",
        },
        template_path: "tag.html"
      )
      return
    end
    Controllers::Public.error_404 ctx
  end

  def login(ctx)
    TemplateRenderer.render_page(ctx: ctx,
      data: {
        "title" => "Sign in to admin",
      },
      template_path: "login.html"
    )
  end

  def register(ctx)
    TemplateRenderer.render_page(ctx: ctx,
      data: {
        "title" => "Sign up",
      },
      template_path: "register.html"
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
