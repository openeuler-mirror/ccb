# ccb

#### 介绍
This repository serves as a client-side tool for EulerMaker, allowing users to perform command-line operations on EulerMaker from within their own environment.

#### 软件架构
软件架构说明


#### 安装教程

EulerMaker 将 [lkp-tests](https://gitee.com/openeuler-customization/lkp-tests.git) 作为客户端，通过本地安装 lkp-tests，lkp-tests提交任务依赖ruby，建议安装ruby2.5及以上版本。

安装ccb软件包后需要对本地配置文件配置用户名， 密码、网关等信息：

- #{ENV['HOME']}/.config/cli/defaults/*.yaml，该文件中需手动添加部分参数完成配置，本文为yaml格式请注意编写规范，冒号后需添加空格。
- 客户端环境要求：支持x86、arm、龙芯架构的openeuler系统服务器

```
  GATEWAY_IP: eulermaker.compass-ci.openeuler.openatom.cn  #网关配置必填
  GATEWAY_PORT: 443
  SRV_HTTP_REPOSITORIES_HOST: eulermaker.compass-ci.openeuler.openatom.cn
  SRV_HTTP_REPOSITORIES_PORT: 443
  SRV_HTTP_REPOSITORIES_PROTOCOL: https://  #仅用于ccb download子命令，若无下载需求，可以不配置
  SRV_HTTP_RESULT_HOST: 443  存储job日志的微服务
  SRV_HTTP_RESULT_PORT: 443
  SRV_HTTP_RESULT_PROTOCOL: https://   #仅用于ccb log子命令
  ACCOUNT: xx  #配置openeuler社区账号，社区账号及密码若不配置只能执行游客可执行的命令
  PASSWORD: xx  #配置openeuler社区账号密码
  OAUTH_TOKEN_URL: https://omapi.osinfra.cn/oneid/oidc/token
  OAUTH_REDIRECT_URL: https://eulermaker.compass-ci.openeuler.openatom.cn/oauth
  PUBLIC_KEY_URL: https://omapi.osinfra.cn/oneid/public/key?community=openeuler
```

配置完成后可执行以下命令，查看是否可以正常使用ccb命令。
```
ccb -h/--help
```

#### 使用说明

**命令总览**

```
# CRUD
# Elasticsearch 7.x文档基本操作（CRUD） 
 https://www.cnblogs.com/liugp/p/11848408.html
  Elasticsearch CRUD基本操作
 https://www.cnblogs.com/powercto/p/14438907.html

ccb create <index> <os_project> k=v|--json JSON|--yaml YAML # Details see "ccb create -h".
ccb update <index> <os_project> k=v|--json JSON|--yaml YAML

ccb select <index> <os_project> k=v|--json JSON-file|--yaml YAML-file [-f/--field key1,key2...]
              [-s/--sort key1:asc/desc,key2:asc/desc...]
ccb download os_project=<project_name> packages=<package_name> architecture=x86/aarch64 [--sub] [--source] [--debuginfo]
ccb cancel $build_id
ccb build  
ccb log <job_id> 
ccb build-single os_project=<project_name> packages=<package_name> k=v|--json JSON-file|--yaml YAML-file
ccb ls -p os_project <repo> -a <arch>
ccb query -f <info> -r <rpm_path>  #<info> job_id build_id
ccb local-build key1=val1 key2=val2 ... --rm --debug=bp/bc/bi
ccb lb key1=val1 key2=val2 ... --rm --debug=bp/bc/bi
ccb local-rebuild job_id=cbs.001 --showdocker
ccb lr job_id=cbs.001 --showdocker
```

**命令权限说明**

|命令关键字   | admin   |maintaner|reader|other|guest|备注|
|------------|-----------|-----|------|----|-----|-----|
|create   |√|√|√|√|×|N|
|update   |√|√|×|×|×|同一工程不同角色权限|
|select   |√|√|√|√|√|N|
|download   |√|√|√|√|×|同一工程不同角色权限|
|cancel   |√|√|×|×|×|同一工程不同角色权限|
|log   |√|√|√|√|√|同一工程不同角色权限|
|build-single   |√|√|×|×|×|同一工程不同角色权限|
|build   |√|√|×|×|×|同一工程不同角色权限|
|local-build   |√|√|√|√|×|N|
|local-rbuild   |√|√|√|√|×|N|


**命令详情**

**1. ccb select查询各表信息**

**查询所有的projects全部信息**

```
ccb select projects
```

注意：
rpms和rpm_repos，这两个表由于数据量过大，无法通过`ccb select 表名`命令直接查询该表的全部信息，
查询rpms表必须使用-f指定过滤字段或者使用key=value指定明确的过滤条件。
```
ccb select rpms -f repo_id
ccb select rpms repo_id=openEuler-22.03-LTS:baseos-openEuler:22.03-LTS-x86_64-313
```
查询rpm_repos表必须使用key=value指定明确的过滤条件，如果不知道value的值，可以先查询其他表获取，然后再使用key=value查询rpm_repos表。
```
ccb select builds -f repo_id  # 先查询builds获得repo_id值
ccb select rpm_repos repo_id=openEuler-22.03-LTS:baseos-openEuler:22.03-LTS-x86_64-313 # 使用上个命令获得的repo_id值查询rpm_repos表
```

  **查询符合要求的projects的全部信息**

```
ccb select projects os_project=openEuler:Mainline owner=xxx
```

  **查询符合要求的projects的部分信息**

```
ccb select projects os_project=openEuler:Mainline --field os_project,users
```

  **查询符合要求的projects的部分信息并排序**

```
ccb select projects os_project=openEuler:Mainline --field os_project,users --sort create_time:desc,os_project:asc
```

**列出指定project的所有snapshot(快照)**

```
ccb select snapshots os_project=openEuler:Mainline
```

**注：查看其它表类似**

**2.ccb create project**
**创建project**

```
ccb create projects test-project --json config.json  #config.json文件请用户根据下面模板自行创建
config.json:
{
    "os_project": "test-project",
    "descrption": "this is a private project of zhangshan",
    "my_specs": [
        {
            "spec_name": "gcc",
            "spec_url": "https://gitee.com/src-openeuler/gcc.git",
            "spec_branch": "openEuler-20.03-LTS"
        },
        {
            "spec_name": "python-flask",
            "spec_url": "https://gitee.com/src-openeuler/python-flask.git",
            "spec_branch": "openEuler-20.03-LTS"
        }
    ],
    "build_targets": [
        {
            "os_variant": "openEuler_20.03",
            "architecture": "x86_64"
        },
        {
            "os_variant": "openEuler_20.03",
            "architecture": "aarch64"
        }
    ],
    "bootstrap_rpm_repo": [
        {
            "name": "everything",
            "repo": "https://repo.openeuler.org/openEuler-22.03-LTS-SP1/everything"
        }
    ],
    "flags": {
        "build": true,
        "publish": true
    }
}
```

**3. ccb update projects $os_project**
**project添加package**

```
ccb update projects $os_project --json update.json  # os_project为需要更新得工程名
update.json:
{
    "my_specs+": [
        {
        	"spec_name": "python-flask",
		    "spec_url": "https://gitee.com/src-openeuler/python-flask.git",
		    "spec_branch": "master"
        },
        ...
    ]
}
```
**project增删user**

```
ccb update projects $os_project --json update.json
update.json:
{
    "users-": ["zhangsan"],
    "users+": {
        "lisi": "reader",
	    "wangwu": "maintainer"
    }
}
```
**锁定某个package**

```
ccb update projects test-project package_overrides.$package.lock=true
```

**解锁某个package**

```
ccb update projects test-project package_overrides.$package.lock=false
```

**4. 单包构建**

build_targets可以不传，可以有1或多个，如果不传，采用os_project默认配置的build_targets。
```
ccb build-single os_project=test-project packages=gcc --json build_targets.json
build_targets.json:
{
    "build_targets": [
        {
            "os_variant": "openEuler:20.03",
            "architecture": "x86_64"
        },
        {
            "os_variant": "openEuler:20.03",
            "architecture": "aarch64"
        }
    ]
}
```

**5. 全量/增量构建**

指定build_type=full则为全量构建，指定build_type=incremental则为增量构建；
build_targets参数与单包构建中的build_targets一样，可以不传，可以有1或多个，如果不传，采用os_project默认配置的build_targets；
如果指定snapshot_id，则os_project可不传，表示基于某个历史快照创建全量/增量构建。
```
ccb build os_project=test-project build_type=full --json build_targets.json # 全量构建
ccb build snapshot_id=xxx build_type=incremental --json build_targets.json # 增量构建
build_targets.json: 
{
    "build_targets": [
        {
            "os_variant": "openEuler:20.03",
            "architecture": "x86_64"
        },
        {
            "os_variant": "openEuler:20.03",
            "architecture": "aarch64"
        }
    ]
}
```
**6. 下载软件包**

如果指定snapshot_id，则os_project可不传；
dest表示指定软件包下载后存放的路径，可不传，默认使用当前路径。

基本用法：
```
ccb download os_project=test-project packages=python-flask architecture=aarch64 dest=/tmp/rpm
ccb download snapshot_id=123456 packages=python-flask architecture=aarch64 dest=/tmp/rpm
```
-s的用法：
```
# 使用-s 表示下载该packages的源码包。示例如下所示：
ccb download os_project=test-project packages=python-flask architecture=aarch64 -s
```

-d的用法：
```
# 使用-d 表示下载该packages的debug（debuginfo和debugsource）包。示例如下所示：
ccb download os_project=test-project packages=python-flask architecture=aarch64 -d
```

-b的用法：
```
# 使用-b all 表示下载该packages的所有子包。示例如下所示：
ccb download os_project=test-project packages=python-flask architecture=aarch64 -b all

# 使用-b $rpm 表示下载该packages的指定子包$rpm，指定多个子包以逗号分隔。示例如下所示：
ccb download os_project=test-project packages=python-flask architecture=aarch64 -b python2-flask
ccb download os_project=test-project packages=python-flask architecture=aarch64 -b python2-flask,python3-flask
```

-s -d -b 组合使用
```
# 使用-b all -s -d 表示下载该packages的debug包，源码包和所有子包。示例如下所示：
ccb download os_project=test-project packages=python-flask architecture=aarch64 -b all -s -d

# 使用-b $rpm -s -d 表示下载该packages的debug包，源码包和指定子包（指定多个子包以逗号分隔）。示例如下所示：
ccb download os_project=test-project packages=python-flask architecture=aarch64 -b python2-flask -s -d
ccb download os_project=test-project packages=python-flask architecture=aarch64 -b python2-flask,python3-flask -s -d
```

**7. cancel 取消构建任务**

```
ccb cancel $build_id

```

**8. 查看job日志**

```
ccb log $job_id
```

**9. 通过rpm包查询job相关信息**
```
ccb query -f job_id -r rpm_path #该rpm包为统一构建平台构建产物, 可查询多个job信息，rpm包路径/srv/repositories/$os_project/... 可使用tab键到对应架构的Packages目录下：
ccb query -f 'job_id, os_project' -r rpm_path
```

**10. 本地构建 **
说明：
1、创建工程时应选择openEuler-22.03-LTS-Next、openEuler-22.03-LTS-SP1、openEuelr-22.03-LTS-SP2、openEuelr-22.03-LTS-SP3、openEuler-20.03-LTS-SP4以上分支

```
ccb local-build os_project=xx package=xx --rm --debug=bp/bc/bi  # os_project可选择私有工程列表中已创建的工程，package选择该工程中的软件包
ccb local-build os_project=xx package=xx spec=gcc.spec --rm --debug=bp/bc/bi
ccb lb os_project=xx package=xx --rm --debug=bp/bc/bi
```

使用rm删除本次构建环境，反之构建环境一直保留
```
ccb local-build os_project=xx package=xx --rm
```
使用debug表示可将构建在执行到pre(解压与打补丁), build,install阶段停止，并进入容器进行调试 
```
ccb local-build os_project=xx package=xx --debug=bp
ccb local-build os_project=xx package=xx --debug=bc
ccb local-build os_project=xx package=xx --debug=bi
```
**11. 重复构建**
```
ccb local-rebuild job_id=cbs.001 --showdocker  # job_id应为系统真是存在的id信息
ccb lr job_id=cbs.001 --showdocker
```

使用showdocker构建完成后显示本次构建容器名称和容器id
```
ccb local-rebuild job_id=cbs.001 --showdocker
```

**12. 单包指定增量构建**

```
ccb build os_project=xx build_type=specified --json select_pkgs.json  #os_project可选择私有工程列表中已创建的工程
```

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
