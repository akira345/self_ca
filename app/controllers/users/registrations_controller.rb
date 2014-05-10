class Users::RegistrationsController < Devise::RegistrationsController
 
  def new
    super
  end
 
  def create
    super
  end

   def destroy
    dirpath = Rails.root.to_s+"/data/#{current_user.id}"
    if File.exists? dirpath
      FileUtils.rm_r(Dir.glob("#{dirpath}/"), :secure => true)
    end
    super
  end
end
