module CrystalWorld::Data
  extend self

  def get_user(username = nil, sessionid = nil)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        if username
          userid, password, first_name, last_name, sessionid, csrftoken =
            db.query_one("SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                         "FROM users WHERE username = ? LIMIT 1;",
              username,
              as: {Int32, String, String?, String?, String?, String?}
            )
        elsif sessionid
          userid, password, first_name, last_name, sessionid, csrftoken =
            db.query_one("SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                         "FROM users WHERE sessionid = ? LIMIT 1;",
              sessionid,
              as: {Int32, String, String?, String?, String?, String?}
            )
        end
      rescue DB::NoResultsError
        puts "No results"
        return nil
      end
      return {
        "id"         => userid,
        "password"   => password,
        "first_name" => first_name,
        "last_name"  => last_name,
        "sessionid"  => sessionid,
      }
    end
  end

  def get_authenticated_user(sessionid, csrftoken)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        userid, password, first_name, last_name, sessionid, csrftoken =
          db.query_one("SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                       "FROM users WHERE sessionid = ? AND csrftoken = ? LIMIT 1;",
            sessionid, csrftoken,
            as: {Int32, String, String?, String?, String?, String?}
          )
      rescue DB::NoResultsError
        puts "No results"
        return nil
      end
      return {
        "id"         => userid,
        "password"   => password,
        "first_name" => first_name,
        "last_name"  => last_name,
        "sessionid"  => sessionid,
        "csrftoken"  => csrftoken,
      }
    end
  end

  def update_user_session(id, sessionid, new_csrf_token)
    DB.open "sqlite3://./crw.db" do |db|
      if id
        db.exec "UPDATE users " \
                "SET csrftoken = ?, sessionid = ? " \
                "WHERE id = ?;",
          new_csrf_token, sessionid, id
      end
    end
  end

  def delete_user_session(sessionid)
    DB.open "sqlite3://./crw.db" do |db|
      db.exec "UPDATE users " \
              "SET csrftoken = '', sessionid = '' " \
              "WHERE sessionid = ?;",
        sessionid
    end
  end

  def delete_article(slug)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        return db.exec("DELETE FROM articles where slug = ?", slug)
      rescue e
        puts e.message
      end
    end
  end

  def create_draft
    DB.open "sqlite3://./crw.db" do |db|
      newid = db.query_one( "SELECT seq FROM sqlite_sequence " \
                          "WHERE name = 'articles' LIMIT 1;",
                          as: {Int32}
          ) + 1
      newslug = "new-draft-#{newid}"
      insert = db.exec("INSERT INTO articles " \
              "(slug, title, tags, date, date_created, main_image, image_class, draft, content) " \
              " VALUES (?, ?, ?, ?, DATE('now'), ?, ?, ?, ?);",
        "#{newslug}", "New Draft #{newid}", "", "", "", "", 1, ""
      )
      #return self.get_article(insert.last_insert_id)
      return newslug
    rescue e
      p! e
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
                                  "WHERE slug = ? AND id != ?;",
                                  slug, exclude_article_id,
                                  as: {Int32}
        )
      else
        articles = (db.query_all  "SELECT id " \
                                  "FROM articles " \
                                  "WHERE slug = ?;",
                                  slug,
                                  as: {Int32}
        )
      end
      return articles
    end
  end

  def get_articles(include_drafts=false, order_by="date DESC")
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String | Array(String) | Int32 | Nil)
      begin
        if include_drafts
          results = (db.query_all "SELECT slug, title, date, date_created, tags, draft " \
                                  "FROM articles ORDER BY #{order_by};",
                                  as: {String, String, String?, String, String?, Int32}
            )
        else
          results = (db.query_all "SELECT slug, title, date, date_created, tags, draft " \
                                  "FROM articles WHERE draft = 0 ORDER BY #{order_by};",
                                  as: {String, String, String?, String, String?, Int32}
            )
        end
        results.each do |result|
          pub_date = nil
          pub_date_friendly = nil
          begin
            pub_date = Time.parse_utc(result[2].to_s, "%Y-%m-%d").to_s("%Y-%m-%d")
            pub_date_friendly = Time.parse_utc(result[2].to_s, "%Y-%m-%d").to_s("%d %B %Y")
          rescue e
            puts "Currently not published or bad pub date format"
          end

          tags = result[4]
          if tags
            tags = tags.delete(' ').split(",")
          end
          this_row = {
            "slug"                  => result[0],
            "title"                 => result[1],
            "date"                  => pub_date,
            "friendly_date"         => pub_date_friendly,
            "date_created"          => Time.parse_utc(result[3], "%Y-%m-%d").to_s("%Y-%m-%d"),
            "friendly_date_created" => Time.parse_utc(result[3], "%Y-%m-%d").to_s("%d %B %Y"),
            "draft"                 => result[5],
            "tags"                  => tags,
          }
          articles.push(this_row)
        end
        return articles
      rescue DB::NoResultsError
        puts "No results"
        return nil
      end
    end
  end

  def get_articles_for_tag(tag)
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String)
      begin
        results = db.query_all("SELECT slug, title, date, tags FROM articles " \
                               "WHERE draft = 0 AND tags LIKE '%' || ? || '%' " \
                               "ORDER BY date DESC;",
          tag,
          as: {String, String, String, String}
        )
        results.each do |result|
          this_row = {
            "slug"          => result[0],
            "title"         => result[1],
            "date"          => Time.parse_utc(result[2], "%Y-%m-%d").to_s("%Y-%m-%d"),
            "friendly_date" => Time.parse_utc(result[2], "%Y-%m-%d").to_s("%d %B %Y"),
          }
          articles.<<(this_row)
        end
        return articles.empty? ? nil : articles
      rescue DB::NoResultsError
        return nil
      end
    end
  end

  def get_article(id)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        id, slug, title, tags, date, image, imageclass, draft, md =
          db.query_one("SELECT id, slug, title, tags, date, main_image, " \
                        "image_class, draft, content " \
                        "FROM articles WHERE id = ? LIMIT 1;",
                        id,
            as: {Int32, String, String, String?, String, String?, String?, Int32, String}
          )

          return {
          "id"            => id,
          "slug"          => slug,
          "title"         => title,
          "date"          => Time.parse_utc(date, "%Y-%m-%d").to_s("%Y-%m-%d"),
          "friendly_date" => Time.parse_utc(date, "%Y-%m-%d").to_s("%d %B %Y"),
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

  def get_article(slug, return_draft = false)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        if return_draft
          id, slug, title, tags, date, image, imageclass, draft, md =
            db.query_one("SELECT id, slug, title, tags, date, main_image, " \
                         "image_class, draft, content " \
                         "FROM articles WHERE slug = ? LIMIT 1;",
              slug,
              as: {Int32, String, String, String?, String, String?, String?, Int32, String}
            )
        else
          id, slug, title, tags, date, image, imageclass, draft, md =
            db.query_one("SELECT id, slug, title, tags, date, main_image, " \
                         "image_class, draft, content " \
                         "FROM articles WHERE slug = ? AND draft = 0 LIMIT 1;",
              slug,
              as: {Int32, String, String, String?, String, String?, String?, Int32, String}
            )
        end

        pub_date = !date || date == "" ? nil : date
        friendly_date = nil
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
        puts ex
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
