class AddCanMoveToRmSharings < ActiveRecord::Migration
  def self.up
    add_column :rm_sharings, :can_move, :boolean, default: false
  end

  def self.down
    remove_column :rm_sharings, :can_move, :boolean, default: false
  end
end