<%= pagebreak %>

# Docker による環境構築
{: .counting }

これは Webook の機能そのものとはいえませんが、使い勝手の面からやっておいた方が良さそうです。
Webook を実装した当初はこうした執筆ツールの単独での実行環境を仮想化環境の上に構築する形で提供するといったことは、少なくとも筆者の覚えている範囲ではそれほどなかったと思います。


## プレイグラウンドとしてのDocker
{: .counting }

Ruby をインストールして wkhtmltopdf をインストールして…という手数こなしてやっと試せるという状態より「コンテナイメージを用意して起動」とだけやれば macOS や Windows、Linux といったホスト OS の環境を問わず動くのはやはり強いです。
Docker そのものをインストールしてもらわなくてはなりませんが、それらを込みで手間を天秤にかけた場合、やはり Docker 上にプレイグラウンドを作成するという方法の方が上策といえるのではないでしょうか。

また、Dockerfile として記述しておけば、マニュアルでセットアップする際の資料としても役に立つでしょう。
Re:VIEW なんかは有志が Docker イメージを配布していたと記憶していますが、現実的にRe:VIEW のバックエンドとなる各種ソフトウェアをインストールした状態で、さらに動作確認がとれた状態でパッケージして配布されているのは利用者の視点からみて便利だと思います。


## Docker コンテナイメージを作成する
{: .counting }

さて、グダグダしたところで本題です。
といっても、見出しのとおりに Docker による環境構築を行うだけです。
適当に Dockerfile を書いてビルドするだけですね。
内部で webook コマンドが動作するようなコンテナイメージを作成し、そこにシェルでログインして操作を行います。
ちょっとしたポイントとしては、Docker 対応を行うためのファイル群は、Webook 本体とは別のリポジトリで管理するようにすることです。
ここでは便宜的に、次のように記述して説明します。


- Webook …… Webook 本体 [^webook]
- webook …… コマンドラインアプリケーションとしての webook
- webook-docker …… Webook の Docker による実行環境を提供するためのもの [^webook-docker]


言うにおよばずですが、webook-docker の方も Github にて公開していますので、読者の皆さんも自由にお試しいただけます。 
ちなみに、コンテナイメージの作成、及び動作確認に使用した Docker のバージョンは次のとおりです。


    $ docker --version
    Docker version 18.03.1-ce, build 9ee9f40


[^webook]: https://github.com/CHIKUWAODEN/webook
[^webook-docker]: https://github.com/CHIKUWAODEN/webook-docker

<%= pagebreak %>


## Dockerfile の説明
{: .counting }

せっかくなので、どのようなセットアップになっているのかご紹介します。
といっても、なんの変哲もない Dockerfile です（レイアウトの都合上、実際のものから少し整形しています）。


    FROM ubuntu:bionic

    # Install packages
    RUN apt-get -y update && \
        apt-get -y upgrade && \
        apt-get -y install git gcc g++ make curl wget sudo
    RUN apt-get -y install ruby-build ruby-dev

    WORKDIR /webook

    # Install wkhtmltopdf
    RUN wget \
    -q https://builds.wkhtmltopdf.org/0.12.6-dev/wkhtmltox_0.12.6-0.20180618.3.dev.e6d6f54.bionic_amd64.deb \
        -O wkhtmltopdf.deb && \
        apt-get -y install -f ./wkhtmltopdf.deb && \
        wkhtmltopdf --help

    # add sudo user
    RUN groupadd -g 1000 webook && \
        useradd \
        -g webook \
        -G sudo \
        -m \
        -s /bin/bash webook && \
        echo 'webook:webook' | chpasswd

    RUN echo 'Defaults visiblepw' \
        >> /etc/sudoers && \
        echo 'webook ALL=(ALL) NOPASSWD:ALL' \
        >> /etc/sudoers


    USER webook
    WORKDIR /home/webook

    # Install Webook
    RUN git clone https://github.com/CHIKUWAODEN/webook.git webook && \
        cd webook && \
        sudo gem install bundler && \
        bundle install && \
        rake build && \
        sudo gem install \
        --local ./pkg/webook-0.0.1.gem && \
        webook

    # Make port 80 available to the world outside this container
    EXPOSE 80

    WORKDIR /
    CMD "/bin/bash"


Webook は一応 gem の体裁はとっていますが、rubygems.org 上で公開しているものではありません。
よって、Github からリポジトリをチェックアウト、それをビルドした成果物として得られる gem パッケージをローカルからインストールしています。


## webook-docker の使い方
{: .counting }

この節では、webook-docker の基本的な使い方を解説します。
Docker そのものの解説やコマンドリファレンスは、公式のドキュメントなどに任せるとして、この節では webook-docker を使うたの情報を中心とし、Docker についての解説はできるだけ少なくとどめようと思います。
もし Docker についての基礎知識を得たいのであれば、公式サイト をご覧になるのがいちばんの近道でしょう。


## Docker イメージのビルドとコンテナの起動
{: .counting }

