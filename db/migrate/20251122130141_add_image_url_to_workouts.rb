class AddImageUrlToWorkouts < ActiveRecord::Migration[7.1]
  def change
    add_column :workouts, :image_url, :string
  end
end
