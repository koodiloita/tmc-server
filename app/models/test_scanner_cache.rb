class TestScannerCache
  def self.get_or_update(course, exercise_name, files_hash, &block)
    entries = course.test_scanner_cache_entries.where(:exercise_name => exercise_name)
    if entries.size == 1
      entry = entries.first
    elsif entries.size == 0
      entry = TestScannerCacheEntry.new(:course => course, :exercise_name => exercise_name)
    else
      raise 'TestScannerCache has a duplicate entry. Uniqueness has not been enforced.'
    end
    
    if entry.files_hash == files_hash
      decode_value(entry.value)
    else
      entry.value = ActiveSupport::JSON.encode(block.call)
      entry.files_hash = files_hash
      try_save(entry)
      decode_value(entry.value)
    end
  end

  def self.clear!
    TestScannerCacheEntry.delete_all
  end
  
private
  def self.try_save(entry)
    begin
      entry.save!
    rescue ActiveRecord::RecordNotUnique
      result
    rescue
      ActiveRecord::Base.logger.warn("Failed to add entry to TestScannerCache.")
      ActiveRecord::Base.logger.warn($!)
    end
  end
  
  def self.decode_value(value)
    ActiveSupport::JSON.decode(value, :symbolize_keys => true)
  end
end