# FtsLite

full text search index.

## Installation

Add this line to your application's Gemfile:

    gem 'fts_lite'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fts_lite

## Usage

    require 'fts_lite'
    
    db = FtsLite::Database.new("./db.sqlite3", :tokenizer => :bigram, :cache_size => 64000)
    
    docid = 1
    text = "hoge piyo"
    sort_value = "2012-08-01"
    
    db.transaction do
      db.update(docid, text, sort_value)
    end
    
    db.search('piyo', :order => :desc, :limit => 10).each do |docid|
      p docid
    end
