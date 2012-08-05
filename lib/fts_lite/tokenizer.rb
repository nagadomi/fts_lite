# coding: utf-8
require 'nkf'
require 'bimyou_segmenter'

module FtsLite
  module Tokenizer
    QUERY_DELIMITER = /[\s　]+/
    SIMPLE_DELIMITER = /[\s　\.\*"',\?!;\(\)。、．，？！「」『』（）]+/
    NEAR = " NEAR/2 "
    
    def self.create(name)
      case name.to_sym
      when :simple
        Simple.new
      when :bigram
        Bigram.new
      when :trigram
        Trigram.new
      when :wakachi
        Wakachi.new
      when :wakachi_bigram
        WakachiBigram.new
      else
        raise ArgumentError
      end
    end
    def self.normalize(text)
      NKF::nkf('-wZX', text).downcase
    end
    class Simple
      def query(text)
        vector(text)
      end
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        Tokenizer.normalize(text).split(SIMPLE_DELIMITER)
      end
    end
    class Bigram
      def query(text)
        text = Tokenizer.normalize(text)
        text.split(QUERY_DELIMITER).map {|segment|
          segment.split(SIMPLE_DELIMITER).map {|word|
            0.upto(word.size - 2).map {|i| word[i, 2] }
          }.join(NEAR)
        }.flatten.join(" ")
      end
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        text = Tokenizer.normalize(text)
        text.split(SIMPLE_DELIMITER).map {|word|
          0.upto(word.size - 2).map {|i| word[i, 2] }
        }.flatten
      end
    end
    class Trigram
      def query(text)
        text = Tokenizer.normalize(text)
        text.split(QUERY_DELIMITER).map {|segment|
          segment.split(SIMPLE_DELIMITER).map {|word|
            0.upto(word.size - 3).map {|i| word[i, 3] }
          }.join(NEAR)
        }.flatten.join(" ")
      end
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        text = Tokenizer.normalize(text)
        text.split(SIMPLE_DELIMITER).map {|word|
          0.upto(word.size - 3).map {|i| word[i, 3] }
        }.flatten
      end
    end
    class Wakachi
      def query(text)
        text = Tokenizer.normalize(text)
        text.split(QUERY_DELIMITER).map {|segment|
          BimyouSegmenter.segment(segment,
                                  :white_space => false,
                                  :symbol => false).join(NEAR)
        }.join(" ")
      end
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        BimyouSegmenter.segment(Tokenizer.normalize(text),
                                :white_space => false,
                                :symbol => false)
      end
    end
    class WakachiBigram
      def query(text)
        text = Tokenizer.normalize(text)
        text.split(QUERY_DELIMITER).map {|segment|
          BimyouSegmenter.segment(segment,
                                  :white_space => false,
                                  :symbol => false).map {|word|
            if (word.size == 1)
              word
            else
              0.upto(word.size - 2).map {|i| word[i, 2] }.join(NEAR)
            end
          }.flatten.join(NEAR)
        }.join(" ")
      end
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        BimyouSegmenter.segment(Tokenizer.normalize(text),
                                :white_space => false,
                                :symbol => false).map {|word|
          if (word.size == 1)
            word
          else
            0.upto(word.size - 2).map {|i| word[i, 2] }
          end
        }.flatten
      end
    end
  end
end
