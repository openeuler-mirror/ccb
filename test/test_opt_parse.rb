# frozen_string_literal: true

require "test_helper"
require "opt_parse"

class TestOptParse < Minitest::Test
  def build_parser
    parser = OptionParser.new
    state = { help: false, message: nil }
    parser.on("-h", "--help", "help switch") { state[:help] = true }
    parser.on("-m", "--message=MSG", "a message") { |v| state[:message] = v }
    [parser, state]
  end

  def test_known_switch_is_consumed_and_unknown_short_option_kept
    parser, state = build_parser
    args = ["-h", "-s", "s1"]

    parser.parser_with_unknow_args!(args)

    assert state[:help], "the known -h switch should have been parsed"
    assert_equal ["-s", "s1"], args
  end

  def test_unknown_long_option_with_separate_value_is_kept
    parser, = build_parser
    args = ["--foo", "bar"]

    parser.parser_with_unknow_args!(args)

    assert_equal ["--foo", "bar"], args
  end

  def test_unknown_long_option_with_attached_value_is_kept
    parser, = build_parser
    args = ["--foo=bar"]

    parser.parser_with_unknow_args!(args)

    assert_equal ["--foo=bar"], args
  end

  def test_known_option_taking_argument_consumes_its_value
    parser, state = build_parser
    args = ["-m", "hello", "-x"]

    parser.parser_with_unknow_args!(args)

    assert_equal "hello", state[:message]
    assert_equal ["-x"], args
  end

  def test_only_known_options_leaves_empty_remainder
    parser, state = build_parser
    args = ["-h"]

    parser.parser_with_unknow_args!(args)

    assert state[:help]
    assert_empty args
  end

  def test_only_positional_arguments_are_all_kept
    parser, = build_parser
    args = ["one", "two"]

    parser.parser_with_unknow_args!(args)

    assert_equal ["one", "two"], args
  end

  def test_unknown_options_and_positionals_keep_encounter_order
    parser, state = build_parser
    args = ["-h", "pos1", "--zzz", "pos2"]

    parser.parser_with_unknow_args!(args)

    assert state[:help]
    assert_equal ["pos1", "--zzz", "pos2"], args
  end

  def test_does_not_mutate_a_fresh_args_array_without_known_options
    parser, = build_parser
    args = ["-a", "-b"]

    parser.parser_with_unknow_args!(args)

    assert_equal ["-a", "-b"], args
  end
end
