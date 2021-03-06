require 'middleman-blog-similar/blog_article_extensions'
require 'middleman-blog-similar/helpers'
require 'middleman-blog-similar/algorithm'

module Middleman
  module Blog
    class SimilarExtension < ::Middleman::Extension

      option :algorithm, :word_frequency, 'Similar lookup algorithm'
      option :cache, true, 'Cache distance calc in memory'

      self.defined_helpers = [ Middleman::Blog::Similar::Helpers ]

      def after_configuration
        require 'middleman-blog/blog_article'
        @app.config[:content_css_selector] = options[:content_css_selector].try(:to_s) || 'article'
        algorithm = options[:algorithm].to_s
        begin
          require "middleman-blog-similar/algorithm/#{algorithm}"
          ns = ::Middleman::Blog::Similar::Algorithm
          algorithm.split('/').each do|n|
            ns = ns.const_get n.camelize
          end
          ns.cache = options[:cache]
          @app.config[:similarity_algorithm] = ns
        rescue LoadError => e
          @app.logger.error "Requested similar algorithm '#{algorithm}' not found."
          raise e
        end
        ::Middleman::Sitemap::Resource.send :include, Middleman::Blog::Similar::BlogArticleExtensions
      end

    end
  end
end
