class AddYouTubeUrlToEvent < ActiveRecord::Migration
  def change
    add_column :events, :youtube_url, :string
  end
end
