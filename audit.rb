require 'optparse'
require_relative 'lib/git_audit'

options = { limit: 200, ref: 'HEAD' }
parser = OptionParser.new do |arguments|
  arguments.banner = 'ruby audit.rb [REPOSITORY] [--limit N] [--ref REF]'
  arguments.on('--limit N', Integer) { |value| options[:limit] = value }
  arguments.on('--ref REF') { |value| options[:ref] = value }
end
begin
  parser.parse!
  raise ArgumentError, 'only one repository is accepted' if ARGV.length > 1
  puts JSON.pretty_generate(GitAudit.audit(ARGV.first || '.', **options))
rescue ArgumentError, Timeout::Error => error
  warn error.message
  exit 2
end
