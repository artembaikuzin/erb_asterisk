require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ErbAsteriskTest < MiniTest::Test
  def setup
    @cd = Dir.pwd
  end

  def teardown
    Dir.chdir(@cd)
  end

  def test_render
    Dir.chdir('test/support/')

    cases = ['asterisk/queues.conf', 'asterisk/queues.conf.includes',
             'asterisk/entities/office/pjsip_endpoints.conf',
             'asterisk/pjsip_endpoints.conf.includes',
             'asterisk/extensions.conf', 'asterisk/extensions.conf.includes',
             'asterisk/entities/office/extensions.conf',
             'asterisk/entities/office/extensions_priority.conf']

    cases.each do |c|
      File.delete(c) if File.exist?(c)
    end

    result = system('../../exe/erb_asterisk')

    assert_equal(result, true)
    cases.each do |c|
      assert_equal(File.read(c), File.read("#{c}.expected"))
    end
  end

  def test_template_render
    Dir.chdir('test/support/asterisk_with_templates/')

    case_file = 'queues.conf'
    File.delete(case_file) if File.exist?(case_file)

    result = system('../../../exe/erb_asterisk')

    assert_equal(result, true)
    assert_equal(File.read(case_file), File.read("#{case_file}.expected"))
  end

  def test_no_asterisk_configuration
    Dir.chdir('test/support/no_config/')
    assert_equal(system('../../../exe/erb_asterisk'), false)
  end
end
