require 'sqlite3'

module FtsLite
  class Index
    DEFAULT_TOKENIZER = :bigram
    DEFAULT_JURNAL_MODE = "MEMORY"
    DEFAULT_TEMP_STORE = "MEMORY"
    DEFAULT_CACHE_SIZE = 32000
    DEFAULT_TIMEOUT = 10000
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
    def self.open(path, options = {})
      if (block_given?)
        index = Index.new(path, options)
        begin
          yield(index)
        ensure
          index.close
        end
      else
        Index.new(path, options)
      end
    end

    def sql_value(x)
      if x.nil?
        x
      elsif x.is_a?(DateTime)
        x.iso8601
      elsif x.is_a?(Date)
        x.iso8601
      elsif x.is_a?(Time)
        x.to_datetime.iso8601
      else
        x
      end
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
    def set(docid, text, sort_value = nil)
      if (SQLITE_HAVE_FT4_REPLACE)
        @db.execute("INSERT OR REPLACE INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);",
                    [docid, @tokenizer.vector(text), sql_value(sort_value)])
      else
        begin
          @db.execute("INSERT INTO #{@table_name} (docid, text, sort_value) VALUES(?, ?, ?);",
                      [docid, @tokenizer.vector(text), sql_value(sort_value)])
        rescue SQLite3::ConstraintException
          @db.execute("UPDATE #{@table_name} SET text = ?, sort_value = ? WHERE docid = ?;",
                      [@tokenizer.vector(text), sql_value(sort_value), docid])
        end
      end
    end
    def update_sort_value(docid, sort_value)
      @db.execute("UPDATE #{@table_name} SET sort_value = ? WHERE docid = ?;",
                  [sql_value(sort_value), docid])
    end
    def delete(docid)
      @db.execute("DELETE FROM #{@table_name} WHERE docid = ?;", [docid])
    end
    def search(text, options = {})
      options ||= {}
      limit = options[:limit]
      order = nil
      gt = nil
      lt = nil
      gte = nil
      lte = nil
      if (options[:order])
        case options[:order].to_sym
        when :desc
          order = :desc
        when :asc
          order = :asc
        end
      end
      if (options[:range])
        gt = options[:range][:gt]
        lt = options[:range][:lt]
        gte = options[:range][:gte]
        lte = options[:range][:lte]
      end
      sql = "SELECT docid FROM #{@table_name} WHERE text MATCH ?"
      if gt
        sql += " AND sort_value > ? "
      end
      if lt
        sql += " AND sort_value < ? "
      end
      if gte
        sql += " AND sort_value >= ? "
      end
      if lte
        sql += " AND sort_value <= ? "
      end
      if (order)
        sql += sprintf(" ORDER BY sort_value %s", order == :desc ? "DESC" : "ASC")
      else
        sql += sprintf(" ORDER BY docid ASC")
      end
      if (limit)
        sql += sprintf(" LIMIT %d", limit)
      end
      sql += ";"
      conditions = [gt, lt, gte, lte].reject{|v| v.nil?}.map{|v| sql_value(v)}
      @db.execute(sql, [@tokenizer.query(text, options), conditions].flatten).flatten
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
        @db.busy_timeout = options[:timeout] || DEFAULT_TIMEOUT
      end
    end
  end
end
