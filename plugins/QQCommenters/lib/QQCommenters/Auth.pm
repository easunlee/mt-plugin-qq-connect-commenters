package QQCommenters::Auth;
use strict;
use warnings;

my $PluginKey = 'QQCommenters';

sub password_exists {0}

sub instance {
    my ($app) = @_;
    $app ||= 'MT';
    $app->component($PluginKey);
}


sub condition {
    my ( $blog, $reason ) = @_;
    return 1 unless $blog;
    my $plugin  = instance();
    my $blog_id = $blog->id;
    my $QQ_api_key
        = $plugin->get_config_value( 'QQ_app_key', "blog:$blog_id" );
    my $QQ_api_secret
        = $plugin->get_config_value( 'QQ_app_secret', "blog:$blog_id" );
    return 1 if $QQ_api_key && $QQ_api_secret;
    $$reason
        = '<a href="?__mode=cfg_plugins&amp;blog_id='
        . $blog->id . '">'
        . $plugin->translate('Set up QQ Commenters plugin') . '</a>';
    return 0;
}

sub commenter_auth_params {
    my ( $key, $blog_id, $entry_id, $static ) = @_;
    require MT::Util;
    if ( $static =~ m/^https?%3A%2F%2F/ ) {
        # the URL was encoded before, but we want the normal version
        $static = MT::Util::decode_url($static);
    }
    my $params = {
        blog_id => $blog_id,
        static  => $static,
    };
    $params->{entry_id} = $entry_id if defined $entry_id;
    return $params;
}

sub __create_return_url {
    my $app = shift;
    my $q   = $app->param;
    my $cfg = $app->config;

    my $blog_id = $q->param("blog_id");
    $blog_id =~ s/\D//g;
    my $static = $q->param("static");

    require MT::Util;
    if ( $static =~ m/^https?%3A%2F%2F/ ) {
        # the URL was encoded before, but we want the normal version
        $static = MT::Util::decode_url($static);
    }

    my @params = (
        "__mode=handle_sign_in"
        , "key=QQ"
        , "blog_id=$blog_id"
        , "static=" . &_encode_url( $static ),
    );

    if ( my $entry_id = $q->param("entry_id") ) {
        $entry_id =~ s/\D//g;
        push @params, "entry_id=$entry_id";
    }

    my $return_url
        = $app->base
        . $app->path
        . $cfg->CommentScript . "?"
        . join( '&', @params );
        
  #    return  $return_url;
    return _encode_url($return_url);
}

sub login {
    my $class = shift;
    my ($app) = @_;
    my $q     = $app->param;

    my $blog_id          = $app->blog->id;
    my $QQ_api_key = instance($app)
        ->get_config_value( 'QQ_app_key', "blog:$blog_id" );

   my $return_url =  __create_return_url($app) ;
       #return $app->errtrans($return_url);
  
   require Digest::MD5;
   my $md5_state = Digest::MD5::md5_hex($return_url);

    my $url = "https://graph.qq.com/oauth2.0/authorize?"
        . join( '&',
        'response_type=code',
        #'display=mobile',
        "state=" . $md5_state,
        "client_id=" . $QQ_api_key,
        "redirect_uri=" . $return_url,
        );
       #return $app->errtrans($url);
   return $app->redirect($url);
  #   return   &test($app);

}

