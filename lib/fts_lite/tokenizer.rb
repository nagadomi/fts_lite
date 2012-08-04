# coding: utf-8
require 'nkf'
require 'bimyou_segmenter'

module FtsLite
  module Tokenizer
    SIMPLE_DELIMITER = /[\s\.,\?!;\(\)。、．，？！「」『』（）]+/
    
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
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        Tokenizer.normalize(text).gsub(/[\.,\?!;:]/, ' ').split(SIMPLE_DELIMITER)
      end
    end
    class Bigram
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
      def vector(text)
        split(text).join(" ")
      end
      def split(text)
        words = BimyouSegmenter.segment(Tokenizer.normalize(text),
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
