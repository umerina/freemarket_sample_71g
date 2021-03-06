class ItemsController < ApplicationController
before_action :set_item, only: [:show, :edit, :update, :destroy, :done, :purchase]
before_action :move_to_index1, only: [:done]
before_action :move_to_index2, only: [:update, :destroy]
before_action :move_to_index3, only: [:edit]

  def set_item
    @item = Item.find(params[:id])
  end

  def move_to_index1
    redirect_to action: :index  if @item.buyer_id.present? || current_user.id == @item.seller_id
  end

  def move_to_index2
    redirect_to action: :index unless user_signed_in? && current_user.id == @item.seller_id
  end

  def move_to_index3
    redirect_to root_path if current_user.id != @item.user_id
  end



  
  def index
    @items = Item.all.includes(:images).order("created_at DESC")
  end

  def show
  end

  def new
    @item = Item.new
    5.times { @item.images.build }
    @category_parent_array = ["---"]
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent.name
    end
  end

  def get_category_children
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  
  def create
    @item = Item.new(item_params)
    category_id_params
    if @item.save
      redirect_to root_path
    else
      redirect_to new_item_path
    end
  end

  def edit
    grandchild_category = @item.category
    child_category = grandchild_category.parent
    @category_parent_array = []
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent.name
    end

    @category_children_array = []
    Category.where(ancestry: child_category.ancestry).each do |children|
      @category_children_array << children
    end

    @category_grandchildren_array = []
    Category.where(ancestry: grandchild_category.ancestry).each do |grandchildren|
      @category_grandchildren_array << grandchildren
    end
  end

  def get_category_children
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  def update
    category_id_params
    if @item.update(item_params)
      redirect_to root_path
    else 
      redirect_to edit_item_path
    end
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else 
      redirect_to :destroy
    end
  end

  def done
  end

  def purchase
    card = Card.where(user_id: current_user.id).first
    if card.blank?
      redirect_to controller: "cards", action: "new"
    else
      Payjp.api_key = Rails.application.credentials.payjp[:sk_test]
      
      charge = Payjp::Charge.create(
        amount: @item.price,
        customer: Payjp::Customer.retrieve(card.customer_id),
        currency: 'jpy'
      )
      @item_purchaser= Item.find(params[:id])
      @item_purchaser.update( buyer_id: current_user.id)
      redirect_to root_path
    end
  end

  def item_params
    params.require(:item).permit(
      :name, 
      :explaination, 
      :price, 
      :brand, 
      :prefecture_id, 
      :condition_id, 
      :shipment_id, 
      :responsibility_id, 
      images_attributes: [:src, :_destroy, :id]
    ).merge(
      user_id: current_user.id ,seller_id: current_user.id
    )
  end

  def category_id_params
    category = params.permit(:category_id)
    @item[:category_id] = category[:category_id]
  end

end