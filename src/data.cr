module CrystalWorld::Data
  extend self

    def get_user(username=nil, sessionid=nil)
      DB.open "sqlite3://./crw.db" do |db|
        begin
          if username
            userid, password, first_name, last_name, sessionid, csrftoken =
              db.query_one( "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                            "FROM users WHERE username = ? LIMIT 1;",
                username,
                as: {Int32, String, String?, String?, String?, String?}
              )
          elsif sessionid
            userid, password, first_name, last_name, sessionid, csrftoken =
              db.query_one( "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
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
              db.query_one( "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
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


    def create_article(slug, title, tags, date, image, imageClass, draft, content)
      #
      # ******* OUT OF DATE *******
      #
      DB.open "sqlite3://./crw.db" do |db|
        db.exec "INSERT INTO articles " \
                "(slug, title, tags, date, image, imageClass, draft, content) VALUES " \
                "(?, ?, ?, ?, ?, ?, ?, ?);",
          slug, title, tags, date, image, imageClass, draft, content
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


    def get_articles(include_drafts=false, order_by="date DESC")

      DB.open "sqlite3://./crw.db" do |db|
        articles = [] of Hash(String, String | Array(String) | Int32)
        begin
          if include_drafts
            results = (db.query_all "SELECT slug, title, date, tags, draft FROM articles " \
                                    "ORDER BY #{order_by};",
              as: {String, String, String, String, Int32}
            )
          else
            results = (db.query_all "SELECT slug, title, date, tags, draft FROM articles " \
                                    "WHERE draft = 0 ORDER BY #{order_by};",
              as: {String, String, String, String, Int32}
            )
          end
          results.each do |result|
            dt = result[2].split(' ')[0]
            day, month, year = dt.split('-')[2].to_i, dt.split('-')[1].to_i, dt.split('-')[0].to_i
            this_row = {
              "slug"          => result[0],
              "title"         => result[1],
              "date"          => Time.utc(year, month, day).to_s("%Y-%m-%d"),
              "friendly_date" => Time.utc(year, month, day).to_s("%d %B %Y"),
              "draft"         => result[4],
              "tags"          => result[3].delete(' ').split(","),
            }
            articles.push(this_row)
          end
          return articles
        rescue DB::NoResultsError
          return nil
        end
      end

    end


    def get_articles_for_tag(tag)

      DB.open "sqlite3://./crw.db" do |db|
        articles = [] of Hash(String, String)
        begin
          results = db.query_all( "SELECT slug, title, date, tags FROM articles " \
                                  "WHERE draft = 0 AND tags LIKE '%' || ? || '%' " \
                                  "ORDER BY date DESC;",
                                  tag,
                                  as: {String, String, String, String}
          )
          results.each do |result|
            dt = result[2].split(' ')[0]
            day, month, year = dt.split('-')[2].to_i, dt.split('-')[1].to_i, dt.split('-')[0].to_i
            this_row = {
              "slug"          => result[0],
              "title"         => result[1],
              "date"          => Time.utc(year, month, day).to_s("%Y-%m-%d"),
              "friendly_date" => Time.utc(year, month, day).to_s("%d %B %Y")
            }
            articles.<<(this_row)
          end
          return articles.empty? ? nil : articles
        rescue DB::NoResultsError
          return nil
        end
      end

    end


    def get_article(slug, return_draft=false)

      DB.open "sqlite3://./crw.db" do |db|
        begin
          if return_draft
            id, slug, title, tags, date, image, imageclass, draft, md =
            db.query_one( "SELECT id, slug, title, tags, date, main_image, " \
                          "image_class, draft, content " \
                          "FROM articles WHERE slug = ? LIMIT 1;",
              slug,
              as: {Int32, String, String, String?, String, String?, String?, Int32, String}
            )
          else
            id, slug, title, tags, date, image, imageclass, draft, md =
              db.query_one( "SELECT id, slug, title, tags, date, main_image, " \
                            "image_class, draft, content " \
                            "FROM articles WHERE slug = ? AND draft = 0 LIMIT 1;",
                slug,
                as: {Int32, String, String, String?, String, String?, String?, Int32, String}
              )
          end
          dt = date.split(' ')[0]
          day, month, year = dt.split('-')[2].to_i, dt.split('-')[1].to_i, dt.split('-')[0].to_i

          return {
            "id"            => id,
            "slug"          => slug,
            "title"         => title,
            "date"          => Time.utc(year, month, day).to_s("%Y-%m-%d"),
            "friendly_date" => Time.utc(year, month, day).to_s("%d %B %Y"),
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
      #p! article_id,
      #slug,
      #title,
      #date,
      #tags,
      #main_image,
      #image_class,
      #md
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