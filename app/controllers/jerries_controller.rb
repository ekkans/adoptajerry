require Rails.root.join('app/interactions/jerries/create_jerry')

class JerriesController < ApplicationController
  before_action :find_jerry, except: [:new, :create, :index, :roulette]
  before_action :maker_authenticate, except: [:index, :show, :roulette]

  def new
    @jerry = Jerry.new
    @jerry.organs.build
    @jerry.skills.build
    @jerry.pictures.build
  end

  def create
    outcome = CreateJerry.run(params: params[:jerry],
                              maker: current_maker,
                              images: params[:jerry][:pictures][:image])
    if outcome.valid?
      redirect_to jerry_path outcome.result
    else
      render :new
    end
  end

  def show
  end

  def index
    @jerries = Jerry.all.reverse
  end

  def edit
    redirect_to @jerry, notice: 'You can not edit this Jerry' unless maker_allowed?
  end

  def update
    if maker_allowed?
      if params[:jerry][:makers]
        new_maker = Maker.find_by :uid => params[:jerry][:makers][:uid]
        if new_maker
          @jerry.makers << new_maker
        else
          flash.now.notice = "Unknown maker '#{params[:jerry][:makers][:uid]}', can not be added to the team"
          return render 'edit_team'
        end
      end
      if @jerry.update jerry_params
        redirect_to @jerry
      else
        render 'edit'
      end
    else
      redirect_to @jerry, notice: 'You can not edit this Jerry'
    end
  end

  def edit_team
    redirect_to @jerry, notice: 'You can not edit this Jerry' unless maker_allowed?
  end

  def destroy
    @jerry.destroy
    redirect_to jerries_path
  end

  def roulette
    rand_id = Jerry.ids.shuffle.first
    @jerry = Jerry.find(rand_id)
    redirect_to @jerry
  end

  private

  def find_jerry
    @jerry = Jerry.find params[:id]
  end

  def maker_authenticate
    redirect_to root_path, notice: 'Please Sign in first --→' unless current_maker
  end

  def maker_allowed?
    @jerry.makers.include? current_maker
  end

  def jerry_params
    params.require(:jerry).permit(
      :name,
      :bio,
      :location,
      :avatar,
      organs_attributes:
        [:id, :role, :quantifier, :unit, :_destroy],
      skills_attributes:
        [:id, :layer, :name, :url, :_destroy],
      pictures_attributes:
        [:id, :jerry_id, :image, :_destroy]
    )
  end

end
