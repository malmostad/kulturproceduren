class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.references :culture_provider

      t.string  :name
      t.text    :description
      t.date    :show_date

      t.integer :from_age
      t.integer :to_age

      t.integer :ticket_state

      t.string  :url
      t.string  :movie_url
      t.text    :opening_hours
      t.text    :cost
      t.string  :booking_url
      # TODO: lärarhandledning
      # TODO: bilder
      
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
