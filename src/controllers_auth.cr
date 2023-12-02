module CrystalWorld::AuthControllers
  extend self

  def do_login(ctx)
    params = URI::Params.parse(ctx.request.body.not_nil!.gets_to_end)
    username = params["username"] || ""
    password = params["password"] || ""
    if u = Data.get_user(username)
      begin
        res = Argon2::Password.verify_password(password, u["password"].to_s)
        if res == Argon2::Response::ARGON2_OK
          # Set new sessionid and CSRF for this session
          sessionid = Random::Secure.hex(16)
          csrftoken = Random::Secure.hex(16)
          ctx.response.cookies["sessionid"] = HTTP::Cookie.new(
            name: "sessionid",
            value: sessionid,
            path: "/",
            max_age: Time::Span.new(hours: 12),
            secure: false,
            samesite: HTTP::Cookie::SameSite.new(1),
            http_only: true
          )
          ctx.response.cookies["csrftoken"] = HTTP::Cookie.new(
            name: "csrftoken",
            value: csrftoken,
            path: "/",
            max_age: Time::Span.new(hours: 12),
            secure: false,
            samesite: HTTP::Cookie::SameSite.new(1),
            http_only: true,
          )
          Data.update_user_session(
            id: u["id"],
            sessionid: sessionid,
            new_csrf_token: csrftoken,
          )

          # BASIC REDIRECT
          # ctx.response.redirect "/admin/articles"

          # BASIC REDIRECT FOR HTMX REQUEST
          # ctx.response.headers["HX-Redirect"] = "/admin/articles"

          # REDIRECT FOR HTMX REQUEST, REPLACING ONLY A PART OF THE PAGE
          # (new url pushed to the history automatically)
          ctx.response.headers["HX-Location"] = %({"path": "/admin/articles", "target": "body"})
          return
        end
      rescue ex
        puts "Bad credentials"
      end
    end

    # Adding an error status to the response here trips up
    # the HTMX replacement, so we don't do it
    ctx.response.print "Your credentials were not recognized."
  end


  def do_logout(ctx)
    if u = AdminControllers.authenticated_user(ctx)
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
      Data.delete_user_session(
        sessionid: u["sessionid"]
      )
      return
    end
    ctx.response.redirect "/"
  end

end