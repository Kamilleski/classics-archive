namespace :all_articles do
  desc 'generates ActiveRecord Relation for all articles in database'
  task generate: :environment do
    ALL_ARTICLES = Article.includes(:tags)
    ALL_AUTHORS =  ALL_ARTICLES.select(&:approved?).map(&:author_full_name).uniq.join(',')
    ALL_PUBLISHERS = ALL_ARTICLES.select(&:approved?).map(&:site_name).uniq.join(',')
    ALL_TAGS = ActsAsTaggableOn::Tag.all.order(taggings_count: :desc).map(&:name)
    APPROVED_TAGS = ALL_ARTICLES.where(approved:true).map{|a| a.tags.map{|t| t.name}}.flatten.uniq
    FEATURED_ARTICLES = ALL_ARTICLES.select{ |a| a.featured? && a.featured_date.between?(1.weeks.ago.to_datetime,(DateTime.now + 1.week)) }

    puts "Articles ActiveRecord dump updated #{Time.now}"
  end
end
