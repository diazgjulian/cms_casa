# use SSHKit directly instead of Capistrano
require 'sshkit'
require 'sshkit/dsl'

include SSHKit::DSL

project_name = 'crm_casa'

git_repo = 'git@github.com:diazgjulian/cms_casa.git'

# shared_dirs = ["csv", "log", "sockets", "pids", "db_production", "public/system"]

# server_ip = 'lucius.tacticatic.com'
server_ip = '192.168.1.89'
server_username = 'julian'
# server_username = 'root'
server_port = '80'

base_path = '/var/www/'

project_path = "#{base_path}#{project_name}"

server = SSHKit::Host.new hostname: server_ip, port: server_port, user: server_username
root_server = SSHKit::Host.new hostname: server_ip, port: server_port, user: 'root'

namespace :julian do
  desc 'Crea la estructura del proyecto'
  task :config do
    on server do

      # Creamos la estructura básica de carpetas
      execute 'mkdir', '-p', project_path
      execute 'mkdir', '-p', "#{project_path}/releases"
      execute 'mkdir', '-p', "#{project_path}/shared"
      execute 'mkdir', '-p', "#{project_path}/pg"
    end
  end

  desc 'Crea la estructura del proyecto'
  task :first_deploy do
    on server do
      # Creamos la nueva release
      release_name = Time.now.strftime('%Y%m%d%H%M%S')
      release_path = "#{project_path}/releases/#{release_name}"
      execute 'mkdir', '-p', release_path

      # Descargamos el código del Git
      execute :git, :clone, git_repo, release_path

      within release_path do
        execute 'echo', "'#{release_name}'", '>', 'realase.pid'
      end

      execute 'rm', '-rf', "#{release_path}/pg"
      execute 'ln', '-s', "#{project_path}/pg", "#{release_path}/pg"
      execute 'rm', '-rf', "#{release_path}/public/uploads"
      execute 'ln', '-s', "#{project_path}/shared/public/uploads", "#{release_path}/public/uploads"
      execute 'rm', '-rf', "#{release_path}/public/system"
      execute 'ln', '-s', "#{project_path}/shared/public/system", "#{release_path}/public/system"
      execute 'rm', '-rf', "#{release_path}/log"
      execute 'ln', '-s', "#{project_path}/shared/log", "#{release_path}/log"


      # Ajusto la configuración del Docker a pre
      execute 'rm', '-rf', "#{release_path}/config/database.yml"
      execute 'mv', "#{release_path}/config/database.production.yml", "#{release_path}/config/database.yml"
      execute 'touch', "#{release_path}/Gemfile.lock"

      execute 'sed', '-i', "'s/release_path/#{release_path.gsub('/','\/')}/g'", "#{release_path}/docker-compose.production.yml"
      execute 'sed', '-i', "'s/app_name/#{project_name}/g'", "#{release_path}/docker-compose.production.yml"


      # Hago el build de las máquinas de pre
      within release_path do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'build'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
        # execute 'docker-compose', '-f', 'docker-compose.production.yml', 'run', 'app', 'rake', 'db:migrate'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'run', 'app', 'rake', 'assets:precompile'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
      end

      current_path = "#{project_path}/current"
      execute 'ln', '-s', "$(ls -td -- #{project_path}/releases/*/ | head -n 1)", current_path
    end
  end

  desc 'Creo la nueva release'
  task :new_release do
    on server do
      # Creamos la nueva release
      release_name = Time.now.strftime('%Y%m%d%H%M%S')
      release_path = "#{project_path}/releases/#{release_name}"
      execute 'mkdir', '-p', release_path

      # Descargamos el código del Git
      execute :git, :clone, git_repo, release_path

      # Ajustamos los enlaces simbólicos al shared
      # for dir in shared_dirs
      #   execute 'mkdir', '-p', "#{project_path}/shared/#{dir}"
      #   execute 'rm', '-rf', "#{release_path}/#{dir}"
      #   execute 'ln', '-s', "#{project_path}/shared/#{dir}", "#{release_path}/#{dir}"
      # end

      within release_path do
        execute 'echo', "'#{release_name}'", '>', 'realase.pid'
      end

      execute 'rm', '-rf', "#{release_path}/pg"
      execute 'ln', '-s', "#{project_path}/pg", "#{release_path}/pg"
      execute 'rm', '-rf', "#{release_path}/public/uploads"
      execute 'ln', '-s', "#{project_path}/shared/public/uploads", "#{release_path}/public/uploads"
      execute 'rm', '-rf', "#{release_path}/public/system"
      execute 'ln', '-s', "#{project_path}/shared/public/system", "#{release_path}/public/system"
      execute 'rm', '-rf', "#{release_path}/log"
      execute 'ln', '-s', "#{project_path}/shared/log", "#{release_path}/log"


      # Ajusto la configuración del Docker a pre
      execute 'rm', '-rf', "#{release_path}/config/database.yml"
      execute 'mv', "#{release_path}/config/database.production.yml", "#{release_path}/config/database.yml"
      execute 'touch', "#{release_path}/Gemfile.lock"

      # # Enlazamos el entorno de pre
      # pre_path = "#{project_path}/pre"
      # execute 'rm', '-rf', pre_path
      # execute 'ln', '-s', release_path, pre_path


      execute 'sed', '-i', "'s/release_path/#{release_path.gsub('/','\/')}/g'", "#{release_path}/docker-compose.production.yml"
      execute 'sed', '-i', "'s/app_name/#{project_name}/g'", "#{release_path}/docker-compose.production.yml"


      # Hago el build de las máquinas de pre
      within release_path do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'build'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
        # execute 'docker-compose', '-f', 'docker-compose.pre.yml', 'up', '-d'

        # execute 'docker-compose', '-f', 'docker-compose.pre.yml', 'run', 'app_pre', 'rake', 'db:create'
        # execute 'docker-compose', '-f', 'docker-compose.pre.yml', 'run', 'app_pre', 'rake', 'db:migrate'
        # execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
        # execute 'docker-compose', '-f', 'docker-compose.production.yml', 'run', 'app', 'rake', 'db:migrate'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'run', 'app', 'rake', 'assets:precompile'

        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
      end
    end
  end

  # desc 'Inicio el servidor de pre-producción'
  # task :pre_start do
  #   on server do
  #     pre_path = "#{project_path}/pre"
  #     within pre_path do
  #       execute 'docker-compose', '-f', 'docker-compose.pre.yml', 'up', '-d'
  #     end
  #   end
  # end

  # desc 'Detengo el servidor de pre-producción'
  # task :pre_stop do
  #   on server do
  #     pre_path = "#{project_path}/pre"
  #     within pre_path do
  #       execute 'docker-compose', '-f', 'docker-compose.pre.yml', 'down'
  #     end
  #   end
  # end

  desc 'Paso el proyecto de pre-producción a real'
  task :publish_realease do
    on server do

      current_path = "#{project_path}/current"

      within "#{current_path}/" do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
      end

      # Hago el build de las máquinas de producción
      execute 'rm', '-rf', current_path

      execute 'ln', '-s', "$(ls -td -- #{project_path}/releases/2*/ | head -n 1)", current_path

      within "#{current_path}/" do
        # execute 'docker-compose', '-f', 'docker-compose.production.yml', 'build'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'up', '-d'
      end

    end
  end

  desc 'Para la aplicacion'
  task :release_app_start do
    on root_server do
      within "#{project_path}/releases" do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'up', '-d'
      end
    end
  end

  desc 'Para la aplicacion'
  task :release_app_stop do
    on root_server do
      within "#{project_path}/releases" do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
      end
    end
  end

  desc 'Para la aplicacion'
  task :current_app_start do
    on root_server do
      within "#{project_path}/releases/$(cat #{current_path}/realase.pid)" do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'up', '-d'
      end
    end
  end

  desc 'Para la aplicacion'
  task :current_app_stop do
    on root_server do
      within "#{project_path}/releases/$(cat #{current_path}/realase.pid)" do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
      end
    end
  end

  desc 'Borro las releases viejas'
  task :cleanup do
    on server do
      within "#{project_path}/releases" do
        # execute 'pwd'
        # sudo 'pwd'
        sudo 'rm', '-rf', '$(ls -v | head -n -3 | tr \'\n\' \' \')'
        # execute :sudo, 'ls',  '-1tr', '|', 'head', '-n', '-3', '|', 'xargs', '-d', "'\\n'", 'sudo', 'rm', '-rf', '--'
        # execute :sudo, 'ls',  '-1tr', '|', 'head', '-n', '-3', '|', 'xargs', '-d', "'\\n'", 'sudo', 'rm', '-rf', '--'
      end
    end
  end

  desc 'Reinicio el servidor real'
  task :restart do
    on server do
      # Hago el build de las máquinas de producción
      current_path = "#{project_path}/current/"

      within current_path do
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'down'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'build'
        execute 'docker-compose', '-f', 'docker-compose.production.yml', 'up', '-d'
      end

    end
  end

  desc 'Reinicio el servicio Docker'
  task :docker_restart do
    on root_server do
      execute 'docker', 'network', 'rm', "$(docker network ls | grep 'bridge' | awk '/ / { print $1 }')"
      execute 'sudo',  'service', 'docker', 'restart'
    end
  end

  desc 'Reinicio el servidor NGINX'
  task :nginx_restart do
    on root_server do
      execute 'sudo',  'service', 'nginx', 'restart'
    end
  end

  desc 'Inicio el servidor NGINX'
  task :nginx_start do
    on root_server do
      execute 'sudo',  'service', 'nginx', 'start'
    end
  end

  desc 'Detengo el servidor NGINX'
  task :nginx_stop do
    on root_server do
      execute 'sudo',  'service', 'nginx', 'stop'
    end
  end


  desc 'Borro las releases viejas'
  task :config_nginx do
    on server do
      within "#{project_path}/current" do
        # execute 'pwd'
        # sudo 'pwd'
        sudo 'cp', 'nginx_conf.txt', "/etc/nginx/sites-available/#{project_name}"
        sudo 'ln', '-s', "/etc/nginx/sites-available/#{project_name}", "/etc/nginx/sites-enabled/#{project_name}"
        sudo 'service', 'nginx', 'restart'
        # execute :sudo, 'ls',  '-1tr', '|', 'head', '-n', '-3', '|', 'xargs', '-d', "'\\n'", 'sudo', 'rm', '-rf', '--'
        # execute :sudo, 'ls',  '-1tr', '|', 'head', '-n', '-3', '|', 'xargs', '-d', "'\\n'", 'sudo', 'rm', '-rf', '--'
      end
    end
  end

  desc 'Hace el despliegue completo'
  task deploy: %w{julian:new_release julian:publish_realease} # pull images manually to reduce down time
