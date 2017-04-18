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
  # before_actionでモデルを読み込み、デフォルトでshowビューが読み込まれるので、特にコードはなし。
  end

  # GET /csrs/1/edit
  def edit
      #編集
  # before_actionでモデルを読み込み、デフォルトでeditビューが読み込まれるので、特にコードはなし。
  end

  def download
    #パラメタで秘密鍵、公開鍵のダウンロードを行う。
    @param = params[:kind]
    if @param == "public"
      filename = "cert_" + @csr.hostname + ".pem"
      download_filename = @csr.hostname + ".crt"
    else
      filename = @csr.hostname + "_keypair.pem"
      download_filename = @csr.hostname + ".key"
    end
    filepath = Rails.root.to_s+"/data/#{current_user.id}/CERT/#{@csr.hostname}/#{filename}"
    if File.exists? filepath
      logger.debug("ファイルあり")
      stat = File::stat(filepath)
      logger.debug(stat.size)
      #binding.pry
      send_file(filepath, :filename => download_filename,:length => stat.size,:status=>201,:type=>'application/x-pem-file')
    else
      logger.debug("ファイルなし")
    end
          #戻る
    #redirect_to( :back )
  end

  # POST /csrs
  def create
    #証明書作成
    @csr = Csr.new(csr_params)
    @csr.user_id = current_user.id
    respond_to do |format|
      if @csr.save
        @ca = Ca.find_by user_id:current_user.id
        logger.debug("-----------------------")
                      #各ファイルの出力先
        ca_param = Hash.new
        cert_param = Hash.new
        ca_param = Utils::generate_ca_param(@ca)
        cert_param = Utils::generate_cert_param(@csr)
        logger.debug("作成開始")
        cert = Makecert.new(ca_param)
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
    #証明書内容更新。旧証明書を削除し、新証明書を作りなおす。
    logger.debug "EDIT!!"
      #変更前のホスト名を取得
    before_csr = Csr.select("hostname").where(["id = ? and user_id = ?", params[:id], current_user.id]).first
    respond_to do |format|
      if @csr.update(csr_params)
              #一旦削除して造り替える
        dirpath = Rails.root.to_s+"/data/#{current_user.id}/CERT/" + before_csr.hostname

        Utils::delete_file(dirpath)

        @ca = Ca.find_by user_id:current_user.id
                     #各ファイルの出力先
        ca_param = Hash.new
        cert_param = Hash.new
       
        ca_param = Utils::generate_ca_param(@ca)
        cert_param = Utils::generate_cert_param(@csr)

        cert = Makecert.new(ca_param)
        cert.create_cert(cert_param)
        format.html { redirect_to @csr, notice: '証明書は再作成されました。' }
      else
        format.html { render :edit }
      end
    end
 end

  # DELETE /csrs/1
  def destroy
      #証明書削除処理。CAとの整合性をどうする？ちゃんと失効処理追加する？
    @csr.destroy
          #今はバスっと証明書をディレクトリごと削除。シリアルがぶつかるので、CA側は消さない。
    dirpath = Rails.root.to_s+"/data/#{current_user.id}/CERT/" + @csr.hostname

    Utils::delete_file(dirpath)

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
