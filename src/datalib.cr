class DataLib

    def self.create_article(slug, title, tags, date, image, imageClass, draft, content)
        # insert into articles (slug, title, tags, date, image, imageClass, draft, content
        DB.open "sqlite3://./crystalworld.db" do |db|
            db.exec "INSERT INTO articles " \
                    "(slug, title, tags, date, image, imageClass, draft, content) VALUES " \
                    "(?, ?, ?, ?, ?, ?, ?, ?)",
                    slug, title, tags, date, image, imageClass, draft, content
        end
    end

    def self.get_articles()
        DB.open "sqlite3://./crystalworld.db" do |db|
            articles = [] of Hash(String, String)
            results =  db.query_all "SELECT slug, title, date, tags FROM articles ORDER BY date DESC",
                        as: {String, String, String, String}

            results.each do |result|
                this_row = {
                    "slug" => result[0],
                    "title" => result[1],
                    "date" => result[2],
                    "tags" => result[3],
                }
                articles.<<(this_row)
            end
            return articles
        end
    end

    def self.get_article(slug)
        DB.open "sqlite3://./crystalworld.db" do |db|
            #slug, title, tags, date, image, imageclass, draft, content
            begin
                slug, title, tags, date, image, imageclass, draft, md =
                                    db.query_one "SELECT slug, title, tags, date, image, imageClass, draft, content " \
                                    "FROM articles WHERE slug = ? LIMIT 1",
                                    slug,
                                    as: {String, String, String, String, Int32, String, Int32, String}
            rescue DB::NoResultsError
                puts "No article found"
                return nil
            end

            return {
                "slug" => slug,
                "title" => title,
                "date" => date,
                "tags" => tags,
                "image" => image, # casts to bool
                "imageclass" => imageclass,
                "draft" => draft, # casts to bool
                "md" => md,
            }

        end
    end

end