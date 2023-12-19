module CrystalWorld::Data::Articles
  extend self

  def purge_article(id)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        return db.exec("DELETE FROM articles WHERE id = ?", id)
      rescue e
        puts e.message
      end
    end
  end

  def delete_article(id)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        return db.exec("UPDATE articles SET deleted = 1, date = '' WHERE id = ?", id)
      rescue e
        puts e.message
      end
    end
  end

  def create_draft
    DB.open "sqlite3://./crw.db" do |db|
      begin
        newid = db.query_one( "SELECT seq FROM sqlite_sequence " \
                            "WHERE name = 'articles' LIMIT 1;",
                            as: {Int32}
            ) + 1
        newslug = "new-draft-#{newid}-#{Random.new.hex(4)}"
        insert = db.exec("INSERT INTO articles " \
                "(slug, title, tags, date, date_created, main_image, image_class, draft, content) " \
                " VALUES (?, ?, ?, ?, DATE('now'), ?, ?, ?, ?);",
          "#{newslug}", "New Draft #{newid}", "", "", "", "", 1, ""
        )
        return newid
      rescue e
        p! e
      end
    end
  end

  def get_tags
    all_tags = [] of String
    DB.open "sqlite3://./crw.db" do |db|
      tag_vals = db.query_all(
        "SELECT tags from articles WHERE draft = 0;",
        as: {String}
      )
      tag_vals.each do |row|
        all_tags |= row.delete(' ').split(",")
      end
    end
    return all_tags
  end


  # ************************************************************************
  #
  # TODO: REMOVE THE DB::NORESULTS ERROR STUFF EVERYWHERE EXCEPT query_one
  #
  # ************************************************************************

  def get_articles_by_slug(slug, exclude_article_id : Int32 = 0)
    DB.open "sqlite3://./crw.db" do |db|
      #articles = [] of Int32 | Nil
      if exclude_article_id > 0
        articles = (db.query_all  "SELECT id " \
                                  "FROM articles " \
                                  "WHERE slug = ? AND id != ? " \
                                  "AND deleted = 0;",
                                  slug, exclude_article_id,
                                  as: {Int32}
        )
      else
        articles = (db.query_all  "SELECT id " \
                                  "FROM articles " \
                                  "WHERE slug = ? " \
                                  "AND deleted = 0;",
                                  slug,
                                  as: {Int32}
        )
      end
      return articles
    end
  end

  def get_deleted_articles(order_by="date DESC")
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String | Array(String) | Int32 | Nil)
      results = (db.query_all "SELECT id, slug, title, date, date_created, tags, draft " \
                                  "FROM articles WHERE deleted = 1 ORDER BY #{order_by};",
                                  as: {Int32, String, String, String?, String, String?, Int32}
            )
      results.each do |result|
        begin
          pub_date = Time.parse_utc(result[3].to_s, "%Y-%m-%d").to_s("%Y-%m-%d")
          pub_date_friendly = Time.parse_utc(result[3].to_s, "%Y-%m-%d").to_s("%d %B %Y")
        rescue e
          puts "Currently not published or bad pub date format"
        end

        tags = result[5]
        if tags
          tags = tags.delete(' ').split(",")
        end
        this_row = {
          "id"                    => result[0],
          "slug"                  => result[1],
          "title"                 => result[2],
          "date"                  => pub_date,
          "friendly_date"         => pub_date_friendly,
          "date_created"          => Time.parse_utc(result[4], "%Y-%m-%d").to_s("%Y-%m-%d"),
          "friendly_date_created" => Time.parse_utc(result[4], "%Y-%m-%d").to_s("%d %B %Y"),
          "draft"                 => result[6],
          "tags"                  => tags,
        }
        articles.push(this_row)
      end
      return articles
    end
  end

  def get_articles(include_drafts=false, order_by="date DESC")
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String | Array(String) | Int32 | Nil)
      where = "WHERE deleted = 0 "
      if !include_drafts
        where += "AND draft = 0 AND date <= DATETIME('now') "
      end
      query = "SELECT id, slug, title, date, date_created, tags, draft FROM articles " \
              "#{where} ORDER BY #{order_by};"

      results = db.query_all(
        query,
        as: {Int32, String, String, String?, String, String?, Int32}
      )

      results.each do |result|
        begin
          pub_date = Time.parse_utc(result[3].to_s, "%Y-%m-%d").to_s("%Y-%m-%d")
          pub_date_friendly = Time.parse_utc(result[3].to_s, "%Y-%m-%d").to_s("%d %B %Y")
        rescue e
          puts "Currently not published or bad pub date format"
        end

        tags = result[5]
        if tags
          tags = tags.delete(' ').split(",")
        end
        this_row = {
          "id"                    => result[0],
          "slug"                  => result[1],
          "title"                 => result[2],
          "date"                  => pub_date,
          "friendly_date"         => pub_date_friendly,
          "date_created"          => Time.parse_utc(result[4], "%Y-%m-%d").to_s("%Y-%m-%d"),
          "friendly_date_created" => Time.parse_utc(result[4], "%Y-%m-%d").to_s("%d %B %Y"),
          "draft"                 => result[6],
          "tags"                  => tags,
        }
        articles.push(this_row)
      end
      return articles
    end
  end

  def get_articles_for_tag(tag)
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String | Int32)
      begin
        results = db.query_all("SELECT id, slug, title, date, tags FROM articles " \
                               "WHERE deleted = 0 AND draft = 0 " \
                               "AND tags LIKE '%' || ? || '%' " \
                               "ORDER BY date DESC;",
          tag,
          as: {Int32, String, String, String, String}
        )
        results.each do |result|
          this_row = {
            "id"            => result[0],
            "slug"          => result[1],
            "title"         => result[2],
            "date"          => Time.parse_utc(result[3], "%Y-%m-%d").to_s("%Y-%m-%d"),
            "friendly_date" => Time.parse_utc(result[3], "%Y-%m-%d").to_s("%d %B %Y"),
          }
          articles.<<(this_row)
        end
        return articles.empty? ? nil : articles
      rescue DB::NoResultsError
        return nil
      end
    end
  end

  def get_article(id : Int32)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        id, slug, title, tags, date, image, imageclass, draft, md =
          db.query_one("SELECT id, slug, title, tags, date, main_image, " \
                        "image_class, draft, content " \
                        "FROM articles WHERE id = ? LIMIT 1;",
                        id,
            as: {Int32, String, String, String?, String, String?, String?, Int32, String}
          )

        pub_date = !date || date == "" ? nil : date
        if pub_date
          pub_date = Time.parse_utc(date, "%Y-%m-%d").to_s("%Y-%m-%d")
          friendly_date = Time.parse_utc(date, "%Y-%m-%d").to_s("%d %B %Y")
        end

        return {
          "id"            => id,
          "slug"          => slug,
          "title"         => title,
          "date"          => pub_date,
          "friendly_date" => friendly_date,
          "tags"          => tags,
          "image"         => image,
          "imageclass"    => imageclass,
          "draft"         => draft,
          "md"            => md,
        }
      rescue DB::NoResultsError
        return nil
      end
    end
  end

  def get_article(slug : String, return_draft : Bool = false)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        anddrafts = ""
        if return_draft
          anddrafts = "AND draft = 0 "
        end

        id, slug, title, tags, date, image, imageclass, draft, md =
          db.query_one("SELECT id, slug, title, tags, date, main_image, " \
                        "image_class, draft, content " \
                        "FROM articles WHERE slug = ? #{anddrafts}LIMIT 1;",
            slug,
            as: {Int32, String, String, String?, String, String?, String?, Int32, String}
          )

        pub_date = !date || date == "" ? nil : date
        if pub_date
          pub_date = Time.parse_utc(date, "%Y-%m-%d").to_s("%Y-%m-%d")
          friendly_date = Time.parse_utc(date, "%Y-%m-%d").to_s("%d %B %Y")
        end

        return {
          "id"            => id,
          "slug"          => slug,
          "title"         => title,
          "date"          => pub_date,
          "friendly_date" => friendly_date,
          "tags"          => tags,
          "image"         => image,
          "imageclass"    => imageclass,
          "draft"         => draft,
          "md"            => md,
        }
      rescue DB::NoResultsError
        return nil
      end
    end
  end

  def publish_article(
    article_id,
    slug,
    title,
    date,
    tags,
    main_image,
    image_class,
    md
  )
    # p! article_id,
    # slug,
    # title,
    # date,
    # tags,
    # main_image,
    # image_class,
    # md
    DB.open "sqlite3://./crw.db" do |db|
      begin
        db.exec("UPDATE articles " \
                "SET slug = ?, title = ?, date = ?, tags = ?, " \
                "main_image = ?, image_class = ?, draft = ?, content = ? WHERE id = ?;",
          slug, title, date, tags, main_image, image_class, 0, md, article_id
        )
      rescue ex
        return nil
      end
    end
  end

  def unpublish_article(article_id)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        db.exec "UPDATE articles " \
                "SET draft = 1 WHERE id = ?;",
          article_id
      rescue ex
        puts ex
        return nil
      end
    end
  end

  def save_article(slug, title, date, tags, main_image, image_class, draft, md)
    DB.open "sqlite3://./crw.db" do |db|
      db.exec "UPDATE articles " \
              "SET slug = ?, title = ?, tags = ?, date = ?, main_image = ?, image_class = ?, draft = ?, content = ?;",
        slug, title, tags, date, main_image, image_class, draft, md
    end
  end

end