end

# # set the identifier used to used to tag our Docker images
# deploy_tag = ENV['DEPLOY_TAG']

# # set the name of the environment we are deploying to (e.g. staging, production, etc.)
# deploy_env = ENV['DEPLOY_ENV'] || :production

# # set the location on the server of where we want files copied to and commands executed from
# deploy_path = ENV['DEPLOY_PATH'] || "/home/#{ENV['SERVER_USER']}"

# # connect to server
# server = SSHKit::Host.new hostname: ENV['SERVER_HOST'], port: ENV['SERVER_PORT'], user: ENV['SERVER_USER']

# namespace :deploy do
#   desc 'copy to server files needed to run and manage Docker containers'
#   task :configs do
#     on server do
#       upload! File.expand_path('../../config/containers/docker-compose.production.yml', __dir__), deploy_path
#     end
#   end
# end

# namespace :docker do
#   desc 'logs into Docker Hub for pushing and pulling'
#   task :login do
#     on server do
#       within deploy_path do
#         execute 'docker', 'login', '-e' , ENV['DOCKER_EMAIL'], '-u', ENV['DOCKER_USER'], '-p', "'#{ENV['DOCKER_PASS']}'"
#       end
#     end
#   end

#   desc 'stops all Docker containers via Docker Compose'
#   task stop: 'deploy:configs' do
#     on server do
#       within deploy_path do
#         with rails_env: deploy_env, deploy_tag: deploy_tag do
#           execute 'docker-compose', '-f', 'docker-compose.production.yml', 'stop'
#         end
#       end
#     end
#   end

