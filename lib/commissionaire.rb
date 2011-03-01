$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_record'

if RUBY_VERSION > "1.9"
 require "csv"  
 unless defined? FCSV
   class Object # :nodoc:
     FCSV = CSV 
     alias_method :FCSV, :CSV
   end  
 end
else
 require "fastercsv"
end

##
# Commissionaire is a +ActiveRecord::Base+ mixin that adds the
# ability to collect/import data into your database.  It provides
# several helper methods to easy the import process.
module Commissionaire

  # Module for collecting data to be imported into system.
  module Collect
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods

      # Adds a collector to the current +ActiveRecord+ model.
      #
      #    class Customer < ActiveRecord::Base
      #      collect :my_parts
      #    end
      #
      #    Customer.collect_my_parts :filename => "/path/to/customer.csv"
      #
      # @param [Symbol] name identifies the name of the collector that is
      #   setup.
      # @param [Hash] opts options that setup the collector
      # @option opts [Hash] mapping includes the header name (key) to 
      #   method name (value) used to assign the value to in the
      #   current object.
      # 
      def collects(name, opts={})

        self.class.class_eval do 
          define_method("collect_#{name}") do |*args|
            # filename = args.shift
            local_opts = {}
            local_opts = args.shift unless args.empty?
            results = Results.new

            fastcsv_opts = { :headers => :first_row }.merge(local_opts[:fastcsv_opts] || {})
            if local_opts[:filename]
              csv_method = :foreach
            else
              csv_method = :parse
            end
            FCSV.send(csv_method, (local_opts[:filename] || local_opts[:csv_string]), fastcsv_opts) do |row|
              obj = collector_build_or_find(row, opts)
              unless obj.save
                results.add(:success, row, obj.errors.full_messages)
              end
            end
            
            results
          end
        end
        
        include Commissionaire::Collect::InstanceMethods
        extend Commissionaire::Collect::SingletonMethods
      end
      
    end
    
    module SingletonMethods
      
      def collector_headers(mapping={})
        if mapping.blank?
          mapping = self.column_names.inject({}) { |hash, v| hash[v.to_s] = v.to_s; hash }
        end
        mapping
      end
      
      def collector_find_for_key(key, row)
        if key.respond_to?(:call)
          key.call(row)
        else
          self.first(:conditions => { key.to_sym => row[key.to_s] })
        end
      end
      
      def collector_build_or_find(row, opts={})
        key = opts[:key] || "id"
        obj = collector_find_for_key(key, row)
        obj = self.new unless obj
        collector_set_attributes(obj, row, opts)
      end
      
      def collector_set_attributes(obj, row, opts={})
        mapping = collector_headers(opts[:mapping])
        mapping.each do |csv_name, method_name|
          if row[csv_name]
            obj.send(:"#{method_name}=", row[csv_name])
          end
        end
        obj
      end
  
    end
    
    module InstanceMethods
      
    end
    
    class Collector
      attr_reader :opts, :local_opts
      attr_accessor :results
      
      def initialize(opts, local_opts)
        @opts = opts
        @local_opts = local_opts
        @results = Results.new
      end
      
      def parse
        fastcsv_opts = { :headers => :first_row }.merge(local_opts[:fastcsv_opts] || {})
        csv_method = (local_opts[:filename] ? :foreach : :parse)
        
        FCSV.send(csv_method, (local_opts[:filename] || local_opts[:csv_string]), fastcsv_opts) do |row|
          obj = self.collector_build_or_find(row, opts)
          unless obj.save
            results.add(:success, row, obj.errors.full_messages)
          end
        end
        
      end
      
      def collector_headers(mapping={})
        if mapping.blank?
          mapping = self.column_names.inject({}) { |hash, v| hash[v.to_s] = v.to_s; hash }
        end
        mapping
      end
      
      def collector_find_for_key(key, row)
        if key.respond_to?(:call)
          key.call(row)
        else
          self.first(:conditions => { key.to_sym => row[key.to_s] })
        end
      end
      
      def collector_build_or_find(row, opts={})
        key = opts[:key] || "id"
        obj = collector_find_for_key(key, row)
        obj = self.new unless obj
        collector_set_attributes(obj, row, opts)
      end
      
      def collector_set_attributes(obj, row, opts={})
        mapping = collector_headers(opts[:mapping])
        mapping.each do |csv_name, method_name|
          if row[csv_name]
            obj.send(:"#{method_name}=", row[csv_name])
          end
        end
        obj
      end
      
      
    end
    
    
    
    # Simple class to collect messages from the collection
    # process. Mainly used to collect messages in standard
    # format.
    class Results
      
      attr_accessor :messages
      def initialize
        @messages = []
      end

      ## 
      # Add message to be collected in standard format.
      #
      # @param [Symbol] type is success or error
      # @param [Hash] input_row CSV row represented by a hash normally
      # @param [Array] error_messages array of error messages
      #
      #
      def add(type, input_row, error_messages)
        @messages << {:type => type, :input_row => input_row, :errors => error_messages}
      end
      
    end
  end
end
  
ActiveRecord::Base.class_eval do
  include Commissionaire::Collect
end
