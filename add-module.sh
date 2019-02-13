#!/usr/bin/env bash

################################################################################
## Root working directory
################################################################################

SCRIPT=$(readlink -f "$0")
DIR=$(dirname "$SCRIPT")
cd "$DIR"

################################################################################
## Significant directories
################################################################################

MODS_DIR="$DIR"/modules
mkdir -p "$MODS_DIR"

################################################################################
## Command options & parameters
################################################################################

## Options

DRY_RUN=false
RE_DOCKERIZE=false
for arg in "$@"; do
  test "$arg" == "--dry-run" && DRY_RUN=true
  test "$arg" == "--re-dockerize" && RE_DOCKERIZE=true
done

## Paramters

for i in $(seq 1 $#); do
  if [ "${!i}" == "--mod" ]; then
    i=$((i+1))
    MOD_REPO="${!i}"
    
    i=$((i+1))
    MOD_BRANCH="${!i}"
    
    i=$((i+1))
    MOD_PROFILE="${!i}"
  fi
done

################################################################################
## Functions
################################################################################

setup_mvnw(){
  if [ -f "pom.xml" ] && [ ! -f "mvnw" ] ; then
    echo "=================================================================="
    echo "Setup maven wrapper on [$(pwd)]"
    echo "------------------------------------------------------------------"
  
    if [ -e ".git" ]; then
      git checkout $MOD_BRANCH
      git pull
    fi
    
    mvn -N io.takari:maven:wrapper
    
    if [ "$DRY_RUN" == "false" ] && [ -e ".git" ]; then
      git add .mvn/ mvnw*
      git commit -m "Setup maven wrapper"
      git push
    fi
  fi
}

generate_springboot_deployment(){
  cat <<EOT >"$1"
version: "3"
services:
  $2:
    image: "\${REGISTRY}$3:latest"
    restart: unless-stopped
    env_file:
      - ../config/all.cfg
      - ../config/$3.cfg
    volumes:
      - "../timezone:/etc/timezone"
    cap_add:
      - SYS_PTRACE
    networks:
      - backend
EOT
}

dockerize_springboot_maven_project(){
  echo "==================== Dockerizing [$MOD:$MOD_BRANCH] ===================="
  cd "$MOD_DIR"
  
  setup_mvnw
  ./mvnw clean
  rm -f .stamp
  
  if [ -e ".git" ]; then
    git checkout $MOD_BRANCH
    git pull
  fi

  if [ 0 == $(grep -c ".docker" ".gitignore") ]; then
    echo ".docker" >> ".gitignore"
  fi
 
  echo "=================================================================="
  echo "Scanning configuration files"
  echo "------------------------------------------------------------------"
  tmp="/tmp/$(cat /proc/sys/kernel/random/uuid)"
  tmp_env="/tmp/$(cat /proc/sys/kernel/random/uuid)"
  tmp_port="/tmp/$(cat /proc/sys/kernel/random/uuid)"
  for mod_internal_config in $(find . -regex '.+\.\(properties\|yml\|yaml\)'); do
    ## Fetch environment variables
    if [ $(grep -cE "\\$\\{(.+):(.+)\\}" "$mod_internal_config") -gt 0 ]; then
      echo "Found enironment variable settings in configuration file[$mod_internal_config]"
      echo "------------------------------------------------------------------"
      cp /dev/null "$tmp"
      grep -nE "\\$\\{(.+):(.+)\\}" "$mod_internal_config" > "$tmp"
      while read -u 3 grep_line; do
        grep_lnum=$(echo $grep_line|awk -F':' '{print $1}')
        grep_content=$(echo $grep_line|awk -F':' '{print substr($0, index($0,$2))}')
        grep_env=$(echo $grep_content|grep -oE "\\$\\{(.+):(.+)\\}")
        grep_env_key=$(echo $grep_env|awk -F'{|}|:' '{print $2}')
        grep_env_val=$(echo $grep_env|awk -F'{|}|:' '{print substr($0, index($0,$3),length($0)-length($2)-4)}')
        
        echo "  Line number = [$grep_lnum]"
        echo "    content = [$grep_content]"
        echo "    env-var key = [$grep_env_key]"
        echo "    env-var value = [$grep_env_val]"
        
        #test $(grep -c "$grep_env_key" "$tmp_env") -eq 0 && echo "$grep_env_key=$grep_env_val" >> "$tmp_env"
        found_in_tmp_env=$(grep -c "$grep_env_key" "$tmp_env")
        if [ -z "$found_in_tmp_env" ] || [ "$found_in_tmp_env" == "0" ]; then
          echo "$grep_env_key=$grep_env_val" >> "$tmp_env"
        fi
      done 3< "$tmp"
      echo "------------------------------------------------------------------"
      test -f "$tmp_env" && echo "Following environment variables will be written to env.sh:" && cat "$tmp_env"
      echo "------------------------------------------------------------------"
    fi

    ## Fetch ports
    expose_ports=""
    if [ $(grep -cE "port.*[0-9]{1,5}.*" "$mod_internal_config") -gt 0 ]; then
      echo "Found port settings in configuration file[$mod_internal_config]"
      echo "------------------------------------------------------------------"
      cp /dev/null "$tmp"
      grep -n -E "port.*[0-9]{1,5}.*" "$mod_internal_config" > "$tmp"
      while read -u 3 grep_line; do
        #port=$(echo "$grep_line"|grep -o -E "[0-9]{1,5}")
        #echo "config entry is$config_entry"
        grep_lnum=$(echo $grep_line|awk -F':' '{print $1}')
        grep_content=$(echo $grep_line|awk -F':' '{print substr($0, index($0,$2))}')
        grep_port=$(echo $grep_content|grep -o -E "[0-9]{1,5}")

        echo "  Line number = [$grep_lnum]"
        echo "    content = [$grep_content]"
        echo "    port = [$grep_port]"

        read -p "Would you like to expose port $grep_port(y/n)? " need_expose
        test "$need_expose" == "y" && expose_ports="$grep_port $expose_ports"
      done 3< "$tmp"
      echo "------------------------------------------------------------------"
      test -n "$expose_ports" && echo "Following ports will be exposed in Dockerfile:" && echo "$expose_ports"
      test -n "$expose_ports" && echo "$expose_ports" > "$tmp_port" 
      echo "------------------------------------------------------------------"
    fi
  done

  echo "=================================================================="
  echo "Generating env.sh"
  echo "------------------------------------------------------------------"
  if [ "$RE_DOCKERIZE" == "true" ] || [ ! -f env.sh ]; then
    echo "#!/usr/bin/env bash" > env.sh
    echo "cat <<EOT" >> env.sh
    test -f "$tmp_env" && cat "$tmp_env" >> env.sh
    echo "EOT" >> env.sh
    chmod +x env.sh
  fi
  
  echo "=================================================================="
  echo "Generating Dockerfile"
  echo "------------------------------------------------------------------"
  if [ "$RE_DOCKERIZE" == "true" ] || [ ! -f Dockerfile ]; then
    cat <<EOT >Dockerfile
FROM java:8-jdk
ARG app_file=app.jar
COPY .docker/\$app_file /app/springboot-executable.jar
$(test -n "$(cat "$tmp_port")" && echo "EXPOSE $(cat "$tmp_port")")
WORKDIR /app
CMD /app/springboot-executable.jar
EOT
  fi
  
  echo "=================================================================="
  echo "Generating build.sh"
  echo "------------------------------------------------------------------"
  if [ "$RE_DOCKERIZE" == "true" ] || [ ! -f build.sh ]; then
    cat <<EOT >build.sh
#!/usr/bin/env bash

SCRIPT=\$(readlink -f "\$0")
DIR=\$(dirname "\$SCRIPT")
cd "\$DIR"

APP_PREFIX="$MOD"

DOCKER_DIR="\$DIR/.docker"
mkdir -p "\$DOCKER_DIR"
rm -rf "\$DOCKER_DIR"/*

echo "============= Buidling application packages ============="
./mvnw -Dmaven.test.skip=true -D skipTests clean package
test \$? != 0 && >&2 echo "========== Fail to build application packages! ==========" && exit 1
echo "========== Application packages are now built! =========="

echo "================ Building docker images ================="
if [ ! -f Dockerfile ]; then
  echo "Cannot find Dockerfile"
  echo "============== Fail to build Docker image =============="
  exit 1
fi

app_name=\$(echo \${APP_PREFIX}|awk '{print tolower(\$0)}')
app_version="latest"
app_tag="\$app_name:\$app_version"

echo "Building image[\$app_tag]"
if [ -f env.sh ]; then
  ./env.sh > "\$DOCKER_DIR/\$app_name.cfg"
fi

find . -type f -perm /a+x -name *.jar ! -name maven-wrapper.jar -exec cp {} "\$DOCKER_DIR/\$app_name.jar" \;
app_file="\$app_name.jar"
docker build -f "./Dockerfile" --build-arg app_file="\$app_file" . -t "\$app_tag"
test \$? != 0 && echo "============== Fail to build image[\$app_tag] ==============" && exit 1

echo "============== Docker images are now built =============="
EOT
    chmod +x build.sh
  fi
  
  if [ "$DRY_RUN" == "false" ] && [ -e ".git" ]; then
    git add .
    git commit -m "Dockerize springboot-style maven project"
    git push
  fi
}

################################################################################
## CLI
################################################################################

## git submodule add

echo "=================================================================="
echo "git submodule status:"
echo "------------------------------------------------------------------"
git submodule status

if [ "$RE_DOCKERIZE" == "true" ]; then
  echo "=================================================================="
  echo "Please input the module that needs to re-dockerize:"
  read MOD
  MOD_DIR="$MODS_DIR/$MOD"
  test ! -d "$MOD_DIR" && echo "Invalid module!" && exit 1
  
  MOD_BRANCH=$(git submodule status|grep $MOD|grep -o "(.*)"|awk -F'\(|\)|/' '{print $3}')
  test -z "$MOD_BRANCH" && ./update-modules.sh
  test -z "$MOD_BRANCH" && MOD_BRANCH=$(git submodule status|grep $MOD|grep -o "(.*)"|awk -F'\(|\)|/' '{print $3}')
else
  cd "$MODS_DIR"
  echo "=================================================================="
  test -z "$MOD_REPO" && echo "Please input the git repo address:" || echo "git repo address:[$MOD_REPO]"
  test -z "$MOD_REPO" && read MOD_REPO
  MOD=$(echo "$MOD_REPO"|awk -F':|\/|\.git' '{print $(NF-1)}')
  MOD_DIR="$MODS_DIR/$MOD"

  echo "=================================================================="
  test -z "$MOD_BRANCH" && echo "Please input the git repo branch:" || echo "git repo branch:[$MOD_BRANCH]"
  test -z "$MOD_BRANCH" && read MOD_BRANCH

  echo "------------------------------------------------------------------"
  echo "Add git submodule:$MOD_REPO:$MOD_REPO_BRANCH"
  git submodule add -b "$MOD_BRANCH" "$MOD_REPO"
fi

echo "[$MOD:$MOD_BRANCH]"

cd "$DIR"
./update-modules.sh

## dockerizing

if [ "$RE_DOCKERIZE" == "true" ] || [ ! -f "$MOD_DIR"/build.sh ]; then
  test ! -f "$MOD_DIR"/build.sh && echo "=================================================================="
  test ! -f "$MOD_DIR"/build.sh && echo "\"build.sh\" does not exist, setup the build processes for [$MOD]."
  
  while true; do
    if [ -z "$MOD_PROFILE" ]; then
      echo "Please choose the profile for [$MOD]:"
      echo "  0 = springboot-style maven project"
      echo "  x = I don't want to dockerize this project"
    fi

    test -z "$MOD_PROFILE" && read MOD_PROFILE
    if [ "$MOD_PROFILE" == "x" ]; then
      exit 0
    elif [[ "$MOD_PROFILE" =~ [0] ]]; then
      break
    fi
    echo "Invalid project mode!"
    MOD_PROFILE=""
  done
  echo "------------------------------------------------------------------"
  
  case "$MOD_PROFILE" in
    0)
      echo "The chosen profile is:springboot-style maven project"
      echo "=================================================================="
      ls -l "$MOD_DIR"
      dockerize_springboot_maven_project
      ;;
  esac
  cd "$DIR"
fi

## docker-compose configuration file of this module

mod_lowercase=$(echo "$MOD"|awk '{print tolower($0)}')
mod_deployment="$DIR/starter/deployment/$mod_lowercase.yaml"

if [ ! -f "$mod_deploy_yaml" ]; then
  echo "=================================================================="
  echo "Setup the deployment configuration for [$MOD]."
  
  if [ -e ".git" ]; then
    git pull
  fi
  
  case "$MOD_PROFILE" in
    0)
      generate_springboot_deployment "$mod_deployment" "$MOD" "$mod_lowercase"
      ;;
  esac
  
  if [ "$DRY_RUN" == "false" ] && [ -e ".git" ]; then
    git add .
    git commit -m "Add deployment configuration for [$MOD]"
    git push
  fi
fi
