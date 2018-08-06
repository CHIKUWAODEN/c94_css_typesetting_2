<%= pagebreak %>

小ネタ
========
{: .counting }

この章では TIPS であるとか執筆中にまとめたこと、トラブルなど雑多なことを書いていこうと思います。


wkhtmltopdf をインストールするのに苦労した話
------
{: .counting }

先に紹介した Webook の Dockerfile ですが、Debian 系（Ubuntu）のディストリビューションがベースとなっています。
当初は alpine をベースにしていたのですが、結局のところそれをやめてしまった理由が wkhtmltopdf にあります。

まず、alpine のパッケージマネージャ（apk）で wkhtmltopdf をインストールすることができなかったというのがあります。
であればソースコードからビルドするくらいはしてやろうか、と思ったのですが、wkhtmltopdf のビルドシステムは独特のビルド及びパッケージのツールを用いているようでした。
本筋から逸れる形でそれらを調査するより、適当かつ安定した、オフィシャルで提供されているビルド済みのバイナリを利用するほうが得策だろうと判断したため、Ubuntu をベースとした環境を作る方面にシフトした次第です。

<%= pagebreak %>

wkhtmltopdf 目次生成のバグ
--------
{: .counting }

これを書いている時点での wkhtmltopdf の最新の安定リリースバージョンは、0.12.5 なのですが、どうやら目次の生成に不具合があるらしいです。
この問題は Github 上で Issue としても報告されています。


- [https://github.com/wkhtmltopdf/wkhtmltopdf/issues/3953]()


最新の開発ビルドである 0.12.6-dev では修正されているとのことで、そちらのパッケージを直接ダウンロードしてインストールするようにしています。


    # Install wkhtmltopdf
    RUN wget \
        -q https://builds.wkhtmltopdf.org/0.12.6-dev/wkhtmltox_0.12.6-0.20180618.3.dev.e6d6f54.ˀbionic_amd64.deb \
        -O wkhtmltopdf.deb && \
        apt-get -y install -f ./wkhtmltopdf.deb && \
        wkhtmltopdf --help


あとは気をつける点として、なぜか `--toc-header-text` オプションが機能しないというのがあります。
仕方ないため、これは TOC 用のテンプレートファイル（.xsl）を直接編集することで対応しました。

<%= pagebreak %>

改ページ
--------
{: .counting }

強制的な改ページを行うために、次のような CSS を定義しています。

    body.main div.pagebreak {
        page-break-before: always;
        height:  1px;
        padding: 0px;
        margin: 0px;
    }


そして、次のように記述することで、改ページを行います。


    <div class="pagebreak">&nbsp;</div>


ポイントとなるのが、CSS で設定された `height: 1px` の設定と、div タグにくくられた `&nbsp;` の存在です。 
どういう訳かはわかりませんが、div をレンダリングしたサイズがゼロになると、改ページされないようです。
wkhtmltopdf がからんでいるのか Webkit 由来のものなのか定かではありませんが、邪魔にならない程度に中身をいれてやることにしました。

強制的な改ページは、不自然なレイアウトを避けるうえで役にたってくれましたが、また別の問題が現れました。
それは、`h2` などのタグで改ページ直後かどうかを判別することができないため、タグ自体に下手に top にマージンやパディングを入れておいたりすると改ページ後に微妙な間が生まれてしまいます。
ここからは妄想というか想像なのですが、改ページ直後だったら、あるいはそうでなかったらというのを擬似セレクタをつかって設定できるようにならないかなと思います。