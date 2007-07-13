unless defined? TEST_ROOT
  ENV["RAILS_ENV"] = "test"
  require 'pathname'
  TEST_ROOT = Pathname.new(File.expand_path(File.dirname(__FILE__))).cleanpath(true).to_s
  require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
  #silence_warnings { RAILS_ENV = "test" }
  require 'test_help' 
  
  ## COPY from rails/lib/test_help.rb --seems not to require right sometimes
    require 'application'
    require 'test/unit'
    require 'active_record/fixtures'
    require 'action_controller/test_process'
    require 'action_controller/integration'
    require 'action_web_service/test_invoke'
    require 'breakpoint'
    Test::Unit::TestCase.fixture_path = RAILS_ROOT + "/test/fixtures/"
    def create_fixtures(*table_names)
      Fixtures.create_fixtures(RAILS_ROOT + "/test/fixtures", table_names)
    end
  ## END COPY
  
  
  require TEST_ROOT + '/helpers/wagn_test_helper'
  require TEST_ROOT + '/helpers/chunk_test_helper'  # FIXME-- should only be in certain tests
  
  class Test::Unit::TestCase
    include AuthenticatedTestHelper
    # Transactional fixtures accelerate your tests by wrapping each test method
    # in a transaction that's rolled back on completion.  This ensures that the
    # test database remains unchanged so your fixtures don't have to be reloaded
    # between every test method.  Fewer database queries means faster tests.
    #
    # Read Mike Clark's excellent walkthrough at
    #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
    #
    # Every Active Record database supports transactions except MyISAM tables
    # in MySQL.  Turn off transactional fixtures in this case; however, if you
    # don't care one way or the other, switching from MyISAM to InnoDB tables
    # is recommended.
    self.use_transactional_fixtures = true
  
    # Instantiated fixtures are slow, but give you @david where otherwise you
    # would need people(:david).  If you don't want to migrate your existing
    # test cases which use the @david style and don't mind the speed hit (each
    # instantiated fixtures translates to a database query per test method),
    # then set this back to true.
    self.use_instantiated_fixtures  = false
  
    def self.common_fixtures
      #fixtures :system, :users, :tags, :tag_revisions, :cards, :revisions, :roles, :cardtypes
      # FIXME: this burns me every time we add a table the tests break and I dunno why...
      fixtures :cards, :cardtypes, :revisions, :roles, :roles_users, :system, :tag_revisions, :tags, :users, :settings
    end
    
    include WagnTestHelper
    include ChunkTestHelper
  
    class << self
      # Class method for test helpers
      def test_helper(*names)
        names.each do |name|
          name = name.to_s
          name = $1 if name =~ /^(.*?)_test_helper$/i
          name = name.singularize
          first_time = true
          begin
            constant = (name.camelize + 'TestHelper').constantize
            self.class_eval { include constant }
          rescue NameError
            filename = File.expand_path(TEST_ROOT + '/helpers/' + name + '_test_helper.rb')
            require filename if first_time
            first_time = false
            retry
          end
        end
      end    
      alias :test_helpers :test_helper
    end
  end
end  

