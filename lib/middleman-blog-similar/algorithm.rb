require "sqlite3"
require 'digest'

class Middleman::Blog::Similar::Algorithm
  @@db_name = "middleman-blog-similar"
  @@semaphore = Mutex.new
  @@should_cache = false
  attr_reader :article, :css_selector, :app
  def initialize(article, css_selector)
    @article = article
    @css_selector = css_selector
  end
  def self.cache= should_cache
    puts "enabled middleman-blog-similar caching: #{should_cache}"
    @@should_cache = should_cache
  end
  def self._db_path
    @@db_path ||= ".tmp/#{@@db_name}.db".tap do |path|
      `mkdir -p .tmp`
    end
  end
  def self._db
    @@db ||= SQLite3::Database.new(_db_path).tap do |db|
      db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS cache (
        id text,
        val text
      )
      SQL
    end
  end
  def self._find key
    @@semaphore.synchronize {
      _db.execute("SELECT * FROM cache WHERE id = ?", key).tap do |res|
        unless res && res.length > 0
          return nil
        end
      end.first.last.to_i
    }
  end
  def self._set key, val
    @@semaphore.synchronize {
      _db.execute("BEGIN TRANSACTION")
      _db.execute("DELETE FROM cache WHERE id = ?", key)
      _db.execute("INSERT INTO cache (id, val) VALUES (?,?)", key, val)
      _db.execute("END")
    }
  end
  def article_text article
    if (res = Nokogiri::XML(article.body).at_css(css_selector).try(:inner_text)).blank?
      res = Nokogiri::XML("<article>#{article.body}</article>").at_css(css_selector).try(:inner_text)
    end
    if res.blank?
      raise "#{article.title} has no content"
    end
    res
  end
  def article_hash article
    return Digest::SHA256.hexdigest(article_text(article))[0..16]
  end
  def similar_articles
    @similar_articles ||= articles
      .reject{|a| a.url == article.url || a.data.published == false}
      .map do |article_b|
        article_a, article_b = [@article, article_b].sort_by{|a| article_hash(a)}
        # key is the hash of this article and the compared article
        key = [article_hash(article_a), article_hash(article_b)].join('-')
        dist = self.class._find(key)
        if @@should_cache && !dist
          dist = distance(article_text(article_a), article_text(article_b))
          puts "Blog Similar cache miss (updated distance: #{dist}):\n    - #{article_a.title}\n    - #{article_b.title}"
          self.class._set(key, dist)
        end
        #puts "dist: #{dist}"
        #dist ||= self.class._find(key) || distance(a)
        [dist, article_b]
      end.sort{|x, y| x[0] <=> y[0]  }
      .map{|a| a[1] }
  end
  def distance
    0.0
  end
  def articles
    article.blog_controller.data.articles
  end
end
