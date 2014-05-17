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
      @ca=Ca.new
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
           #パスワード生成
    tmp =[]
    tmp = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    password = Array.new(pass_size){tmp[rand(tmp.size)]}.join

    logger.debug("Begin")
    @ca = Ca.new(ca_params)
    @ca.ca_password=password
    @ca.user_id = current_user.id
    if @ca.save
      logger.debug("OK")
      logger.debug(@ca.country)
                #各ファイルの出力先
      ca_param=Hash.new
      #CAファイルの出力先
      ca_param[:CA_dir] = Rails.root.to_s+"/data/#{current_user.id}/CA/"
      ca_param[:keypair_file] = File.join ca_param[:CA_dir], "private/cakeypair.pem"
      ca_param[:cert_file] = File.join ca_param[:CA_dir], "cacert.pem"
      ca_param[:serial_file] = File.join ca_param[:CA_dir], "serial"
      ca_param[:new_certs_dir] = File.join ca_param[:CA_dir], "newcerts"
      #CAの有効期限
      ca_param[:ca_cert_days] = 5 * 365 # five years
      #CAの鍵長
      ca_param[:ca_rsa_key_length] = 2048
                #発行する証明書の有効期限と鍵の長さ
      ca_param[:cert_days] = 365 # one year
      ca_param[:cert_key_length_min] = 1024
      ca_param[:cert_key_length_max] = 2048
      #CAのDN
      ca_param[:name] = [
        ['C', "#{@ca.country}", OpenSSL::ASN1::PRINTABLESTRING],
        ['ST',"#{@ca.dn_st}",OpenSSL::ASN1::UTF8STRING],
        ['L',"#{@ca.dn_l}",OpenSSL::ASN1::UTF8STRING],
        ['O', "#{@ca.dn_o}", OpenSSL::ASN1::UTF8STRING],
        ['OU', "#{@ca.dn_ou}", OpenSSL::ASN1::UTF8STRING],
                ]
      #CAのホスト名情報
      ca_param[:hostname] = @ca.hostname
      #CAのパスワード
      ca_param[:password] = @ca.ca_password
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
