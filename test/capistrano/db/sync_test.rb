require 'test_helper'

class Capistrano::Db::Sync::Test < ActiveSupport::TestCase
  test 'truth' do
    assert_kind_of Module, Capistrano::Db::Sync
  end
end
