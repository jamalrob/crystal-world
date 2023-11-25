module CrystalWorld
    module DataLib
        extend self

        # NOTE: Without an ORM, there is no column name -> column index mapping,
        # so it has to be done manually

        def create_article(slug, title, tags, date, image, imageClass, draft, content)
            DB.open "sqlite3://./crystalworld.db" do |db|
                db.exec "INSERT INTO articles " \
                        "(slug, title, tags, date, image, imageClass, draft, content) VALUES " \
                        "(?, ?, ?, ?, ?, ?, ?, ?)",
                        slug, title, tags, date, image, imageClass, draft, content
            end
        end

        def get_tags
            all_tags = [] of String
            DB.open "sqlite3://./crystalworld.db" do |db|
                tag_vals = db.query_all "SELECT tags from articles WHERE draft = 0", as: {String}
                tag_vals.each do |row|
                    all_tags = all_tags | row.gsub(", ", ",").split(",")
                end
            end
            all_tags
        end

        def get_articles_for_tag(tag)
            DB.open "sqlite3://./crystalworld.db" do |db|
                articles = [] of Hash(String, String)
                begin
                    results =   db.query_all "SELECT slug, title, date, tags FROM articles WHERE tags LIKE '%' || ? || '%' ORDER BY date DESC",
                                tag,
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

        def get_articles
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

        def get_article(slug)
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