module JobStateCases
  def test_build_mapper_image_twice
    @job.build_mapper_image File.read('testdata/input.hello')
    begin
      @job.build_mapper_image File.read('testdata/input.hello')
      flunk 'No exception thrown'
    rescue RuntimeError => e
      assert_instance_of RuntimeError, e
      assert_equal 'Mapper image already exists', e.message
    end
  end

  def test_run_mapper_without_image
    begin
      @job.run_mapper 1
      flunk 'No exception thrown'
    rescue RuntimeError => e
      assert_instance_of RuntimeError, e
      assert_equal 'Mapper image does not exist', e.message
    end
  end

  def test_run_invalid_mapper
    begin
      @job.run_mapper 4
      flunk 'No exception thrown'
    rescue ArgumentError => e
      assert_instance_of ArgumentError, e
      assert_equal 'Invalid mapper number 4', e.message
    end
  end

  def test_invalid_mapper_runner
    begin
      @job.mapper_runner 4
      flunk 'No exception thrown'
    rescue ArgumentError => e
      assert_instance_of ArgumentError, e
      assert_equal 'Invalid mapper number 4', e.message
    end
  end

  def test_build_reducer_image_without_mapper_results
    begin
      @job.build_reducer_image
      flunk 'No exception thrown'
    rescue RuntimeError => e
      assert_instance_of RuntimeError, e
      assert_equal 'Not all mappers ran', e.message
    end
  end

  def test_build_reducer_image_twice
    @job.build_mapper_image File.read('testdata/input.hello')
    1.upto(3) { |i| @job.run_mapper i }
    @job.build_reducer_image
    begin
      @job.build_reducer_image
      flunk 'No exception thrown'
    rescue RuntimeError => e
      assert_instance_of RuntimeError, e
      assert_equal 'Reducer image already exists', e.message
    end
  end

  def test_run_reducer_without_image
    begin
      @job.run_reducer
      flunk 'No exception thrown'
    rescue RuntimeError => e
      assert_instance_of RuntimeError, e
      assert_equal 'Reducer image does not exist', e.message
    end
  end
end
