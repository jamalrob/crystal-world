module CrystalWorld::Data::Users
  extend self

  def create_user(username : String, first_name : String, last_name : String)
    DB.open "sqlite3://./crw.db" do |db|
      db.exec "INSERT INTO users (username, first_name, last_name)" \
              "VALUES (?, ?, ?);",
              username, first_name, last_name
    end
  end

  def update_password(id : Int32, new_password : String)
    DB.open "sqlite3://./crw.db" do |db|
      db.exec "UPDATE users " \
              "SET password = ? " \
              "WHERE id = ?;",
              new_password, id
    end
  end

  def get_user(username : String, invite_key : String)
    DB.open "sqlite3://./crw.db" do |db|

      begin
        id, password, first_name, last_name, sessionid, csrftoken = db.query_one(
          "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
          "FROM users WHERE username = ? AND invite_key = ?;",
          username, invite_key,
          as: {Int32, String, String?, String?, String?, String?}
        )
      rescue DB::NoResultsError
        puts "No results"
        return nil
      end

      return {
        "id"         => id,
        "password"   => password,
        "first_name" => first_name,
        "last_name"  => last_name,
        "sessionid"  => sessionid,
      }

    end
  end

  def get_user(sessionid = nil, username = nil)
    DB.open "sqlite3://./crw.db" do |db|
      begin
        if sessionid
          where = "WHERE sessionid = ? LIMIT 1"
          by = sessionid
        elsif username
          where = "WHERE username = ? LIMIT 1"
          by = username
        end

        query = "SELECT id, password, first_name, last_name, sessionid, csrftoken " \
                "FROM users #{where};"

        userid, password, first_name, last_name, sessionid, csrftoken = db.query_one(
          query,
          by,
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

  def get_users()
    DB.open "sqlite3://./crw.db" do |db|
      users = [] of Hash(String, String | Bool | Int32 | Nil)
      results = db.query_all(
        "SELECT id, username, password, first_name, last_name FROM users;",
        as: { Int32, String, String?, String?, String? }
      )

      results.each do |result|
        has_password = result[2] != nil ? true : false
        #p! has_password
        #puts "has_password is nil: #{has_password == nil}"
        this_row = {
          "id"            => result[0],
          "username"      => result[1],
          "has_password"  => has_password,
          "first_name"    => result[3],
          "last_name"     => result[4],
        }
        #articles[result[0]] = this_row
        users.push(this_row)
      end
      return users
    end
  end

end