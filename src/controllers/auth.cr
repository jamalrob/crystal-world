module CrystalWorld::Controllers::Auth
  extend self

  def create_user(ctx)
    params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
    username = params["username"]
    first_name = params["first_name"]
    last_name = params["last_name"]
    Data::Users.create_user(
      username: username,
      first_name: first_name,
      last_name: last_name
    )
  end

  def do_register(ctx)
    params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
    invite_key = params["invite_key"]
    username = params["username"]
    password = params["password"]
    if u = Data::Users.get_user(username, invite_key)
      Data::Users.update_password u["id"].as(Int32), Argon2::Password.create(password)
      self.do_login(ctx)
    end
  end

  def do_login(ctx)
    params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
    username = params["username"]
    password = params["password"]
    if u = Data::Users.get_user(username: username)
      begin
        res = Argon2::Password.verify_password(password, u["password"].to_s)
      rescue ex
        puts "Bad credentials"
      end

      if res == Argon2::Response::ARGON2_OK
        sessionid = Random::Secure.hex(16)
        csrftoken = Random::Secure.hex(16)
        ctx.response.cookies["sessionid"] = HTTP::Cookie.new(
          name: "sessionid",
          value: sessionid,
          path: "/",
          max_age: Time::Span.new(days: 30),
          secure: false,
          samesite: HTTP::Cookie::SameSite.new(1),
          http_only: true
        )
        ctx.response.cookies["csrftoken"] = HTTP::Cookie.new(
          name: "csrftoken",
          value: csrftoken,
          path: "/",
          max_age: Time::Span.new(days: 30),
          secure: false,
          samesite: HTTP::Cookie::SameSite.new(1),
          http_only: true,
        )
        Data::Users.update_user_session(
          id: u["id"],
          sessionid: sessionid,
          new_csrf_token: csrftoken,
        )

        # BASIC REDIRECT
        # ctx.response.redirect "/admin/articles"

        # BASIC REDIRECT FOR HTMX REQUEST
        # Use this because we want admin-specific js files to load in the head
        ctx.response.headers["HX-Redirect"] = "/admin/articles"

        # REDIRECT FOR HTMX REQUEST, REPLACING ONLY A PART OF THE PAGE
        # (new url pushed to the history automatically)
        #ctx.response.headers["HX-Location"] = %({"path": "/admin/articles", "target": "body"})
        return
      end
    end
    ctx.response.respond_with_status(401)
  end

  def do_logout(ctx)
    if u = Controllers::Admin.authenticated_user(ctx)
      #
      # SETTING A COOKIE'S EXPIRES IN THE PAST PROMPTS THE BROWSER TO DELETE IT
      # NOTE: These cookies still need the samesite parameter
      # or else the browser complains
      #
      session_cookie = HTTP::Cookie.new(
        name: "sessionid",
        value: "",
        expires: Time.utc - 1.day,
        samesite: HTTP::Cookie::SameSite.new(1),
      )
      csrf_cookie = HTTP::Cookie.new(
        name: "csrftoken",
        value: "",
        expires: Time.utc - 1.day,
        samesite: HTTP::Cookie::SameSite.new(1)
      )
      ctx.response.headers["Set-Cookie"] = [
        session_cookie.to_set_cookie_header,
        csrf_cookie.to_set_cookie_header,
      ]
      ctx.response.headers["HX-Location"] = %({"path": "/", "target": "body"})
      Data::Users.delete_user_session(
        sessionid: u["sessionid"]
      )
      return
    end
    ctx.response.redirect "/"
  end
end
