class CasController < ApplicationController
#CAの再作成や削除はしない。
  def index
    logger.debug("BEGIN")
    logger.debug(current_user.id)
          #すでに認証局作成済みか？
    if Ca.exists?(user_id: current_user.id)
              #証明書作成画面へリダイレクト
      redirect_to :controller=>'csrs',:action => 'index'
    else
          #認証局作成
      @ca = Ca.new
      render 'create'
    end
  end

  def download
    filepath = Rails.root.to_s+"/data/#{current_user.id}/CA/cacert.pem"
    if File.exists? filepath
      logger.debug("ファイルあり")
      stat = File::stat(filepath)
      logger.debug(stat.size)
      send_file(filepath, :filename => 'cacertt.pem',:length => stat.size,:status=>201,:type=>'application/x-pem-file')
      #send_file(filepath)
    else
      logger.debug("ファイルなし")
    end
          #戻る
    #redirect_to( :back )
  end

  def create
    logger.debug ("Begin")
    pass_size = 16
    @ca = Ca.new(ca_params)
    @ca.ca_password=Utils::generate_password(pass_size)
    @ca.user_id = current_user.id
    if @ca.save
      logger.debug("OK")
      logger.debug(@ca.country)
                #各ファイルの出力先
      ca_param = Hash.new
      ca_param = Utils::generate_ca_param(@ca)
      ca = Makecert.new(ca_param)
      logger.debug("ca")
  
      redirect_to :controller => "csrs", :action=>"index"
    else
      logger.debug("NG")
      render 'create'
    end 
    logger.debug("END")
  end
  
  private
        #入力フォームのリクエストパラメタ検証
    def ca_params
      params.require(:ca).permit(:hostname, :country,:dn_st,:dn_l,:dn_o,:dn_ou)
    end
end
