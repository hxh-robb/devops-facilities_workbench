# SME应用服务

**SME应用服务**是一个基于**Docker容器化技术**，通过整合**SME旗下子产品**而成的易于部署维护的**统一服务**。

目前**SME应用服务**包含以下子产品

* 自营彩API

## 1 概览

### 1.1 发布流程

![sme-devops](docs/sme-devops.png)

### 1.2 文件清单

```bash
.sme/
├── setup-prereq.sh # 前置组件安装脚本
├── prereq # 前置组件及其依赖yum离线安装包目录
│   ├── docker-ce.rpm # docker离线安装包
│   ├── docker-compose # docker-compose命令
│   └── [...] # 其他docker依赖组件离线安装包
├── settings # SME发布仓库地址配置
├── cmd.sh # 入口命令行脚本
├── start.sh # 启动SME应用服务(基于cmd.sh)
├── stop.sh # 终止SME应用服务(基于cmd.sh)
├── upgrade.sh # 升级SME应用服务及子产品程序
├── deployment # 部署相关配置
│   ├── apps.yaml # 子产品部署配置
│   └── deps.yaml # 依赖组件部署配置
├── config # 子产品相关配置
│   └── sl-service.properties # 自营彩服务配置
└── docs # 使用说明相关文档
```

## 2 安装说明

步骤概览

* 解压**发布包**
* 安装前置组件
  * `docker`
  * `docker-compose`
* 设定**SME应用服务**与**发布仓库**的通讯环境
  * 设置发布仓库地址
  * 开放防火墙/路由表访问限制

注意：安装步骤的命令均在64位CentOS 7.3.1611系统执行验证通过，如在其他系统执行下述命令不成功，请寻求SME团队协助。

运维人员可使用如下命令了解当前服务器的系统版本：

```bash
$ cat /etc/*release
```

### 2.1 解压发布包

SME团队将向合作方提供**SME应用服务发布包**，合作方的运维人员在生产服务器上解压该**发布包**。

注意：请按实际情况修改`path/to/sme`（`path/to/sme`为**SME应用服务**的存放路径）。

```bash
$ mkdir -p path/to/sme # 请按实际情况修改path/to/sme
$ tar -xvz -f sme.20180904164034.tar.gz -C path/to/sme # 请按实际情况修改path/to/sme
```

### 2.2 安装前置组件

**SME应用服务**基于`docker`及`docker-compose`，因此需要合作方的运维人员在生产服务器上安装上述前置组件。

**SME应用服务**内已包含前置组件的yum离线安装包，运维人员在生产服务器上执行`setup-prereq.sh`脚本即可。

* 安装前置组件

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ ./setup-prereq.sh # setup-prereq.sh脚本内有指令需要sudo权限，安装过程中请按提示输入当前sudoer的密码
```

* 验证`docker`及`docker-compose`安装成功

```bash
$ docker --version
Docker version 18.06.1-ce, build e68fc7a
$ docker-compose --version
docker-compose version 1.22.0, build f46880fe
```

* 重新登录ssh

`docker`命令需要**root**或**docker组成员**权限，如果当前ssh用户不是超级管理员，需要重新登录ssh使当前用户的**docker组成员**权限生效。

### 2.3 配置发布仓库

**SME应用服务**需要从**发布仓库**提取新版本的SME子产品程序，因此在启动**服务**之前，需要合作方的运维人员设定好**SME应用服务**与**发布仓库**的通讯环境。

#### 2.3.1 设置发布仓库地址

* 增加`docker`配置

```bash
# 备份已存在的docker配置。
$ sudo test -f "/etc/docker/daemon.json" && sudo mv "/etc/docker/daemon.json" "/etc/docker/daemon.json.bak.$(date +%Y%m%d%H%M%S)" 
----------
# 生成docker配置，请按实际情况修改发布仓库的IP地址及端口。
$ echo '{"insecure-registries":["47.75.86.156:65000"]}' | sudo tee "/etc/docker/daemon.json" 
----------
# 重启docker服务使新增的配置生效。
$ sudo systemctl restart docker.service
```

* 设置**SME应用服务**引用的**发布仓库**地址

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ vi settings
----------
SME_REGISTRY=47.75.86.156:65000/ # 请按实际情况修改发布仓库的IP地址及端口。注意：需要保留结尾的斜杠符号（/）。
SME_LOG_DIR=/home/output/logs
```

#### 2.3.2 开放路由访问限制

