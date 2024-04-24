
namespace :db do

    desc "Dumps the database to backups"
    task :dump => :environment do

        backup_dir = backup_directory true
        cmd = nil
        with_config do |app, host, port, db, user, passw|
            cmd = "PGPASSWORD=#{passw}  pg_dump -F c -v -U #{user} -h #{host} -p #{port} -d #{db} -f #{backup_dir}/db.dump"
        end
        if File.exists?("#{backup_dir}/db_bak2.dump")
            FileUtils.rm("#{backup_dir}/db_bak2.dump")
        end
        if File.exists?("#{backup_dir}/db_bak.dump")
            FileUtils.mv("#{backup_dir}/db_bak.dump", "#{backup_dir}/db_bak2.dump")
        end
        if File.exists?("#{backup_dir}/db.dump")
            FileUtils.mv("#{backup_dir}/db.dump", "#{backup_dir}/db_bak.dump")
        end
        puts cmd
        exec cmd
    end

    desc "Restores the database from a backup using PATTERN"
    task :restore => :environment do |task,args|

        cmd = nil
        with_config do |app, host, port, db, user, passwd|
            backup_dir = backup_directory
            cmd = "PGPASSWORD=#{passwd}  pg_restore --verbose --host #{host} --port #{port} --username #{user} --clean --no-owner --no-acl --dbname #{db} #{backup_dir}/db.dump"
        end
        unless cmd.nil?
          Rake::Task["db:drop"].invoke
          Rake::Task["db:create"].invoke
          puts cmd
          exec cmd
        end

    end

    private

    def backup_directory create=false
        backup_dir = "#{Rails.root}/db/backups"
        if create and not Dir.exists?(backup_dir)
          puts "Creating #{backup_dir} .."
          Dir.mkdir(backup_dir)
        end
        backup_dir
    end

    def with_config
        yield Rails.application.class.module_parent_name.underscore,
          ActiveRecord::Base.connection_db_config.host,
          ActiveRecord::Base.connection_db_config.configuration_hash[:port],
          ActiveRecord::Base.connection_db_config.database,
          ActiveRecord::Base.connection_db_config.configuration_hash[:username],
          ActiveRecord::Base.connection_db_config.configuration_hash[:password]
    end

end