#   desc 'starts all Docker containers via Docker Compose'
#   task start: 'deploy:configs' do
#     on server do
#       within deploy_path do
#         with rails_env: deploy_env, deploy_tag: deploy_tag do
#           execute 'docker-compose', '-f', 'docker-compose.production.yml', 'up', '-d'

#           # write the deploy tag to file so we can easily identify the running build
#           execute 'echo', deploy_tag , '>', 'deploy.tag'
#         end
#       end
#     end
#   end

#   desc 'pulls images from Docker Hub'
#   task pull: 'docker:login' do
#     on server do
#       within deploy_path do
#         %w{dockerexample_web dockerexample_app}.each do |image_name|
#           execute 'docker', 'pull', "#{ENV['DOCKER_USER']}/#{image_name}:#{deploy_tag}"
#         end

#         execute 'docker', 'pull', 'postgres:9.4.5'
#       end
#     end
#   end

#   desc 'runs database migrations in application container via Docker Compose'
#   task migrate: 'deploy:configs' do
#     on server do
#       within deploy_path do
#         with rails_env: deploy_env, deploy_tag: deploy_tag do
#           execute 'docker-compose', '-f', 'docker-compose.production.yml', 'run', 'app', 'bundle', 'exec', 'rake', 'db:migrate'
#         end
#       end
#     end
#   end

#   desc 'pulls images, stops old containers, updates the database, and starts new containers'
#   task deploy: %w{docker:pull docker:stop docker:migrate docker:start} # pull images manually to reduce down time
# end
