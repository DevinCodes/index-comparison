require 'algolia'

stream_index = Algolia::Search::Client.create("APP_ID_1", "APP_KEY_1").init_index("INDEX_NAME_1")
cpl_index = Algolia::Search::Client.create("APP_ID_2", "APP_KEY_2").init_index("INDEX_NAME_2")

ATTRIBUTES_TO_IGNORE = [:_tags]

fail_fast = false
batch_size = 100


## Methods
def compare_records(records, index)
  errors = []
  index.browse_objects({ query: '', distinct: false, analytics: false, filters: generate_filters(records) }) do |object|
    record = records.detect { |o| o[:objectID] == object[:objectID] }
    records.delete(record)

    errors.concat(compare(record, object))
  end

  if records.size.positive?
    records.each do |r|
      errors.push("Record not found on main index: #{r[:objectID]}")
    end
  end

  errors
end

def compare(obj_1, obj_2)
  errs = []
  obj_1.keys.each do |key|
    next if ATTRIBUTES_TO_IGNORE.include?(key)

    if obj_1[key] != obj_2[key]
      errs.push("Different values for #{key} attribute in object #{obj_1[:objectID]}:\n   CPL:     #{obj_1[key]} \n   Stream:  #{obj_2[key]}")
    end
  end

  missing_keys = obj_2.keys - obj_1.keys
  missing_keys.each do |key|
    next if ATTRIBUTES_TO_IGNORE.include?(key)
    errs.push("Missing value for #{key} attribute in object #{obj_1[:objectID]}:\n   Stream:  #{obj_2[key]}")
  end

  errs
end

def generate_filters(records)
  records.map { |r| "objectID:#{r[:objectID]}" }.join(' OR ')
end

def output_errors(errors, count)
  if errors.size.positive?
    errors.each { |err| puts err }
    puts "Found #{errors.size} errors"
  else
    puts "No errors found comparing #{count} records"
  end
end

## Browse & compare
count = 1
objects = []
errors = []
cpl_index.browse_objects({ query: '', distinct: false, analytics: false }) do |obj|
  if count % batch_size == 0
    errors.concat(compare_records(objects.dup, stream_index))
    if fail_fast && errors.size.positive?
      output_errors(errors, count)
      exit
    end
    objects = []
  end

  objects.push(obj)
  count += 1
end

errors.concat(compare_records(objects.dup, stream_index)) if objects.size.positive?

obj_count_cpl = cpl_index.search('', { responseFields: ['nbHits'] })[:nbHits]
obj_count_stream = stream_index.search('', { responseFields: ['nbHits'] })[:nbHits]

if obj_count_cpl != obj_count_stream
  errors.push("Number of records not equal: #{obj_count_cpl} for CPL and #{obj_count_stream} for Stream.")
end

output_errors(errors, count)