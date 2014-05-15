class CreateCas < ActiveRecord::Migration
  def change
    create_table :cas do |t|
      t.integer :user_id 
      t.string :ca_password, :limit=>16, :null=>false
      t.string :hostname, :null=>false
      t.string :country, :null=>false
      t.string :dn_st, :null=>false
      t.string :dn_l, :null=>false
      t.string :dn_o, :null=>false
      t.string :dn_ou
      t.timestamps
    end
   #一意制約
      add_index(:cas,[:hostname,:user_id],:unique => true)   
  end
end
