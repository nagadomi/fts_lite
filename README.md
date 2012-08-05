# FtsLite

FtsLiteは組み込み型お手軽全文検索エンジンのRubyライブラリです。
基本的にはSQLite3 FTS4のラッパーで、日本語のbigramやtrigram、wakachi_bigramなどのトークナイザーをRubyのレイヤで実装したものです。

qarc.info で使われています。

Ruby 1.9.2 以降と、FTS4 に対応してる SQLite3 が必要で、SQLite3 はできれば 3.7.7 以降がよいです（FTS4の仮想テーブルに対するINSERT OR REPLACEが実装されているのでsetのパフォーマンスがよい）。

## Installation

Add this line to your application's Gemfile:

    gem 'fts_lite'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fts_lite

## Usage

    # -*- coding: utf-8 -*-
    require 'fts_lite'

    FtsLite::Index.open("./index.sqlite3") do |db|
      # set(docid, text, sort_value = nil)
      db.set(1, "なぜナポリタンは赤いのだろうか？")
      db.set(2, "昼飯のスパゲティナポリタンを眺めながら、積年の疑問を考えていた。")
    
      # docid_array = search(query, options = {})
      docids = db.search("ナポリタン")
      puts docids.join(",")
      
      docids = db.search("赤い ナポリタン")
      puts docids.join(",")
      
      # update_sort_value(docid, sort_value)
      db.update_sort_value(1, 2)
      db.update_sort_value(2, 1)
      
      docids = db.search("ナポリタン", :order => :asc, :limit => 1)
      puts docids.join(",")
    end

set(docid, text, sort\_value)でデータを登録します。
docidはレコードを表すIDで search ではこのIDの配列を検索結果として返します。
textは全文検索インデックスのためのテキストデータです。取り出すことはできないので、元のデータは別のデータベースにあることを想定しています。
sort\_valueはソート用の値で、searchの時にこの値でソートしたり、ソートしたうえで上位N件を取り出したりできます。

search(query, options) で検索できて、queryは空白区切りでAND検索です。このへんの仕様は用途によっていろいろだと思うけど、僕はテキトウにANDだけできればいいやと思っているので、いじりたい人は lib/tokenizer.rb の各トークナイザで定義してある query というメソッドをいじってください。
optionsは :order に :desc か :asc を指定すると sort\_value で昇順ソートまたは降順ソートします。 :order が指定されない場合は docid の昇順になります。:limit => N を指定すると検索結果の上位N件だけを返します。

## Railsで使う

まず config/application.rb あたりで

    QUESTION_FTS = FtsLite::Index.open(File.join(Rails.root.to_s, "fts", "index.sqlite3"), :table_name => "questions")
    THREAD_FTS = FtsLite::Index.open(File.join(Rails.root.to_s, "fts", "index.sqlite3"), :table_name => "threads")
    # ...

とコネクションを作ってグローバルにアクセスできるようにしておきます。
モデルでしか使わない場合は、モデルの中で定義したほうがいいかもしれません。
:table\_name を指定するとひとつのDBファイルに複数の全文検索インデックスが持てます。

あとは、たとえば、Question という ActiveRecord のモデルがあって、全文検索用のテキストデータ（内容やタイトルなんかを適当に結合した文字列）を作成する make\_ft というメソッドとソート用の表示数 view_count というカラムがあるとすると

    class Question < ActiveRecord::Base
       LIMIT = 1000
       after_save :set_ft
       
       def set_ft
         QUESTION_FTS.set(id, make_ft, view_count)
       end
       def search(query)
          find(:all,
               :conditions => ["id in (?)", QUESTION_FTS.search(query, :order => :desc, :limit => LIMIT)],
               :order => "view_count DESC")
       end
       # def make_ft ...
    end

まず after\_save でレコードの更新時に全文検索インデックス側も更新するようにしておきます。
search というメソットでは、全文検索を行って、その結果(IDの配列)を含むレコードをさらにDBに問い合わせることで検索結果となるレコードを返しています。

この実装だとレプリケーションしている場合に、別のサーバーでレコードが更新されるとトリガーが効かなくてローカルの全文検索インデックスが更新されないことに注意してください。
そういう場合は、定期ジョブで適当に同期すればいいと思います。

