class HomeController < ApplicationController
  def index
  # useridがなければTOPへリダイレクト
    redirect_to :user_root if current_user
  end
end
