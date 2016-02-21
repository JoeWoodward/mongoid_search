# encoding: utf-8
module Util

  def self.keywords(klass, field, stem_keywords, ignore_list)
    if field.is_a?(Hash)
      field.keys.map do |key|
        attribute = klass.send(key)
        unless attribute.blank?
          method = field[key]
          if attribute.is_a?(Array)
            if method.is_a?(Array)
              method.map {|m| attribute.map { |a| Util.normalize_keywords a.send(m), stem_keywords, ignore_list } }
            elsif method.is_a?(Hash)
              text = []
              attribute.each do |top_class|
                method.keys.map do |nested_class_name|
                  nested_objects = top_class.send(nested_class_name)
                  unless nested_objects.blank?
                    nested_attribute_names = method[nested_class_name]
                    if nested_objects.is_a?(Array)
                      if nested_attribute_names.is_a?(Array)
                        nested_objects.map {|no| nested_attribute_names.map { |nan| text << nan.send(no) } }
                      else
                        nested_objects.map(&nested_attribute_names).map { |na| text << na }
                      end
                    end
                  end
                end
              end
              Util.normalize_keywords text, stem_keywords, ignore_list
            else
              attribute.map(&method).map { |t| Util.normalize_keywords t, stem_keywords, ignore_list }
            end
          elsif attribute.is_a?(Hash)
            if method.is_a?(Array)
              method.map {|m| Util.normalize_keywords attribute[m.to_sym], stem_keywords, ignore_list }
            else
              Util.normalize_keywords(attribute[method.to_sym], stem_keywords, ignore_list)
            end
          else
            Util.normalize_keywords(attribute.send(method), stem_keywords, ignore_list)
          end
        end
      end
    else
      value = klass[field]
      value = value.join(' ') if value.respond_to?(:join)
      Util.normalize_keywords(value, stem_keywords, ignore_list) if value
    end
  end

  def self.normalize_keywords(text, stem_keywords, ignore_list)
    ligatures = {"œ"=>"oe", "æ"=>"ae"}

    return [] if text.blank?
    text = text.to_s.
      mb_chars.
      normalize(:kd).
      downcase.
      to_s.
      gsub(/[._:;'"`,?|+={}()!@#%^&*<>~\$\-\\\/\[\]]/, ' '). # strip punctuation
      gsub(/[^[:alnum:]\s]/,'').   # strip accents
      gsub(/[#{ligatures.keys.join("")}]/) {|c| ligatures[c]}.
      split(' ').
      reject { |word| word.size < 2 }
    text = text.reject { |word| ignore_list.include?(word) } unless ignore_list.blank?
    text = text.map(&:stem) if stem_keywords
    text
  end

end
