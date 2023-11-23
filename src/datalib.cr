class DataLib

    def self.create_article(slug, title, tags, date, image, imageClass, draft, content)
        # insert into articles (slug, title, tags, date, image, imageClass, draft, content
        DB.open "sqlite3://./crystalworld.db" do |db|
            db.exec "insert into articles " \
                    "(slug, title, tags, date, image, imageClass, draft, content) values " \
                    "(?, ?, ?, ?, ?, ?, ?, ?)",
                    slug, title, tags, date, image, imageClass, draft, content
        end
    end

    def self.get_article(slug)
        DB.open "sqlite3://./crystalworld.db" do |db|
            #slug, title, tags, date, image, imageclass, draft, content
            begin
                rs = db.query_one   "select slug, title, tags, date, image, imageClass, draft, content " \
                                    "from articles where slug = ? order by date desc limit 1",
                                    slug,
                                    as: {String, String, String, String, Int32, String, Int32, String}
            rescue DB::NoResultsError
                puts "No article found"
                return nil
            end

            p! rs

            #return {
            #    "slug" => slug,
            #    "title" => title,
            #    "date" => date,
            #    "tags" => tags,
            #    "image" => image,
            #    "imageclass" => imageclass,
            #    "draft" => draft,
            #    "md" => content,
            #}

        end
    end

end