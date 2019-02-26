#!/usr/bin/env bash

dockerize(){
  cd "$1"
  
  ## append ignore item to [.gitignore]
  if [ -f .gitignore ] && [ $(grep ".devops-wb-dist/" .gitignore|wc -l) -eq 0 ] ; then
    echo "" >> .gitignore
    echo "## DevOps Facilities - Workbench" >> .gitignore
    echo ".devops-wb-dist/" >> .gitignore
  fi

  ## dir:[.devops-wb]
  mkdir -p .devops-wb

  ## try to recognize project type
  mod_type="$(recognize-project-type)"
  echo "=============================="
  echo "[$1]"
  echo "=============================="
  echo "Project Type = [${mod_type}]"
  if [ -z "${mod_type}" ]; then
    echo "Cannot recognize module project type, please dockerize this project manually;"
#    echo "[Tips] Following are the files that workbench build.sh depends on:"
#    echo "  [<path-to-mod>/.devops-wb/mod.sh] - generate [.mods], to let workbench know about the actual running componenets"
#    echo "  [<path-to-mod>/.devops-wb/prebuild.sh] - scanning port/env-var in application config files, then generate [Dockerfile]/[config/<mod>.cfg]/[deployment/<mod>.yaml]"
#    echo "  [<path-to-mod>/.devops-wb/build.sh] - build application, then build docker image"
#    echo "  [<path-to-mod>/.devops-wb/.settings] - custom starter env-var, suffix with [_PORT]/[_PATH] should add port/volume mapping to deployment/<mod>.yaml"
    leave 1
  fi
  
  if [ $(grep 'maven' <<< "${mod_type}"|wc -l) -gt 0 ] && [ ! -x mvnw ]; then
    type mvn 2>/dev/null || ( echo "maven is not installed yet";  leave 1 )
    echo "Setting up Maven Wrapper"
    mvn -N io.takari:maven:wrapper
    if [ $(grep '!.mvn/wrapper/maven-wrapper.jar' .gitignore |wc -l) -eq 0 ]; then
      echo "" >> .gitignore
      echo "## Maven Wrapper" >> .gitignore
      echo "!.mvn/wrapper/maven-wrapper.jar" >> .gitignore
    fi
  fi
    
  if [ $(grep 'springboot' <<< "${mod_type}"|wc -l) -gt 0 ]; then
    echo "Setting up workbench scripts"
    cp "$DIR"/mod-func/dummy-mod.sh .devops-wb/mod.sh
    cp "$DIR"/mod-func/dummy-springboot-prebuild.sh .devops-wb/prebuild.sh
    cp "$DIR"/mod-func/dummy-springboot-build.sh .devops-wb/build.sh
    cp "$DIR"/mod-func/dummy-springboot-dockerfile.template .devops-wb/dockerfile.template
    cp "$DIR"/mod-func/dummy-springboot-deployment.template .devops-wb/deployment.template
    echo "$(git log --pretty="%H" -n 1)" > .devops-wb/.wb-version
    chmod a+x .devops-wb/*.sh
  fi

  leave 0
}

leave(){
  cd "$DIR"
  #exit $1
  return $1
}

## Try to recognize 
recognize-project-type(){
  rt=""
  if [ -f pom.xml ]; then
    rt="${rt} maven"
    if [ $(grep -B 10 "<executable>true" pom.xml|grep "org.springframework.boot"|wc -l) -gt 0 ]; then
      rt="${rt} springboot"
    fi
  fi
 
  ## trim string
  rt=($rt)
  rt=${rt[@]}
  echo ${rt}
}
