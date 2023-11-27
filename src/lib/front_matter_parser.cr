module CrystalWorld
  module FrontMatterParser
    extend self

    private def get_value(fm, name)
      find = "#{name}:"
      if !fm.index(find)
        return nil
      end
      value_start = fm.index(find).as(Int32) + find.size
      value_end = fm.index("\n", offset: value_start)
      if !value_end.nil?
        value = fm[value_start..value_end].strip('\n').strip.strip('\'')
      end
      value
    end

    def parse_frontmatter(fm)
      title = self.get_value(fm, "title")
      date = self.get_value(fm, "date")
      tags = self.get_value(fm, "tags")
      image = self.get_value(fm, "image")
      imageclass = self.get_value(fm, "imageClass")

      parsed = {
        "title"      => title,
        "date"       => date,
        "tags"       => tags,
        "image"      => image,
        "imageclass" => imageclass,
      }
      parsed
    end
  end
end
