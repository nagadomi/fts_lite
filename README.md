# FtsLite

simple full text search engine.

## Installation

Add this line to your application's Gemfile:

    gem 'fts_lite'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fts_lite

## Usage

    require 'fts_lite'
    
    db = FtsLite::Database.new("./db.sqlite3", :tokenizer => :wakachi_bigram, :cache_size => 64000)
    
    docid = 1
    text = "hoge piyo"
    sort_value = "2012-08-01"
    
    db.transaction do
      db.insert_or_replace(docid, text, sort_value)
      db.batch_insert_or_replace([
        {:docid => 30, :text => "hoge hoge", :sort_value => '2012-08-01'},
        {:docid => 40, :text => "piyo piyo", :sort_value => '2012-08-02'}
      ])
    end
    
    db.search('piyo', :order => :desc, :limit => 10).each do |docid|
      p docid
    end
    
    
    db.batch_update_sort_value([
      {:docid => 30, :sort_value => '2012-07-01'},
      {:docid => 40, :sort_value => '2012-07-02'}
    ])
    
    db.search('piyo', :order => :desc, :limit => 10).each do |docid|
      p docid
    end

