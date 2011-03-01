require 'rubygems'
require 'micronaut'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'commissionaire'

def not_in_editor?
  !(ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM'))
end

module CommissionaireExampleHelper
  
  def files_dir
    File.join(File.dirname(__FILE__),'files')
  end
  
end

Micronaut.configure do |c|
  c.color_enabled = not_in_editor?
  c.filter_run :focused => true
  c.formatter = ENV['FORMATTER'] || "documentation"
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => File.join(File.dirname(__FILE__),'../test.db'))  

class CreateModels < ActiveRecord::Migration
  def self.up  
    create_table :customers, :force => true do |t|
      t.string :slug
      t.string :first_name
      t.string :last_name
      t.datetime :date_of_birth
      t.timestamps
    end
  end  
  
  def self.down  
    drop_table :customers
  end  
end

CreateModels.down rescue nil
CreateModels.up

class Customer < ActiveRecord::Base
  
end