基本的には添付の Makefile を利用するだけで事足りるようになっています。
Makefile で定定義されたターゲットは次のとおりです。


build
: イメージをビルドします。

rebuild
: キャッシュを使わずにイメージをビルドします。

run
: ビルドしたイメージをコンテナとして実行します。
: 実行すると、Docker コンテナ上のシェルのプロンプトが表示され、対話的な操作が可能になります。



`make run` によるシェルの対話モードから抜ける場合、`Ctrl-P, Ctrl-Q` とすることで、Docker のデタッチという操作を行うことができるので、これを推奨しています。
デタッチした場合、コンテナは停止されることなく実行が継続され、アタッチしなおすことでシェル操作を再開することも可能です。
シェル上で `exit` コマンドを実行することでも抜けることは可能ですが、この場合 Docker コンテナが停止してしまいます。
そのため、再度接続する場合にはもう一度 `docker run` コマンドを実行しなくてはなりません。


<%= pagebreak %>


## webook-docker 以下に Webook プロジェクトを配置する
{: .counting }

### 既存の Git リポジトリがある場合
{: .counting }

すでに Webook プロジェクトの Git リポジトリがある場合は、webook-docker のサブリポジトリとして扱うのが適当でしょう。
本節では、デモンストレーション用に Github 上に用意した Git リポジトリ CHIKUWAODEN/webook-sample[^webook-sample] を用いて、具体的な手順を次に示します。

    $ git clone https://github.com/CHIKUWAODEN/webook-docker webook-docker
    $ cd /path/to/webook-docker
    $ git submodule add https://github.com/CHIKUWAODEN/webook-sample.git book/webook-sample
    $ git submodule
    09175867cf604ea7a051d0696ef897bd4a15c8e4 book/webook-sample (heads/master)


webook-docker の book ディレクトリ以下は .gitignore で無視するよう設定されているため、本来であれば submodule を追加することはできません。
そのため、`git submodule add` コマンドに `-f` オプションを指定することでサブモジュールとして追加しています。
これで、コンテナ上に `/book/webook-sample` として Webook のプロジェクトが配置された形になります。
あとは `make run` でコンテナのシェルを立ち上げて Webook による操作を行ってください。


[^webook-sample]: [https://github.com/CHIKUWAODEN/webook-sample](https://github.com/CHIKUWAODEN/webook-sample)


### webook コマンドによって新規にプロジェクトを作る場合
{: .counting }

新規に Webook プロジェクトを作る場合はコンテナの `/webook-docker/book` ディレクトリ以下で `webook create` コマンドを実行します。
このように、webook コマンド自体を簡単に使える環境を提供できるというのは、Docker 環境を提供することによって生じる明らかなメリットなので、グッドな感じがありますね。


    $ webook create ./hello
    [Webook] Create Webook project, name: ./hello
    [Webook] Project has been created
    $ cd hello && webook build
    ...（略）


作成したプロジェクトは、 Git リポジトリとして初期化したのち、適当に `git add remote` などでリモートリポジトリを追加、そこにプッシュなどの操作を行うことになるでしょう。
あるいは、他の VCS なども任意でチョイスできますので、そこはユーザーの裁量に任せることになります。
この辺は各々の世界観でうまいことやっていきましょう。

`/webook-docker/book` ディレクトリ以下は Docker とホストとでファイルを共有するためのワークスペースです。
Webook プロジェクトを配置することを念頭においていますが、ファイル配置については任意に行ってください。

次の例では、`webook-docker/book` ディレクトリ以下に hello という Webook プロジェクトを配置した場合の webook-docker のルートからのディレクトリ構造を示したものです。
book 以下にプロジェクトごとのディレクトリを切っておくことによって、複数の Webook プロジェクトを一つの Docker 環境ですべて賄うことを意図した作りにしています。
もちろん、`webook-docker/book` ディレクトリ以下に直接 Webook プロジェクトの各種ファイルを配置してしまってもかまいません。


    webook-docker $ tree  
    .
    ├── Dockerfile
    ├── LICENSE
    ├── Makefile
    ├── README.md
    └── book
        └── hello
            ├── Webookfile
            ├── output
            │   ├── Webook sample.html
            │   ├── Webook sample.pdf
            │   └── Webook sample.xsl
            ├── src
            │   ├── main.md
            │   ├── pos.md
            │   ├── pre.md
            │   └── stylesheet.css
            ├── template
            │   ├── default.erb
            │   ├── footer.html
            │   └── header.html
            └── tmp
                ├── _main.html
                ├── _pos.html
                └── _pre.html


## この章のまとめ
{: .counting }

Docker 対応を行ったことにより、プロジェクトの導入から立ち上げまでがよりスムーズになりました。
Webook というツールが自分以外の誰かから使われることはそうそうないと思いますが、自分自身への説明という意味だけで十分にやった価値はあると思います。
本誌をご覧の皆さんも、ぜひ webook-docker を使って Webook を動かしてみてください。

<%= pagebreak %>