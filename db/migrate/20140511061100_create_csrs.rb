class CreateCsrs < ActiveRecord::Migration
  def change
    create_table :csrs do |t|
      t.integer :user_id
      t.string :hostname, :null=>false
      t.string :country, :null=>false
      t.string :dn_st, :null=>false
      t.string :dn_l, :null=>false
      t.string :dn_o, :null=>false
      t.string :dn_ou
      t.timestamps
    end
  end
end
