require 'sqlite3'

module FtsLite
  class Database
    DEFAULT_TOKENIZER = :bigram
    DEFAULT_JURNAL_MODE = "MEMORY"
    DEFAULT_TEMP_STORE = "MEMORY"
    DEFAULT_CACHE_SIZE = 32000
    SQLITE_HAVE_FT4_REPLACE = SQLite3.libversion >= 3007007
    
    def self.have_ft4_replace
      SQLITE_HAVE_FT4_REPLACE
    end
    def self.sqlite3_version
      SQLite3.libversion
    end
    class RuntimeError < ::RuntimeError
    end
    
    def initialize(path, options = {})
      @db = SQLite3::Database.new(path)
      @table_name = options[:table_name] || "fts_lite"
      create_table!(options)
      set_db_param(options)
      @tokenizer = Tokenizer.create(options[:tokenizer] || DEFAULT_TOKENIZER)
    end
    def close
      @db.close
    end
    def tokenize(text)
      @tokenizer.vector(text).split(" ")
    end
    def transaction(&block)
      @db.transaction do
        block.call
      end
    end
    def update(docid, text, sort_value = nil)
      if (SQLITE_HAVE_FT4_REPLACE)
        @db.execute("INSERT OR REPLACE INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);",
                    [docid, @tokenizer.vector(text), sort_value])
      else
        begin
          @db.execute("INSERT INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);",
                      [docid, @tokenizer.vector(text), sort_value])
        rescue SQLite3::ConstraintException
          @db.execute("UPDATE #{@table_name} SET text = ?, sort_value = ? WHERE docid = ?;",
                      [@tokenizer.vector(text), sort_value, docid])
        end
      end
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
