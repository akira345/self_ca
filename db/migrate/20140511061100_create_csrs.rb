class CreateCsrs <  ActiveRecord::Migration[4.2]
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
    #一意制約
      add_index(:csrs,[:hostname,:user_id],:unique => true)
  end
end
