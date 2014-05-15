class CsrsController < ApplicationController
# onlyで指定されたメソッドでset_csrメソッドが動く
  before_action :set_csr, only: [:show, :edit, :update, :destroy, :download]

  # GET /csrs
  def index
          #一覧表示
     @csrs = Csr.where(:user_id =>current_user.id).order("id")
  end
 
  # GET /csrs/new
  def new
      #新規作成
    @csr = Csr.new
  end
  
  # GET /csrs/1
  def show
      #詳細表示
  end

  # GET /csrs/1/edit
  def edit
      #編集
    #TODO まだ未実装。IDの条件指定を調査すること。
    #  @csr = Csr.where(:user_id=>current_user.id)
  end

  def download
    #TODO まだ未実装。IDの条件指定を調査すること。
    @param=params[:kind]
    if @param == "public"
      filename = "cert_" + @csr.hostname + ".pem"
    else
      filename = @csr.hostname + "_keypair.pem"
    end
    filepath = Rails.root.to_s+"/data/#{current_user.id}/CERT/#{@csr.hostname}/#{filename}"
    if File.exists? filepath
      logger.debug("ファイルあり")
      stat = File::stat(filepath)
      logger.debug(stat.size)
      #binding.pry
      send_file(filepath, :filename => filename,:length => stat.size,:status=>201,:type=>'application/x-pem-file')
    else
      logger.debug("ファイルなし")
    end
          #戻る
    #redirect_to( :back )
  end

  # POST /csrs
  def create
    @csr = Csr.new(csr_params)
    @csr.user_id = current_user.id
    respond_to do |format|
      if @csr.save
        @ca=Ca.find_by user_id:current_user.id
        logger.debug("-----------------------")
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
        logger.debug("作成開始")
        cert = Makecert.new(ca_param)

        cert_param = Hash.new
        cert_param[:type]="server"
        cert_param[:hostname]=@csr.hostname
        cert_param[:password]=nil
        cert_param[:cert_dir] = Rails.root.to_s+"/data/#{current_user.id}/CERT/"
        cert_param[:cert_rsa_key_length]="2048"
        cert_param[:name] = [
          ['C', "#{@csr.country}", OpenSSL::ASN1::PRINTABLESTRING],
          ['ST',"#{@csr.dn_st}",OpenSSL::ASN1::UTF8STRING],
          ['L',"#{@csr.dn_l}",OpenSSL::ASN1::UTF8STRING],
          ['O', "#{@csr.dn_o}", OpenSSL::ASN1::UTF8STRING],
          ['OU', "#{@csr.dn_ou}", OpenSSL::ASN1::UTF8STRING],
                      ]
        logger.debug("証明書生成")
        cert.create_cert(cert_param)

        format.html { redirect_to @csr, notice: '証明書を作成しました。.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /csrs/1
  def update
    #TODO 未実装
    logger.debug "EDIT!!"
    respond_to do |format|
      if @csr.update(csr_params)
              #一旦削除して造り替える
              #関数化したい。
        dirpath = Rails.root.to_s+"/data/#{current_user.id}/CERT/" + @csr.hostname
        if File.exists? dirpath
          FileUtils.rm_r(Dir.glob("#{dirpath}/"), :secure => true)
        end
        ## TODO レコード条件を追加
        @ca=Ca.find_by user_id:current_user.id
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
        cert = Makecert.new(ca_param)

        cert_param = Hash.new
        cert_param[:type]="server"
        cert_param[:hostname]=@csr.hostname
        cert_param[:password]=nil
        cert_param[:cert_dir] = Rails.root.to_s+"/data/#{current_user.id}/CERT/"
        cert_param[:cert_rsa_key_length]="2048"
        cert_param[:name] = [
          ['C', "#{@csr.country}", OpenSSL::ASN1::PRINTABLESTRING],
          ['ST',"#{@csr.dn_st}",OpenSSL::ASN1::UTF8STRING],
          ['L',"#{@csr.dn_l}",OpenSSL::ASN1::UTF8STRING],
          ['O', "#{@csr.dn_o}", OpenSSL::ASN1::UTF8STRING],
          ['OU', "#{@csr.dn_ou}", OpenSSL::ASN1::UTF8STRING],
                      ]
        cert.create_cert(cert_param)
        format.html { redirect_to @csr, notice: '証明書は再作成されました。' }
      else
        format.html { render :edit }
      end
    end
 end

  # DELETE /csrs/1
  def destroy
  #TODO レコード条件追加。CAとの整合性をどうする？ちゃんと失効処理追加する？
    @csr.destroy
          #今はバスっと証明書をディレクトリごと削除。シリアルがぶつかるので、CA側は消さない。
    dirpath = Rails.root.to_s+"/data/#{current_user.id}/CERT/" + @csr.hostname
    if File.exists? dirpath
      FileUtils.rm_r(Dir.glob("#{dirpath}/"), :secure => true)
    end
    respond_to do |format|
      format.html { redirect_to csrs_url, notice: '証明書は削除されました。' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_csr
      @csr = Csr.where(["id = ? and user_id = ?", params[:id], current_user.id]).first
      #@csr=Csr.where(id: params[:id]).where(user_id: current_user.id)
      #@csr = current_user.csrs.where(id: params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def csr_params
      params.require(:csr).permit(:user_id, :hostname, :cert_password, :cert_rsa_key_length, :country, :dn_st, :dn_l, :dn_o, :dn_ou)
    end
end
