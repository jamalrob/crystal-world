module CrystalWorld::Validators
  extend self

  def validate_slug(value, article_id)
    hash = {
      "name" => "slug",
      "value" => value,
      "article_id" => article_id
    } of String => String | Bool | Hash(String, String | Bool)
    if !value.match /^#{SLUG_PATTERN}$/
      hash["publish"] = false
      error = {
        "message" => "Only lower case letters, numbers, and hyphens",
        "show_as_error" => true
      }
    else
      hash["publish"] = true
      articles = Data.get_articles_by_slug(value, exclude_article_id: article_id.to_i)
      if !articles.empty?
        #
        # DUPLICATE SLUG
        #
        # Update the value to send back
        #
        # Although we're calling this an error,
        # if it's the controller's publish method
        # that's calling, we don't want to stop
        # publication in this instance, since
        # we're making the slug unique by appending
        # a random string.
        #
        # So we leave hash["publish"] = true
        #
        hash["value"] = "#{value}-#{Random.new.hex(4)}"
        hash["error"] = {
          "message" => "Duplicate slug found and unique ID added",
          "show_as_error" => false
        }
      end
    end
    return hash
  end

  def validate_date(value, article_id)
    hash = {
      "name" => "date",
      "value" => value,
      "article_id" => article_id
    } of String => String | Bool | Hash(String, String | Bool)
    begin
      Time.parse_utc(value, "%Y-%m-%d")
    rescue Time::Format::Error
      hash["publish"] = false
      hash["error"] = {
        "message" => "Please enter a valid date",
        "show_as_error" => true
      }
      return hash
    end
    hash["publish"] = true
    return hash
  end

  def validate_tags(value)

    #
    # TODO: sanitize
    #

    error = {
      "name" => "tags",
      "value" => value
    } of String => String | Bool

    #error.merge!({
    #    "error_message" => "Please enter some better tags!",
    #    "value" => value,
    #    "show_as_error" => true
    #})
    return error
  end

end