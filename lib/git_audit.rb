require 'json'
require 'open3'
require 'timeout'
require 'pathname'

module GitAudit
  LIMIT = 4 * 1024 * 1024
  TRAILER = /\ACo-authored-by:\s+([^<>]+?)\s+<([^<>\s]+@[^<>\s]+)>\z/i
  GENERATED = %w[pr-log.txt autobadge.py autobranch_pair.py].freeze

  def self.git(path, *arguments)
    output = error = nil
    Open3.popen3('git', '-C', File.expand_path(path), *arguments, pgroup: true) do |stdin, stdout, stderr, process|
      stdin.close
      readers = [stdout, stderr].map do |stream|
        Thread.new do
          data = +''
          loop do
            chunk = stream.read(16_384)
            break unless chunk
            data << chunk
            if data.bytesize > LIMIT
              Process.kill('KILL', -process.pid) rescue nil
              raise ArgumentError, 'git output exceeds capacity'
            end
          end
          data.force_encoding(Encoding::UTF_8)
        end
      end
      unless process.join(30)
        Process.kill('KILL', -process.pid) rescue nil
        process.join
        raise Timeout::Error, 'git command exceeded 30 seconds'
      end
      output, error = readers.map(&:value)
      raise ArgumentError, error.strip[0, 400] unless process.value.success?
    end
    output
  end

  def self.commit(path, sha)
    fields = git(path, 'show', '-s', '--format=%H%x00%an%x00%ae%x00%aI%x00%B', sha).split("\0", 5)
    raise ArgumentError, 'invalid commit metadata' unless fields.length == 5
    id, name, email, timestamp, message = fields
    blocks = message.strip.split("\n\n")
    final = blocks.length > 1 ? blocks.last.lines.map(&:chomp) : []
    authors = []
    malformed = []
    message.lines.map(&:chomp).each do |line|
      next unless line.downcase.start_with?('co-authored-by:')
      match = TRAILER.match(line.strip)
      if !match || !final.include?(line)
        malformed << line
      else
        identity = { name: match[1].strip, email: match[2].downcase }
        authors << identity unless authors.include?(identity)
      end
    end
    changes = git(path, 'diff-tree', '--root', '--no-commit-id', '--numstat', '-r', sha).lines.map do |line|
      added, removed, filename = line.chomp.split("\t", 3)
      raise ArgumentError, 'invalid change record' unless filename
      { path: filename, added: added == '-' ? nil : Integer(added), removed: removed == '-' ? nil : Integer(removed) }
    end
    {
      sha: id, author: { name: name, email: email.downcase }, timestamp: timestamp,
      subject: message.lines.first&.chomp || '', coAuthors: authors, invalidTrailers: malformed,
      changes: changes, substantiveFiles: changes.count { |item| !GENERATED.include?(File.basename(item[:path])) }
    }
  end

  def self.audit(path, limit: 200, ref: 'HEAD')
    raise ArgumentError, 'limit must be 1..10000' unless limit.is_a?(Integer) && (1..10_000).cover?(limit)
    raise ArgumentError, 'invalid reference' unless ref.is_a?(String) && !ref.empty? && !ref.start_with?('-') && ref.bytesize <= 256
    git(path, 'rev-parse', '--verify', "#{ref}^{commit}")
    ids = git(path, 'rev-list', "--max-count=#{limit}", ref, '--').lines.map(&:strip)
    commits = ids.map { |id| commit(path, id) }
    counts = Hash.new(0)
    commits.each { |item| item[:coAuthors].each { |author| counts[author[:email]] += 1 } }
    {
      repository: File.expand_path(path), ref: ref, inspected: commits.length,
      collaborativeCommits: commits.count { |item| !item[:coAuthors].empty? && item[:substantiveFiles].positive? },
      malformedTrailers: commits.sum { |item| item[:invalidTrailers].length },
      coAuthorCounts: counts.sort.to_h, commits: commits
    }
  end
end
