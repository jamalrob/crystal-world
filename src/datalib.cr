require "sqlite3"

module CrystalWorld
  module DataLib
    extend self

    # NOTE: Without an ORM, there is no column name -> column index mapping,
    # so it has to be done manually

    def update_user_session(id, sessionid, new_csrf_token)
      DB.open "sqlite3://./crw.db" do |db|
        if id
          db.exec "UPDATE users " \
                  "SET csrftoken = ?, sessionid = ? " \
                  "WHERE id = ?",
                  new_csrf_token, sessionid, id
        end
      end
    end

    def delete_user_session(sessionid)
      DB.open "sqlite3://./crw.db" do |db|
        db.exec "UPDATE users " \
        "SET csrftoken = '', sessionid = '' " \
        "WHERE sessionid = ?",
        sessionid
      end
    end

    def get_authenticated_user(sessionid, csrftoken)
      DB.open "sqlite3://./crw.db" do |db|
        begin
          userid, password, first_name, last_name, sessionid, csrftoken =
              db.query_one "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                          "FROM users WHERE sessionid = ? AND csrftoken = ? LIMIT 1",
                sessionid, csrftoken,
                as: {Int32, String, String?, String?, String?, String?}
        rescue DB::NoResultsError
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

    def get_user(username=nil, sessionid=nil)
      DB.open "sqlite3://./crw.db" do |db|
        begin
          if username
            userid, password, first_name, last_name, sessionid, csrftoken =
              db.query_one "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                          "FROM users WHERE username = ? LIMIT 1",
                username,
                as: {Int32, String, String?, String?, String?, String?}
          elsif sessionid
            userid, password, first_name, last_name, sessionid, csrftoken =
              db.query_one "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                          "FROM users WHERE sessionid = ? LIMIT 1",
                sessionid,
                as: {Int32, String, String?, String?, String?, String?}
          end
        rescue DB::NoResultsError
          puts "No user found"
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

    def create_article(slug, title, tags, date, image, imageClass, draft, content)
      #
      # ******* OUT OF DATE *******
      #
      DB.open "sqlite3://./crw.db" do |db|
        db.exec "INSERT INTO articles " \
                "(slug, title, tags, date, image, imageClass, draft, content) VALUES " \
                "(?, ?, ?, ?, ?, ?, ?, ?)",
          slug, title, tags, date, image, imageClass, draft, content
      end
    end

    def get_tags
      all_tags = [] of String
      DB.open "sqlite3://./crw.db" do |db|
        tag_vals = db.query_all "SELECT tags from articles WHERE draft = 0", as: {String}
        tag_vals.each do |row|
          all_tags = all_tags | row.delete(' ').split(",")
        end
      end
      return all_tags
    end

    def get_articles_for_tag(tag)
      DB.open "sqlite3://./crw.db" do |db|
        articles = [] of Hash(String, String)
        begin
          results = db.query_all "SELECT slug, title, date, tags FROM articles WHERE tags LIKE '%' || ? || '%' ORDER BY date DESC",
            tag,
            as: {String, String, String, String}
        rescue DB::NoResultsError
          puts "No articles found"
          return [] of String
        end

        results.each do |result|
          this_row = {
            "slug"  => result[0],
            "title" => result[1],
            "date"  => result[2],
            "tags"  => result[3],
          }
          articles.<<(this_row)
        end
        return articles
      end
    end

    def get_articles
      DB.open "sqlite3://./crw.db" do |db|
        articles = [] of Hash(String, String)
        begin
          results = db.query_all "SELECT slug, title, date, tags FROM articles ORDER BY date DESC",
            as: {String, String, String, String}
        rescue DB::NoResultsError
          puts "No articles found"
          return [] of String
        end

        results.each do |result|
          this_row = {
            "slug"  => result[0],
            "title" => result[1],
            "date"  => result[2],
            "tags"  => result[3],
          }
          articles.<<(this_row)
        end
        return articles
      end
    end

    def get_article(slug)
      DB.open "sqlite3://./crw.db" do |db|
        begin
          slug, title, tags, date, image, imageclass, draft, md =
            db.query_one  "SELECT slug, title, tags, date, main_image, " \
                          "image_class, draft, content " \
                          "FROM articles WHERE slug = ? LIMIT 1",
              slug,
              as: {String, String, String?, String, String?, String?, Int32, String}
        rescue DB::NoResultsError
          puts "No article found"
          return nil
        end

        return {
          "slug"       => slug,
          "title"      => title,
          "date"       => date.split(' ')[0],
          "tags"       => tags,
          "image"      => image,
          "imageclass" => imageclass,
          "draft"      => draft,
          "md"         => md,
        }
      end
    end
  end
end
