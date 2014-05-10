class HomeController < ApplicationController
  def index
#useridがなければTOPへリダイレクト
    if current_user  
      redirect_to :user_root  
      return  
    end  
  end
end
