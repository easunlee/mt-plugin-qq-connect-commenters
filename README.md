# QQ互联插件-用QQ账号登陆您的MT
( QQ Connect Commenters Plugin for Movable Type )


Authors:[ 路杨 (EasunLee)](http://easun.org/)
Copyright 2015 [Easun.org](http://easun.org/).
License: Artistic, licensed under the same terms as Perl itself

## 概述

MT QQ互联插件 (QQ Connect Commenters plugin for Movable Type) 允许用户用 QQ 号码登陆你的 [Movable Type](https://movabletype.org/) 博客。<br>
本插件严格使用 [QQ互联](http://connect.qq.com) 的 Open API 编写。安全可靠。
它可以给您的博客带来良好的用户体验。
一旦使用这个插件，评论者可以自动获取QQ昵称、头像等资源。


**请注意:** [QQ互联 （QQ Connect）](http://connect.qq.com)官方使用的机制是审核制度，并不是使用这个插件就直接可以使用QQ登陆。 您需要去  [QQ互联 （QQ Connect）](http://connect.qq.com/intro/login) 官方注册您使用本插件的网站并获取属于自己的 APPID 并提交审核。审核过程可能需要1周或者更长时间。

关于 [QQ互联 （QQ Connect）](http://connect.qq.com) 的注册，请 百度 之。或者读取官方资料： [http://wiki.connect.qq.com/](http://wiki.connect.qq.com/)。


## 运行环境

* Movable Type 4.2 或者更高版本
* JSON::XS 2.0 或者更高版本
* jQuery  (非必需，建议)

Movable Type 的 `extlib` 中已经包含了必需的 JSON：XS 版本。

## 安装


1. [下载](https://github.com/easunlee/mt-plugin-qq-connect-commenters/archive/master.zip)并解压本插件。

2. 复制(上传) `QQCommenters/mt-static` 下的内容到 `/path/to/mt/mt-static/`

4. 复制(上传) `QQCommenters/plugins` 下的内容到 `/path/to/mt/plugins/`

5. 登陆您的 Movable Type 后台 -> `Plugin Settings` 去设置您的 QQ `APP ID` 和 `APP KEY`。 <br />
6. 在 后台->`Registration Settings` -> `Authentication Methods` 中选启用 QQ 。<br />
7. 在前台选择登陆，您会看见 QQ 登陆 的选项已经有了。 如果您的网站通过审核，可以之直接使用了。


## 关于 QQ互联 功能的申请

 关于 QQ互联 功能的申请，简单减少一下流程：

1. 用您的QQ账号登陆 [http://connect.qq.com/intro/login](http://connect.qq.com/intro/login) 并申请网站接入。 
2. 详细描述您要接入的网站信息。请注意 **回调地址** 一定要填写为**您的Movable Type 后台 `CommentScript` 的完整地址，并且带上 `http://` 或者 `https://` 的前缀**。比如 (`http://your_domain/cgi-bin/mt/mt-comments.cgi`)。 <br >可以设置多个回调地址，用 分号 分开即可。 [QQ互联 （QQ Connect）](http://connect.qq.com) 的官方APP帮助文档 写的像浆糊一样，而且处处错误。这个地方官方文档写就是有问题。
3. 腾讯 的QQ [登陆审核](http://wiki.connect.qq.com/%E7%BD%91%E7%AB%99%E6%8E%A5%E5%85%A5%E6%B5%81%E7%A8%8B)一个要求，就是登陆页面要设置 **醒目的QQ登录入口**。而我们的前端如果不做修改的话，会很简洁，这个就需要自己在前台放端代码。 简单的分享一下我的一些前端 JS 代码：<br />  


##前端代码   

 *function QQSignIn()* 

    function QQSignIn() {
    var doc_url = document.URL;
    doc_url = doc_url.replace(/#.+/, '');
    var url = '<$mt:CGIPath$><$mt:CommentScript$>?__mode=login_external&key=QQ&blog_id=<$mt:BlogID$>';
    if (is_preview) {
    if ( document['comments_form'] ) {
    var entry_id = document['comments_form'].entry_id.value;
    url += '&entry_id=' + entry_id;
    } else {url += '&static=<$mt:BlogURL encode_url="1"$>'; }
    } else {url += '&static=' + encodeURIComponent(doc_url);
    }
    mtClearUser();
    location.href = url;
    }
    
*function QQSignInOnClick()*

    function QQSignInOnClick(sign_in_element) {
    var el;
    if (sign_in_element) { el = document.getElementById(sign_in_element);}
    if (el) el.innerHTML = 'Signing in... <span class="status-indicator">&nbsp;</span>';
    mtClearUser(); // clear any 'anonymous' user cookie to allow sign in
    QQSignIn();
    return false;
    }

这样话，只用使用 `<span class="QQ_signin_span" title="Sign in with your QQ Account" onclick="return QQSignInOnClick('signin-widget-content')"></span>` 即可展示出 QQ 登陆按钮。 <br />
当然，这样需要添加 CSS:

    .QQ_signin_span {
      background-image: url("/mt-static/plugins/QQCommenters/Connect_logo_3.png");
      background-repeat: no-repeat;
      background-position: 50% 50%;
      overflow: hidden;
      width: 120px;
      display: inline-block;
      height: 24px;
      padding: 0px;
      margin: 0px 2px;
      vertical-align: bottom;
      cursor: pointer;
    }

##On Github

 + [https://github.com/easunlee/mt-plugin-qq-connect-commenters](https://github.com/easunlee/mt-plugin-qq-connect-commenters)
 + [下载地址](https://github.com/easunlee/mt-plugin-qq-connect-commenters/archive/master.zip)
 + [http://git.easun.org/mt-plugin-qq-connect-commenters/](http://git.easun.org/mt-plugin-qq-connect-commenters/)