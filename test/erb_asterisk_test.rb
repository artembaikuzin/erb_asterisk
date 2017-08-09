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

  def test_asterisk_dir
    cases = ['asterisk/queues.conf',
             'asterisk/queues.conf.includes',
             'asterisk/entities/office/pjsip_endpoints.conf',
             'asterisk/pjsip_endpoints.conf.includes',
             'asterisk/extensions.conf',
             'asterisk/extensions.conf.includes',
             'asterisk/entities/office/extensions.conf',
             'asterisk/entities/office/extensions_priority.conf']

    run_test('test/cases/', '../../exe/erb_asterisk', cases)
  end

  def test_inside_asterisk_dir
    cases = ['queues.conf', 'queues_all.conf']

    run_test('test/cases/asterisk_with_templates/',
             '../../../exe/erb_asterisk', cases)
  end

  def test_no_asterisk_configuration
    Dir.chdir('test/cases/no_config/')
    assert_equal(system('../../../exe/erb_asterisk'), false)
  end

  def test_user_defined_templates
    cases = ['iax_register.conf', 'iax_friends.conf']
    run_test('test/cases/user_defined_templates/',
             '../../../exe/erb_asterisk --templates ../../user_defined_templates',
             cases)
  end

  def test_soft_write
    root = 'test/cases/soft_write/'
    file = 'asterisk.conf'
    conf_path = File.expand_path("#{root}#{file}")

    before = File.stat(conf_path)
    run_test(root, '../../../exe/erb_asterisk',
             [file], true)

    after = File.stat(conf_path)
    assert_equal(before, after)
  end

  def test_no_erb_files
    Dir.chdir('test/cases/no_erb_files/')
    assert_equal(system('../../../exe/erb_asterisk'), true)
  end

  private

  def run_test(dir, command, cases, no_delete = false)
    Dir.chdir(dir)

    unless no_delete
      cases.each do |c|
        File.delete(c) if File.exist?(c)
      end
    end

    result = system(command)

    assert_equal(result, true)
    cases.each do |c|
      assert_equal(File.read(c), File.read("#{c}.expected"))
    end
  end
end
