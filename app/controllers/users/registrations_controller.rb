class Users::RegistrationsController < Devise::RegistrationsController
 
  def new
    super
  end
 
  def create
    super
  end

   def destroy
        #退会時は作成した証明書をディレクトリごと削除
    dirpath = Rails.root.to_s+"/data/#{current_user.id}"
    if File.exists? dirpath
      FileUtils.rm_r(Dir.glob("#{dirpath}/"), :secure => true)
    end
    super
  end
end
