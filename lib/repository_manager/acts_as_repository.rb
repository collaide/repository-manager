module RepositoryManager
  module ActsAsRepository
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_repository(options = {})
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
    end

  end
end

ActiveRecord::Base.send :include, RepositoryManager::ActsAsRepository