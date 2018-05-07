#require 'spec_helper'
#
#describe 'Versioning' do
#
#  before do
#    @user1 = FactoryBot.create(:user)
#    @user1_file = FactoryBot.build(:rm_repo_file)
#    @user1_file.owner = @user1
#    @user1_file.save
#    @user1_folder = FactoryBot.build(:rm_repo_folder)
#    @user1_folder.owner = @user1
#    @user1_folder.save
#    @user2 = FactoryBot.create(:user)
#
#  end
#
#  it 'can versioning a file' do
#    #p @user1_file.sender
#    @user1.create_file!(File.open("#{Rails.root}/../fixture/textfile2.txt"), overwrite: true, sender: @user2, filename: 'textfile.txt')
#    #p @user1_file.reload.sender
#
#    #p @user1_file.reload.versions
#    #p @user1.root_repo_items
#    @user1_folder.name = 'Nouveau nom'
#    @user1_folder.save!
#    #p @user1_folder.reload.versions
#  end
#
#end