module CrystalWorld::Data::Pages
  extend self

  def get_pages(include_drafts=false, order_by="title ASC")
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String | Array(String) | Int32 | Nil)
      where = "WHERE deleted = 0 "
      if !include_drafts
        where += "AND draft = 0 AND date <= DATETIME('now') "
      end
      query = "SELECT id, slug, title, date_created, draft FROM pages " \
              "#{where} ORDER BY #{order_by};"

      results = db.query_all(
        query,
        as: { Int32, String, String, String?, String }
      )

      results.each do |result|
        this_row = {
          "id"    => result[0],
          "slug"  => result[1],
          "title" => result[2],
          "draft" => result[4],
        }
        articles.push(this_row)
      end
      return articles
    end
  end

  def get_header_pages()
    DB.open "sqlite3://./crw.db" do |db|
      articles = [] of Hash(String, String)
      query = "SELECT slug, title FROM pages " \
              "WHERE in_header_menu = 1 AND deleted = 0 ORDER BY title ASC;"

      results = db.query_all(
        query,
        as: { String, String }
      )

      results.each do |result|
        this_row = {
          "slug"  => result[0],
          "title" => result[1],
        }
        #articles[result[0]] = this_row
        articles.push(this_row)
      end
      return articles
    end
  end

  def get_page(slug : String, return_draft : Bool = false)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        anddrafts = ""
        if return_draft
          anddrafts = "AND draft = 0 "
        end

        id, slug, title, image, imageclass, draft, md =
          db.query_one("SELECT id, slug, title, main_image, " \
                        "image_class, draft, content " \
                        "FROM pages WHERE slug = ? #{anddrafts}LIMIT 1;",
            slug,
            as: {Int32, String, String, String?, String, Int32, String}
          )

        return {
          "id"            => id,
          "slug"          => slug,
          "title"         => title,
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

end