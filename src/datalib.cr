module CrystalWorld
    module DataLib

        def self.create_article(slug, title, tags, date, image, imageClass, draft, content)
            # insert into articles (slug, title, tags, date, image, imageClass, draft, content
            DB.open "sqlite3://./crystalworld.db" do |db|
                db.exec "INSERT INTO articles " \
                        "(slug, title, tags, date, image, imageClass, draft, content) VALUES " \
                        "(?, ?, ?, ?, ?, ?, ?, ?)",
                        slug, title, tags, date, image, imageClass, draft, content
            end
        end

        #def self.get_tags

        def self.get_articles
            DB.open "sqlite3://./crystalworld.db" do |db|
                articles = [] of Hash(String, String)
                begin
                    results =  db.query_all "SELECT slug, title, date, tags FROM articles ORDER BY date DESC",
                            as: {String, String, String, String}
                rescue DB::NoResultsError
                    puts "No articles found"
                    return [] of String
                end

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
                    "image" => image,
                    "imageclass" => imageclass,
                    "draft" => draft,
                    "md" => md,
                }

            end
        end

    end
end