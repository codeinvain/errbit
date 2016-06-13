namespace :errbit do
  desc "Updates cached attributes on Problem"
  task problem_recache: :environment do
    ProblemRecacher.run
  end

  desc "Delete resolved errors from the database. (Useful for limited heroku databases)"
  task clear_resolved: :environment do
    require 'resolved_problem_clearer'
    puts "=== Cleared #{ResolvedProblemClearer.new.execute} resolved errors from the database."
  end

  desc "Regenerate fingerprints"
  task notice_refingerprint: :environment do
    NoticeRefingerprinter.run
    ProblemRecacher.run
  end

  desc 'Resolves problems that didnt occur for 2 weeks'
  task :cleanup => :environment do
    offset = 2.weeks.ago
    Problem.where(:updated_at.lt => offset).map(&:resolve!)
    Notice.where(:updated_at.lt => offset).destroy_all
  end

  desc "Remove notices in batch"
  task :notices_delete, [:problem_id] => [:environment] do
    BATCH_SIZE = 1000
    if args[:problem_id]
      item_count = Problem.find(args[:problem_id]).notices.count
      removed_count = 0
      puts "Notices to remove: #{item_count}"
      while item_count > 0
        Problem.find(args[:problem_id]).notices.limit(BATCH_SIZE).each do |notice|
          notice.remove
          removed_count += 1
        end
        item_count -= BATCH_SIZE
        puts "Removed #{removed_count} notices"
      end
    end
  end
end
