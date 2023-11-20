# frozen_string_literal: true

module StorageHelpers
  def test_file_store_path
    File.join(TMP_ROOT, 'store')
  end

  def test_file_store
    Reynard::Store::Disk.new(path: test_file_store_path)
  end
end
