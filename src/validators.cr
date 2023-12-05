module CrystalWorld::Validators
  extend self

  def validate_slug(value, article_id)
    error = {"value" => value} of String => String | Bool
    if !value.match /^#{SLUG_PATTERN}$/
      error_message = "Only lower case letters, numbers, and hyphens"
      error.merge!({
        "error_message" => "Only lower case letters, numbers, and hyphens",
        "value" => value,
        "show_as_error" => true
      })
    else
      articles = Data.get_articles_by_slug(value, exclude_article_id: article_id.to_i)
      if !articles.empty?
        r = Random.new
        error.merge!({
          "error_message" => "Duplicate slug found and unique ID added",
          "value" => "#{value}-#{r.hex(3)}",
          "show_as_error" => false
        })
      end
    end
    return error
  end

  def validate_date(value)
    error = {"value" => value} of String => String | Bool
    begin
      Time.parse_utc(value, "%Y-%m-%d").to_s("%Y-%m-%d")
    rescue Time::Format::Error
      error.merge!({
        "error_message" => "Please enter a valid date",
        "value" => value,
        "show_as_error" => true
      })
    end
    return error
  end

  def validate_tags(value)
    error = {"value" => value} of String => String | Bool
    error.merge!({
        "error_message" => "Please enter some better tags!",
        "value" => value,
        "show_as_error" => true
    })
    return error
  end

end