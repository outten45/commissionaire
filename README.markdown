# Commissionaire

Used to add class methods to your ActiveRecord class to collect data into your application.

# Usage

To define a new collector all you need to do is define a collects method.

    class Customer < ActiveRecord::Base
      collects(:full_customers)
    end

You can then collect customers from a csv file.

    Customer.collect_full_customers :filename => "#{RAILS_ROOT}/customer.csv"

or from a csv string

    Customer.collect_full_customers :csv_string => %{id,first_name,last_name\n23,Tom,Smith}

# TODOs

1. add option to not save the collected data
1. separate the import/mapping logic into separate class for testing
1. create option to disseminate data is format provided
1. create a method for converting csv headers to nested structure
1. handle associations with the nested structure
1. look at batch/bulk updates with AR
1. look at disseminating(exporting) the data

# Copyright

Copyright (c) 2009 Richard Outten. See LICENSE for details.
