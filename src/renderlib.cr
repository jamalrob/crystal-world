module CrystalWorld
    module RenderLib

        private def self.get_value(fm, name)
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

        def self.parse_frontmatter(fm)
            title = self.get_value(fm, "title")
            date = self.get_value(fm, "date")
            tags = self.get_value(fm, "tags")
            image = self.get_value(fm, "image")
            imageclass = self.get_value(fm, "imageClass")

            parsed = {
                "title" => title,
                "date" => date,
                "tags" => tags,
                "image" => image,
                "imageclass" => imageclass,
            }
            parsed
        end

        macro render_page(ctx, page_template, title)
            content = ECR.render({{page_template}})
            title = {{title}}
            header = ECR.render "src/templates/components/header.ecr"
            error_msg = nil
            populated_layout = ECR.render "src/templates/layouts/base.ecr"
            ctx.response.content_type = "text/html; charset=UTF-8"
            ctx.response.print populated_layout
        end

        def self.render_article(ctx, article)
            error_msg = nil
            content = ECR.render "src/templates/components/article.ecr"
            title = article["title"]
            header = ECR.render "src/templates/components/header.ecr"
            populated_layout = ECR.render "src/templates/layouts/base.ecr"
            ctx.response.content_type = "text/html; charset=UTF-8"
            ctx.response.print populated_layout
        end

        macro render_error(ctx, msg, status)
            title = {{msg}}
            error_msg = {{msg}}
            content = "Sorry about that."
            header = ECR.render "src/templates/components/header.ecr"
            populated_layout = ECR.render "src/templates/layouts/base.ecr"
            ctx.response.content_type = "text/html; charset=UTF-8"
            ctx.response.status = {{status}}
            ctx.response.print populated_layout
        end

    end
end