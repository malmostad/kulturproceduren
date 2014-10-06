class CreateSchoolTypes < ActiveRecord::Migration
  def up
    create_table :school_types do |t|
      t.string :name
      t.boolean :active, default: true
      t.timestamps
    end

    add_column :districts, :school_type_id, :integer

    legacy = SchoolType.create!(name: "Gamla stadsdelar")
    District.update_all(school_type_id: legacy.id)
  end

  def down
    remove_column :districts, :school_type_id
    drop_table :school_types
  end
end
