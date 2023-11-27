module CrystalWorld
  extend self

  class User

    def self.is_authenticated(sessionid=nil)
      if sessionid
        if DataLib.get_user(sessionid: sessionid)
          return true
        end
      end
      return false
    end

    def self.login(id, sessionid, csrftoken)
      DataLib.update_user_session(
        id: id,
        sessionid: sessionid,
        new_csrf_token: csrftoken,
      )
    end

    def self.logout(sessionid)
      DataLib.delete_user_session(
        sessionid: sessionid
      )
    end

  end

end