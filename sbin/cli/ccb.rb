#! /usr/bin/env ruby

# frozen_string_literal: true

LKP_SRC = ENV['LKP_SRC'] || File.dirname(File.dirname(File.dirname(File.realpath($PROGRAM_NAME))))

require 'yaml'
require "#{LKP_SRC}/lib/opt_parse"


COMMAND_INFO = {
  'select' => {
    'profile' => 'Query ES. Usage: ccb select <index> k=v|--json JSON|--yaml YAML --sort --field. Details see "ccb select -h".',
    'path' => "#{LKP_SRC}/sbin/cli/select"
  },
  'create' => {
    'profile' => 'Create project/snapshot. Usage: ccb create <index> <os_project> k=v|--json JSON|--yaml YAML. Details see "ccb create -h".',
    'path' => "#{LKP_SRC}/sbin/cli/create"
  },
  'update' => {
    'profile' => 'Update project. Usage: ccb update <index> <os_project> k=v|--json JSON|--yaml YAML. Details see "ccb update -h".',
    'path' => "#{LKP_SRC}/sbin/cli/update"
  },
  'build-single' => {
    'profile' => 'Build single package. Usage: ccb build-single k=v|--json JSON|--yaml YAML. Details see "ccb build-single -h".',
    'path' => "#{LKP_SRC}/sbin/cli/build-single"
  },
  'download' => {
    'profile' => 'Download rpms. Usage: ccb download k=v --sub --debuginfo --source. Details see "ccb download -h".',
    'path' => "#{LKP_SRC}/sbin/cli/download"
  },
  'log' => {
    'profile' => 'Search job result log url. Usage: ccb log <job_id>. Details see "ccb log -h".',
    'path' => "#{LKP_SRC}/sbin/cli/log"
  },
  'build' => {
    'profile' => 'ccb build',
    'path' => "#{LKP_SRC}/sbin/cli/build"
  },
  'cancel' => {
    'profile' => 'ccb cancel',
    'path' => "#{LKP_SRC}/sbin/cli/cancel"
  },
  'ls' => {
    'profile' => 'Display rpm packet information',
    'path' => "#{LKP_SRC}/sbin/cli/ls"
  },
  'query' => {
    'profile' => 'Display rpms query information',
    'path' => "#{LKP_SRC}/sbin/cli/query"
  },
  'local-build' => {
    'profile' => 'Build package locally',
    'path' => "#{LKP_SRC}/sbin/cli/local-build"
  },
  'lb' => {
    'profile' => 'Build package locally',
    'path' => "#{LKP_SRC}/sbin/cli/local-build"
  },
  'local-rebuild' => {
    'profile' => 'Rebuild job locally',
    'path' => "#{LKP_SRC}/sbin/cli/local-rebuild"
  },
  'lr' => {
    'profile' => 'Rebuild job locally',
    'path' => "#{LKP_SRC}/sbin/cli/local-rebuild"
  }
}.freeze

def show_command(opts)
  COMMAND_INFO.each do |command, info|
    opts.separator "    #{command}" + ' ' * (33 - command.size) + info['profile']
  end
end

option_hash = {}
options = OptionParser.new do |opts|
  opts.banner = 'Usage: ccb [global options] sub_command [sub_command options] [args]'
  opts.separator ''
  opts.separator 'Global options:'

  opts.on('-h', '--help', 'show this message') do |h|
    option_hash['help'] = h
  end

  opts.separator ''
  opts.separator 'These are ccb commands:'
  opts.separator ''
  show_command(opts)
end

if ARGV.empty? || ARGV.length == 1 && (ARGV[0] == '-h' || ARGV[0] == '--help')
  puts(options)
  exit
end

options.parser_with_unknow_args!(ARGV)

opt = ARGV.shift
args = ''
ARGV.each do |a|
  args += "\"#{a}\" "
end

cmd = "#{COMMAND_INFO[opt]['path']} #{args.strip}"
cmd += ' -h'                              unless option_hash['help'].nil?
exec cmd
