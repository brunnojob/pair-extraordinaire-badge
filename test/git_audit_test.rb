require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/git_audit'

class GitAuditTest < Minitest::Test
  def test_real_commit_and_malformed_trailer
    Dir.mktmpdir do |path|
      GitAudit.git(path, 'init', '-q')
      GitAudit.git(path, 'config', 'user.name', 'Operator')
      GitAudit.git(path, 'config', 'user.email', 'operator@example.test')
      File.write(File.join(path, 'code.c'), 'int main(void) { return 0; }')
      GitAudit.git(path, 'add', 'code.c')
      GitAudit.git(path, 'commit', '-qm', "Add native implementation\n\nCo-authored-by: Peer <peer@example.test>")
      report = GitAudit.audit(path)
      assert_equal 1, report[:collaborativeCommits]
      assert_equal({ 'peer@example.test' => 1 }, report[:coAuthorCounts])
      File.write(File.join(path, 'code.c'), 'int main(void) { return 1; }')
      GitAudit.git(path, 'commit', '-am', "Fix result\nCo-authored-by: Peer <peer@example.test>")
      assert_equal 1, GitAudit.audit(path)[:malformedTrailers]
      assert_raises(ArgumentError) { GitAudit.audit(path, ref: '--all') }
      assert_raises(ArgumentError) { GitAudit.audit(path, limit: 0) }
    end
  end
end
