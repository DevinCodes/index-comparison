# Index comparison
This is a basic scripts that outputs any differences within records between 2 indices. It doesn't look at the record count, only at the records in the `cpl_index` and compares those records to similar records in the `stream_index`.

**Requirements**:
- `ruby >= 2.5`

**Get started:**
- Run `bundle install` to install all dependencies.
- Update the `compare.rb` file on line 3 and 4 to point to the correct indices you want to compare, using the right credentials. Make sure the API key you use has the `browse` permissions.
- Run `bundle exec ruby ./compare.rb` to compare the 2 indices.

**Notes:**
- You can ignore certain attributes by adding them to the `ATTRIBUTES_TO_IGNORE` array on line 6 of the script. You need to pass the attribute name as a symbol, for example `:sku`.