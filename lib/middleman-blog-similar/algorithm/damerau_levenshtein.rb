require 'damerau-levenshtein'

class Middleman::Blog::Similar::Algorithm::DamerauLevenshtein < ::Middleman::Blog::Similar::Algorithm
  def distance(a,b)
    ::DamerauLevenshtein.distance(a,b)
  end
end
