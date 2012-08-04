require 'sqlite3'

module FtsLite
  class Database
    DEFAULT_TOKENIZER = :bigram
    DEFAULT_JURNAL_MODE = "MEMORY"
    DEFAULT_TEMP_STORE = "MEMORY"
    DEFAULT_CACHE_SIZE = 32000
    
    class RuntimeError < ::RuntimeError
    end
    
    def initialize(path, options = {})
      @db = SQLite3::Database.new(path)
      @table_name = options[:table_name] || "fts_lite"
      create_table!(options)
      set_db_param(options)
      @tokenizer = Tokenizer.create(options[:tokenizer] || DEFAULT_TOKENIZER)
    end
    def tokenize(text)
      @tokenizer.vector(text).split(" ")
    end
    def close
      @db.close
    end
    def transaction(&block)
      @db.transaction do
        block.call
      end
    end
    def insert_or_replace(docid, text, sort_value = nil)
      @db.execute("INSERT OR REPLACE INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);",
                  [docid, @tokenizer.vector(text), sort_value])
    end
    def update_sort_value(docid, sort_value)
      @db.execute("UPDATE #{@table_name} SET sort_value = ? WHERE docid = ?;",
                  [sort_value, docid])
    end
    def delete(docid)
      @db.execute("DELETE FROM #{@table_name} WHERE docid = ?;", [docid])
    end
    def search(text, options = {})
      limit = options[:limit]
      order = nil
      if (options[:order])
        case options[:order].to_sym
        when :desc
          order = :desc
        when :asc
          order = :asc
        end
      end
      sql = "SELECT docid FROM #{@table_name} WHERE text MATCH ?"
      if (order)
        sql += sprintf(" ORDER BY sort_value %s", order == :desc ? "DESC" : "ASC")
      else
        sql += sprintf(" ORDER BY docid ASC")
      end
      if (limit)
        sql += sprintf(" LIMIT %d", limit)
      end
      sql += ";"
      @db.execute(sql, [@tokenizer.vector(text)]).flatten
    end
    def count
      @db.execute("SELECT COUNT(*) FROM #{@table_name} ;").first.first
    end
    def delete_all
      @db.execute("DELETE FROM #{@table_name} ;")
    end
    def batch_insert(records)
      @db.prepare("INSERT INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);") do |stmt|
        records.each do |rec|
          stmt.execute([rec[:docid], @tokenizer.vector(rec[:text]), rec[:sort_value]])
        end
      end
    end
    def batch_insert_or_replace(records)
      @db.prepare("INSERT OR REPLACE INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);") do |stmt|
        records.each do |rec|
          stmt.execute([rec[:docid], @tokenize.vector(rec[:text]), rec[:sort_value]])
        end
      end
    end
    def batch_update_sort_value(records)
      @db.prepare("UPDATE #{@table_name} SET sort_value = ? WHERE docid = ?;") do |stmt|
        records.each do |rec|
          stmt.execute([rec[:sort_value], rec[:docid]])
        end
      end
    end
    def drop_table!
      if (table_exist?)
        @db.execute("DROP TABLE #{@table_name};")
      end
    end
    
    private
    def create_table!(options)
      ret = false
      @db.transaction do 
        tokenizer = options[:tokenizer] || DEFAULT_TOKENIZER
        exist = table_exist?
        if (!exist)
          drop_table!
          @db.execute("CREATE VIRTUAL TABLE #{@table_name} USING FTS4(text, sort_value, tokenize=simple);")
          ret = true
        end
      end
      ret
    end
    def table_exist?
      @db.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?;",
                  [@table_name]).size == 1
    end
    def set_db_param(options)
      @db.transaction do 
        @db.execute("PRAGMA journal_mode=#{options[:journal_mode] || DEFAULT_JURNAL_MODE};")
        @db.execute("PRAGMA temp_store=#{options[:temp_store] || DEFAULT_TEMP_STORE};")
        @db.execute("PRAGMA cache_size=#{options[:cache_size] || DEFAULT_CACHE_SIZE};")
      end
    end
  end
end