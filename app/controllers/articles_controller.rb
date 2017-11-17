class ArticlesController < ApplicationController
  include ApplicationHelper
  include Aylien
  include Calais
  include Filter
  include Pagination

  before_action :require_login, only: %i[create edit update destroy manage]

  def new
    if params[:ldid]
      DumpedLink.destroy(params[:ldid]) if DumpedLink.exists?(params[:ldid])
      flash[:success] = 'Added from Link Dump'
    end

    @parsed = article_info(params[:user_url]) if params[:user_url]

    @existing = Article.where(url: @parsed[:url])[0]
    if @existing
      flash[:info] = "Great minds think alike... this article has already been submitted as of #{@existing.created_at.strftime('%e %B %Y')}!"
      redirect_to articles_manage_path
    end

    @article = Article.new
  end

  def create
    params[:article][:calais_tags] = params[:article][:calais_tags].split(',')

    params[:article][:tag_list] = params[:article][:tag_list].map(&:titlecase).join(',')
    @article = Article.new(article_params)
    if @article.save
      if @article.approved
        flash[:success] = "Article '#{@article.title}' by #{@article.author_full_name} added to feed"
      else
        flash[:warning] = "Article '#{@article.title}' by #{@article.author_full_name} submitted for review"
      end
      redirect_to articles_manage_path
    else
      flash[:danger] = "Please re-check information: #{@article.errors.full_messages}"
      Rails.logger.info(@article.errors.inspect)
      render 'new'
    end
  rescue OpenURI::HTTPError, RuntimeError => e
    copy_params = article_params
    copy_params['image'] = 'https://upload.wikimedia.org/wikipedia/en/thumb/1/1f/Paideiainstitutelogo.jpg/250px-Paideiainstitutelogo.jpg'
    copy_params['image_credit'] = 'NEEDS IMAGE AND CREDIT'
    @article_without_image = Article.new(copy_params)
    if @article_without_image.save
      if @article_without_image.approved
        flash[:success] = "Article '#{@article.title}' by #{@article.author_full_name} added to feed"
      else
        flash[:warning] = "Article '#{@article_without_image.title}' by #{@article_without_image.author_full_name} submitted for review"
      end
      redirect_to articles_manage_path
    else
      flash[:danger] = "Please re-check information: #{@article_without_image.errors.full_messages}"
      Rails.logger.info(@article_without_image.errors.inspect)
      render 'new'
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    params[:article][:tag_list] = params[:article][:tag_list].join(',')
    if @article.update(article_params)
      flash[:success] = "Article '#{@article.title}' by #{@article.author_full_name} added to feed"
      redirect_to articles_manage_path
    else
      flash[:danger] = "Please re-check information: #{@article.errors.full_messages}"
      Rails.logger.info(@article.errors.inspect)
      render 'edit'
    end
  end

  def index
    @filterrific = initialize_filterrific(
      Article.where(approved: true),
      params[:filterrific],
      select_options: {
        sorted_by: Article.options_for_sorted_by,
        of_type: CONTENT_TYPES
      }
    ) || return
    @all_articles = @filterrific.find
    @featured = params[:filterrific] ? [] : @all_articles.select{ |a| a.featured? && a.featured_date.between?(1.weeks.ago.to_datetime,(DateTime.now + 1.week)) }
    @all_articles -= @featured
    @articles = Kaminari.paginate_array(@all_articles).page(params[:page])
                        .per(15)
                        .as_json(
                          methods: %i[
                            image
                            tags
                            pretty_date
                          ]
                        )
    @featured_articles = @featured.as_json(methods: %i[
                                             image
                                             tags
                                             pretty_date
                                           ])
    @query = URI.encode_www_form @filterrific.to_hash
    @all_tags = ActsAsTaggableOn::Tag.all.order(taggings_count: :desc).map(&:name)
    @all_authors = Article.all.select(&:approved?).map(&:author_full_name).uniq.join(',')
    @all_publishers = Article.all.select(&:approved?).map(&:site_name).uniq.join(',')
    @p = params[:page].to_i.zero? ? 1 : params[:page].to_i
    @page_entries_info = paginate @all_articles, @p
    @current_filters = describe_filters(@filterrific.to_hash)
    @sorted = @filterrific.to_hash['sorted_by'] || nil
    respond_to do |format|
      format.html
      format.js
      format.json { render json: @articles, include: [:tags, :image] }
    end
    rescue ActiveRecord::RecordNotFound => e
      puts "Had to reset filterrific params: #{ e.message }"
      redirect_to(reset_filterrific_url(format: :html)) and return
  end

  def destroy
    Article.find(params[:id]).destroy
    flash[:success] = "Article removed"
    redirect_to articles_manage_path
  end

  def manage
    @approved_articles = Article.all.where(approved: true)
    @need_approval = Article.all.where(approved: false)
    @dumped_links = DumpedLink.all.where(rejected: nil)
  end

  private

  def article_params
    params.require(:article).permit(
      :title,
      :author_first_name,
      :author_last_name,
      :type_of,
      :image,
      :featured,
      :featured_date,
      :image_credit,
      :description,
      :site_name,
      :url,
      :published_time,
      :tag_list,
      :calais_tags,
      :board_list,
      :site_text,
      :boilerpipe_text,
      :approved,
      :approved_by,
      :submitted_by,
      calais_tags: []
    ).permit!
  end

  def logged_in?
    !current_user.nil?
  end

  def require_login
    unless logged_in?
      flash[:danger] = "You must be signed in to access this section"
      redirect_to root_path # halts request cycle
    end
  end
end