#         "__mode=handle_sign_in",
#         "response_type=code",
#          "key=QQ",
#         "blog_id=$blog_id",
#         "static=" . _encode_url( $static ),
#
sub handle_sign_in {
    my $class = shift;
    my ( $app, $auth_type ) = @_;
    my $q      = $app->param;
    my $plugin = instance($app);

    if ( $q->param("error") ) {
        return $app->error(
            $plugin->translate(
                "Authentication failure: [_1], reason:[_2]",
                $q->param("error"),
                $q->param("error_description")
            )
        );
    }
    ####
    my $user_data ;
    my ($qq_id,$nickname,$figureurl);

#     JS MODE # 没完全开放，需要配合 JSSDK来实现
#     if ( $q->param("js_mode") && $q->param("openid") ) #JS MODE # 没完全开放，需要配合 JSSDK来实现
#     {
#        $qq_id    =  $q->param("openid");
#        $nickname = $q->param("nickname");
#        $figureurl= $q->param("figureurl_qq_1");  # figureurl QQ空间 30x30头像。  figureurl_qq_1 为QQ本身头像，但是是40x40 注释 By 路杨（easun.org）
#     }

#   else #unless ($qq_id)  #我们认为是普通模式
#   {
         my $return_url = __create_return_url($app);
         ## 检测 state 是否一致，防止跨站漏洞  By 路杨###
        require Digest::MD5;
        my $md5_state = Digest::MD5::md5_hex($return_url);
        #return $app->errtrans($md5_state .'-VS-' .$q->param("state"))  ;

        if ( $q->param("state")  ne  $md5_state ) {
           return $app->errtrans(
               #$plugin->translate(
                "Authentication failure: [_1], reason:[_2]",
                'Invalid request',
                'I think the state-code is wrong.'
             # )
          );
        }
       #################################

         my $success_code = $q->param("code");  # Authorization Code 第一次我们想要的， By 路杨
         my $ua = $app->new_ua( { paranoid => 1 } );

         my $blog_id = $app->blog->id;
         my $QQ_api_key
              = $plugin->get_config_value( 'QQ_app_key', "blog:$blog_id" );
         my $QQ_api_secret
             = $plugin->get_config_value( 'QQ_app_secret', "blog:$blog_id" );


           my @url_params = (
              "client_id=$QQ_api_key",
              "redirect_uri=$return_url",
              "client_secret=$QQ_api_secret",
              "code=$success_code" ,
               'grant_type=authorization_code',
            );

         my $url = "https://graph.qq.com/oauth2.0/token?"
                    . join( '&', @url_params );
         #return $app->errtrans($url) ; #TEST#
         my $response = $ua->get($url);
         return $app->errtrans("Invalid request.-[_1]", "Get token not Success 1 form QQ.com.")
               unless $response->is_success;

         my $content = $response->decoded_content();
         return $app->errtrans("Invalid request.-[_1]", "Get token not Success 2 form QQ.com.")
                unless $content =~ m/^access_token=(.*)/m;

         my $access_token = $1;
               $access_token =~ s/\s//g;
               $access_token =~ s/&.*//;

          $url  = "https://graph.qq.com/oauth2.0/me?access_token=$access_token"; #第2次我们想要的access_token， By 路杨
          $response = $ua->get($url);
          return $app->errtrans("Invalid request.-[_1]", "Get openID not Success form QQ.com.")
                unless $response->is_success;

          ### 获取 openid
            my $data_tmps = $response->decoded_content();
                  $data_tmps =~ s/callback\(//g;
                  $data_tmps =~ s/\)\;//g;
           ###
            require JSON;
            my $user_data_temp = JSON::from_json( $data_tmps );
            $qq_id    = $user_data_temp->{openid};  #第3次我们想要的openid， 注释 By 路杨（easun.org）

             $url = "https://graph.qq.com/user/get_user_info?access_token=$access_token&oauth_consumer_key=$QQ_api_key&openid=$qq_id";
             $response = $ua->get($url);
             return $app->errtrans("Invalid request.-[_1]", "Get UserInfo not Success form QQ.com.")
                        unless $response->is_success;
              $user_data = JSON::from_json( $response->decoded_content() );
              $nickname = $user_data->{nickname};
              $figureurl    = $user_data->{figureurl_qq_1};  # figureurl QQ空间 30x30头像。  figureurl_qq_1 为QQ本身头像，但是是40x40 注释 By 路杨（easun.org）
              $figureurl =~ s{^http://}{https://};

#      } # End unless openid
 ################################################

    my $author_class = $app->model('author');
    my $cmntr        = $author_class->load(
        {   external_id      => $qq_id,
            type      => $author_class->COMMENTER(),
            auth_type => $auth_type,
        }
    );

    if ( not $cmntr ) {
        $cmntr = $app->make_commenter(
            external_id => $qq_id,
            name        => $nickname,
            nickname    => $nickname,
            auth_type   => $auth_type,
            hint         =>  $figureurl,   #我们用废弃的 hint 字段来存储远程头像路径， 当然我们也可以直接下载到本地
        );
    }

    return $app->error( $plugin->translate("Failed to created commenter.") )
        unless $cmntr;
            
    if ( 
           ($cmntr->hint ne  $figureurl) 
        #|| ($cmntr->name ne  $nickname)
       )
     {  
        $cmntr->hint($figureurl); 
        #$cmntr->name($nickname) ; 
        $cmntr->save ;
     }

## __get_userpic 为远程的QQ头像下载在本地，并生成不同大小的缩略图，比较消耗资源，可以屏蔽掉。
   __get_userpic($cmntr, $figureurl);

    $app->make_commenter_session($cmntr)
        or return $app->error(
        $plugin->translate("Failed to create a session.") );
    return $cmntr;
}

## OK, 我们把远程的QQ头像下载在本地。。。。。 注释 By 路杨（easun.org）###
sub __get_userpic {
    my ($cmntr,$figureurl) = @_;


    if ( my $userpic = $cmntr->userpic ) {
        require MT::FileMgr;
        my $fmgr     = MT::FileMgr->new('Local');
        my $mtime    = $fmgr->file_mod_time( $userpic->file_path() );
        my $INTERVAL = 60 * 60 * 24 * 7;
        if ( $mtime > time - $INTERVAL ) {

            # newer than 7 days ago, don't download the userpic
            return;
        }
    }

#         my $blog_id = $app->blog->id;
#         my $QQ_api_key
 #             = $plugin->get_config_value( 'QQ_app_key', "blog:$blog_id" );

    require MT::Auth::OpenID;
    my $picture_url  =$figureurl;
       # = "http://qzapp.qlogo.cn/qzapp/'
       #. $QQ_api_key
       #. '/'
       #. $cmntr->external_id
      #  . "/100";

    if ( my $userpic = MT::Auth::OpenID::_asset_from_url($picture_url) ) {
        $userpic->tags('@userpic');
        $userpic->created_by( $cmntr->id );
        $userpic->save;
        if ( my $userpic = $cmntr->userpic ) {

         # Remove the old userpic thumb so the new userpic's will be generated
         # in its place.
            my $thumb_file = $cmntr->userpic_file();
            my $fmgr       = MT::FileMgr->new('Local');
            if ( $fmgr->exists($thumb_file) ) {
                $fmgr->delete($thumb_file);
            }
            $userpic->remove;
        }
        $cmntr->userpic_asset_id( $userpic->id );
        $cmntr->save;
    }
}

sub __check_api_configuration {
    my ( $app, $plugin, $QQ_api_key, $QQ_api_secret ) = @_;

    if (    ( not eval { require Crypt::SSLeay; 1; } )
        and ( not eval { require IO::Socket::SSL; 1; } ) )
    {
        return $plugin->error(
            $plugin->translate(
                "QQ Commenters needs either Crypt::SSLeay or IO::Socket::SSL installed to communicate with QQ."
            )
        );
    }

    return $plugin->error(
        $plugin->translate("Please enter your QQ App key and secret.") )
        unless ( $QQ_api_key and $QQ_api_secret );
    return 1;
}

my $mt_support_save_config_filter;

sub plugin_data_pre_save {
    my ( $cb, $obj, $original ) = @_;

    return 1 if $mt_support_save_config_filter;

    my ( $args, $scope ) = ( $obj->data, $obj->key );

    return 1
        unless ( $obj->plugin eq $PluginKey )
        && ( $scope =~ m/^configuration/ );

    $scope =~ s/^configuration:?|:.*//g;
    return 1 unless $scope eq 'blog';

    my $QQ_api_key    = $args->{QQ_app_key};
    my $QQ_api_secret = $args->{QQ_app_secret};

    my $app    = MT->instance;
    my $plugin = instance($app);

    return __check_api_configuration( $app, $plugin, $QQ_api_key,
        $QQ_api_secret );
}

sub check_api_key_secret {
    my ( $cb, $plugin, $data ) = @_;

    $mt_support_save_config_filter = 1;

    my $app = MT->instance;

    my $QQ_api_key    = $data->{QQ_app_key};
    my $QQ_api_secret = $data->{QQ_app_secret};

    return __check_api_configuration( $app, $plugin, $QQ_api_key,
        $QQ_api_secret );
}

sub _encode_url {
    my ( $str, $enc ) = @_;
    $enc ||= MT->config->PublishCharset;
    my $encoded = Encode::encode( $enc, $str );
    $encoded =~ s!([^a-zA-Z0-9_.-])!uc sprintf "%%%02x", ord($1)!eg;
    $encoded;
}

1;
