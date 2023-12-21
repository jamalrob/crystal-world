module CrystalWorld::Data
  extend self

  def get_settings
    DB.open "sqlite3://./crw.db" do |db|

      begin
        id, bg_color, fg_color, link_color, link_hover_color = db.query_one(
          "SELECT id, bg_color, fg_color, link_color, link_hover_color " \
          "FROM settings WHERE id = 1;",
          as: {Int32, String?, String?, String?, String?}
        )
      rescue DB::NoResultsError
        puts "No results"
        return nil
      end

      return {
        "id"                => id,
        "bg_color"          => bg_color,
        "fg_color"          => fg_color,
        "link_color"        => link_color,
        "link_hover_color"  => link_hover_color,
      }

    end
  end

end