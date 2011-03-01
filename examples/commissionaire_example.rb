require 'example_helper'

describe "Commissionaire" do
  include CommissionaireExampleHelper
  
  before do
    Customer.class_eval do
      collects(:full_customer)
    end
  end
  
  describe "a collecting active record class (Customer)" do
    
    it "should respond to collect_full_customer" do
      Customer.should respond_to(:collect_full_customer)
    end
    
  end
  
  describe "importing customers" do
    
    after do
      Customer.destroy_all
    end
    
    it "should be able to import customers with no errors" do
      Customer.collect_full_customer(:filename => "#{files_dir}/customers_no_ids.csv")
      Customer.count.should eql(2)
    end
    
  end
  
  describe "importing select mappings" do
    
    before do
      Customer.class_eval do
        collects(:select_customer_attributes, 
          :mapping => {
            "fname" => "first_name",
            "lname" => "last_name"
          }
        )
      end
    end
    
    after do
      Customer.destroy_all
    end
    
    it "should only import the fields defined in the mapping" do
      Customer.collect_select_customer_attributes(:filename => "#{files_dir}/customers_fname_lname.csv")
      customer = Customer.find_by_last_name('Jones')
      customer.date_of_birth.should be_nil
      customer.first_name.should eql('Mike')
    end
    
  end
  
  describe "importing with row updating" do
    
    before do
      Customer.create :first_name => "first1", :last_name => "last1"
      @customer = Customer.create :first_name => "first2", :last_name => "last2"
    end
    
    after do
      Customer.destroy_all
    end
    
    it "should update the first and last name based on the id values in the csv file" do
      @customer.first_name.should eql("first2")
      csv = %{id,first_name,last_name\n#{@customer.id},Jimmy,Gordan}
      Customer.collect_full_customer(:csv_string => csv)
      @customer.reload
      @customer.first_name.should eql('Jimmy')
      @customer.last_name.should eql('Gordan')
    end
    
    describe "with select column name" do
      
      before do
        module V1
          class Customer < ActiveRecord::Base
            validates_uniqueness_of :slug
            set_table_name "customers"
            collects(:customers_by_first_name_and_slug, 
                     :key => lambda { |row| 
                         V1::Customer.first(:conditions => {:slug => row["slug"], :first_name => row["original_first_name"]}) 
                     })
            collects(:customers_by_slug, :key => :slug)
          end
        end
        @v1_customer = V1::Customer.create :first_name => "f1", :last_name => "smith", :slug => "f1smith"
      end
      
      after do
        V1::Customer.destroy_all
      end
      
      it "should be able to update a row based on lambda" do
        csv = %{original_first_name,first_name,slug\nf1,"new first",#{@v1_customer.slug}}
        V1::Customer.collect_customers_by_first_name_and_slug(:csv_string => csv)
        @v1_customer.reload
        @v1_customer.first_name.should eql('new first')
      end
      
      it "should be able to update by other column name" do
        csv = %{first_name,slug\n"new first by column",#{@v1_customer.slug}}
        V1::Customer.collect_customers_by_slug(:csv_string => csv)
        @v1_customer.reload
        @v1_customer.first_name.should eql('new first by column')
      end
    end
    
  end

end
