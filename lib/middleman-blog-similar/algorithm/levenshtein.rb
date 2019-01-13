require 'levenshtein'

class Middleman::Blog::Similar::Algorithm::Levenshtein < ::Middleman::Blog::Similar::Algorithm
  def distance(a,b)
    ::Levenshtein.distance(a,b)
  end
end