如果**生产服务器**与**中转服务器**之间的网络通讯受限于`iptables`路由表或外置防火墙，请合作方的运维人员向有关部门申请权限，并开通两者之间的网络通讯。

```bash
$ sudo iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
ACCEPT     all  --  192.168.31.0/24      anywhere            
ACCEPT     tcp  --  47.75.86.156         anywhere             tcp spt:65000
DROP       all  --  anywhere             anywhere            

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
ACCEPT     all  --  anywhere             192.168.31.0/24     
ACCEPT     tcp  --  anywhere             47.75.86.156         tcp dpt:65000
DROP       all  --  anywhere             anywhere            
```

（以上`iptables`配置仅供阐述**SME应用服务**期望的生产环境内网路由表访问限制情况。）

## 3 使用说明

本章将说明**SME应用服务**的基本使用操作步骤。

### 3.1 子模块配置

启动**SME应用服务**之前，运维人员需要根据实际环境设定**SME应用服务**内部各子模块与其他**外部组件**之间的对接配置(如**数据库**/**消息队列**等)。

* 自营彩API

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ vi config/sl-service.properties
RABBITMQ_BROKERURL=${RabbitMQ_IP} # 消息队列IP地址，请按实际环境替换${RabbitMQ_IP}。例：127.0.0.1
RABBITMQ_PORT=${RabbitMQ_Port} # 消息队列端口，请按实际环境替换${RabbitMQ_Port}。例：5672
RABBITMQ_USERNAME=${RabbitMQ_User} # 消息队列接入账号，请按实际环境替换${RabbitMQ_User}。例：guest
RABBITMQ_PASSWORD=${RabbitMQ_Password} # 消息队列接入密码，请按实际环境替换${RabbitMQ_Password}。例：guest
RABBITMQ_HOST=/

# 数据库(读库)IP地址及端口，请按实际环境替换${Database_IP}:${Database_Port}。例：127.0.0.1:3306
DRUID_READER_URL=jdbc:mysql://${Database_IP}:${Database_Port}/thirdpart_issue?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=PRC&useSSL=false
DRUID_READER_USERNAME=${Database_User} # 数据库(读库)接入账号，请按实际环境替换${Database_User}。例：root
DRUID_READER_PASSWORD=${Database_Password} # 数据库(读库)接入密码，请按实际环境替换${Database_Password}。例：123456

# 数据库(写库)IP地址及端口，请按实际环境替换${Database_IP}:${Database_Port}。例：127.0.0.1:3306
DRUID_WRITER_URL=jdbc:mysql://192.168.31.121:3306/thirdpart_issue?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=PRC&useSSL=false
DRUID_WRITER_USERNAME=${Database_User} # 数据库(写库)接入账号，请按实际环境替换${Database_User}。例：root
DRUID_WRITER_PASSWORD=${Database_Password} # 数据库(写库)接入密码，请按实际环境替换${Database_Password}。例：123456

LOTTERY_SOURCE_SECRETKEY=${SecretKey} # 验证密钥，请按实际环境替换${SecretKey}。
LOTTERY_SOURCE_OPENCODE_EXCHANGE=LXYD.WebGame.Util.MiscHelpers.RabbitMQ.RabbitMQMessage:LXYD.WebGame.Core
LOTTERY_SOURCE_OPENCODE_ROUTINGKEY=SelfGamblingOpenResult.Router

LOTTERY_SOURCE_HARDWARERANDOMENABLE=1 # 是否启用硬件随机数，0=禁用/1=启用
LOTTERY_SOURCE_HARDWARERANDOMURL=http://127.0.0.1:8888
LOTTERY_SOURCE_MODE=xmode
```

### 3.2 启动服务

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ ./start.sh
```

注意：启动服务前会检测日志目录是否存在，如果不存在将会执行`sudo mkdir`命令尝试创建，请按提示输入当前sudoer的密码。

如果需要指定日志目录，可以修改settings中对应的配置项：

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ vi settings
SME_REGISTRY=47.75.86.156:65000/
SME_LOG_DIR=/home/output/logs # 请按实际情况修改SME应用服务的日志存放路径。
```

### 3.3 停止服务

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ ./stop.sh
```

### 3.4 查看服务运行状态

* 查看子模块运行状态

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ ./cmd.sh ps
```

* 查看子模块控制台日志输出

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ ./cmd.sh logs
```

### 3.5 升级服务

```bash
$ cd path/to/sme # 请按实际情况修改path/to/sme
$ ./upgrade.sh
```
