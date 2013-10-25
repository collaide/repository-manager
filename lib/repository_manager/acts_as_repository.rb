module RepositoryManager
  module ActsAsRepository
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_repository(options = {})

        has_many :shares, :through => :shares_items, dependent: :destroy
        has_many :shares_items, as: :item, dependent: :destroy
        has_many :shares_owners, as: :owner, :class_name => 'Share'

        has_many :repositories, as: :owner#, dependent: :destroy

        #cattr_accessor :yaffle_text_field
        #self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s
        # your code will go here

        include RepositoryManager::ActsAsRepository::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def test(string)
        "test: #{string}"
        #write_attribute(self.class.yaffle_text_field, string.to_squawk)
      end

      #Share the repository to the items, with the repo_permissions
      #share_permission contains :
        #can_add and can_remove specifie if the users can add/remove people to the share
      def share(repository, items, repo_permissions, global_share_permissions)
        #TODO add repo_permissions
        share = Share.new(can_read:true, can_create:true)
        share.owner = self

        repository.shares << share

        items.each do |i|
          #Todo add share permissions
          shareItem = SharesItem.new
          shareItem.item = i
          #add the shares items in the share
          share.shares_items << shareItem
        end

        repository.save
      end
    end

  end
end

ActiveRecord::Base.send :include, RepositoryManager::ActsAsRepository