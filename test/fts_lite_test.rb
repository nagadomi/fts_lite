# coding: utf-8
require 'test_helper'

class FtsLiteTest < Test::Unit::TestCase
  DB_FILE = File.expand_path(File.join(File.dirname(__FILE__), "test.sqlite3"))
  puts "RUBY_VERSION => #{RUBY_VERSION}"
  puts "SQLITE3_VERSION => #{FtsLite::Index.sqlite3_version}"
  puts "SQLITE_HAVE_FT4_REPLACE => #{FtsLite::Index.have_ft4_replace}"
  def setup
    if (File.exist?(DB_FILE))
      File.unlink(DB_FILE)
    end
  end
  def teardown
  end
  def test_update
    FtsLite::Index.open(DB_FILE, :tokenizer => :bigram) do |db|
      db.transaction do 
        db.delete_all

        assert_equal db.search("赤い").size, 0
        db.set(1, "なぜナポリタンは赤いのだろうか ？", 2)
        db.set(2, "昼飯のスパゲティナポリタンを眺めながら、積年の疑問を考えていた。 ", 1)
        
        assert_equal db.search("赤い").size, 1
        assert_equal db.search("ナポリタン", :order => :desc).size, 2
        assert_equal db.search("ナポリタン", :order => :desc)[0], 1
        assert_equal db.search("ナポリタン", :order => :desc)[1], 2
        assert_equal db.search("赤い　ナポリタン", :order => :desc).size, 1
        
        db.set(1, "なぜナポリタンは青いのだろうか ？", 0)
        assert_equal db.search("赤い").size, 0
        assert_equal db.search("青い").size, 1
        
        assert_equal db.search("ナポリタン", :order => :desc).size, 2
        assert_equal db.search("ナポリタン", :order => :desc)[0], 2
        assert_equal db.search("ナポリタン", :order => :desc)[1], 1
      end
    end
  end
  def test_bigram
    db = FtsLite::Index.open(DB_FILE, :tokenizer => :bigram)
    db.transaction do 
      db.delete_all
      p db.tokenize("なぜナポリタンは赤いのだろうか ？")
      db.set(1, "なぜナポリタンは赤いのだろうか ？", 2)
      db.set(2, "昼飯のスパゲティナポリタンを眺めながら、積年の疑問を考えていた。 ", 1)
      
      assert_equal db.search("赤い").size, 1
      assert_equal db.search("赤い")[0], 1
      
      assert_equal db.search("ナポリタン").size, 2
      assert_equal db.search("ナポリタン")[0], 1
      assert_equal db.search("ナポリタン")[1], 2
      assert_equal db.search("赤い　ナポリタン", :order => :desc).size, 1
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 1
      assert_equal db.search("ナポリタン", :order => :desc)[1], 2
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 2
      assert_equal db.search("ナポリタン", :order => :asc)[1], 1
      
      db.update_sort_value(1, 1)
      db.update_sort_value(2, 2)
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 2
      assert_equal db.search("ナポリタン", :order => :desc)[1], 1
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 1
      assert_equal db.search("ナポリタン", :order => :asc)[1], 2
    end
  end
  def test_trigram
    db = FtsLite::Index.open(DB_FILE, :tokenizer => :trigram)
    db.transaction do 
      db.delete_all
      p db.tokenize("なぜナポリタンは赤いのだろうか ？")
      db.set(1, "なぜナポリタンは赤いのだろうか ？", 2)
      db.set(2, "昼飯のスパゲティナポリタンを眺めながら、積年の疑問を考えていた。 ", 1)
      
      assert_equal db.search("赤いの").size, 1
      
      assert_equal db.search("ナポリタン").size, 2
      assert_equal db.search("ナポリタン")[0], 1
      assert_equal db.search("ナポリタン")[1], 2
      assert_equal db.search("赤いの　ナポリタン", :order => :desc).size, 1
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 1
      assert_equal db.search("ナポリタン", :order => :desc)[1], 2
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 2
      assert_equal db.search("ナポリタン", :order => :asc)[1], 1
      
      db.update_sort_value(1, 1)
      db.update_sort_value(2, 2)
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 2
      assert_equal db.search("ナポリタン", :order => :desc)[1], 1
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 1
      assert_equal db.search("ナポリタン", :order => :asc)[1], 2
    end
  end
  def test_wakachi_bigram
    db = FtsLite::Index.open(DB_FILE, :tokenizer => :wakachi_bigram)
    db.transaction do 
      db.delete_all
      p db.tokenize("なぜナポリタンは赤いのだろうか ？")
      db.set(1, "なぜナポリタンは赤いのだろうか ？", 2)
      db.set(2, "昼飯のスパゲティナポリタンを眺めながら、積年の疑問を考えていた。 ", 1)
      
      assert_equal db.search("赤い").size, 1
      assert_equal db.search("赤い")[0], 1
      
      assert_equal db.search("ナポリタン").size, 2
      assert_equal db.search("ナポリタン")[0], 1
      assert_equal db.search("ナポリタン")[1], 2
      assert_equal db.search("赤い　ナポリタン", :order => :desc).size, 1
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 1
      assert_equal db.search("ナポリタン", :order => :desc)[1], 2
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 2
      assert_equal db.search("ナポリタン", :order => :asc)[1], 1
      
      db.update_sort_value(1, 1)
      db.update_sort_value(2, 2)
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 2
      assert_equal db.search("ナポリタン", :order => :desc)[1], 1
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 1
      assert_equal db.search("ナポリタン", :order => :asc)[1], 2
    end
  end
  def test_simple
    db = FtsLite::Index.open(DB_FILE, :tokenizer => :simple)
    db.transaction do 
      db.delete_all
      p db.tokenize("なぜ ナポリタン は 赤い の だろ う か ？")
      db.set(1, "なぜ ナポリタン は 赤い の だろ う か ？", 2)
      db.set(2, "昼飯 の スパゲティ ナポリタン を 眺め ながら 、 積年 の 疑問 を 考え て い た", 1)
      
      assert_equal db.search("赤い").size, 1
      assert_equal db.search("赤い")[0], 1
      
      assert_equal db.search("ナポリタン").size, 2
      assert_equal db.search("ナポリタン")[0], 1
      assert_equal db.search("ナポリタン")[1], 2
      assert_equal db.search("赤い　ナポリタン", :order => :desc).size, 1
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 1
      assert_equal db.search("ナポリタン", :order => :desc)[1], 2
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 2
      assert_equal db.search("ナポリタン", :order => :asc)[1], 1
      
      db.update_sort_value(1, 1)
      db.update_sort_value(2, 2)
      
      assert_equal db.search("ナポリタン", :order => :desc).size, 2
      assert_equal db.search("ナポリタン", :order => :desc)[0], 2
      assert_equal db.search("ナポリタン", :order => :desc)[1], 1
      
      assert_equal db.search("ナポリタン", :order => :asc).size, 2
      assert_equal db.search("ナポリタン", :order => :asc)[0], 1
      assert_equal db.search("ナポリタン", :order => :asc)[1], 2
    end
  end
  def test_fuzzy
    db = FtsLite::Index.open(DB_FILE, :tokenizer => :bigram)
    db.transaction do
      db.delete_all
      db.set(1, "あいいいう")
      db.set(2, "あいいう")
      assert_equal db.search("あいい").size, 2
      assert_equal db.search("あいう").size, 0
      assert_equal db.search("あいい", :fuzzy => true).size, 2
      assert_equal db.search("あいう", :fuzzy => true).size, 2
      assert_equal db.search("あいい", :fuzzy => false).size, 2
      assert_equal db.search("あいう", :fuzzy => false).size, 0
    end
  end
  def test_create
    db = FtsLite::Index.open(DB_FILE)
    db.drop_table!
    db.close
    FtsLite::Index.open(DB_FILE, :table_name => "hogehgoe") do |f|
      f.drop_table!
    end
  end
end
