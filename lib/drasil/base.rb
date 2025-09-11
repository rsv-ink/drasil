module Drasil
  class Base < Spyke::Base
    include_root_in_json Config.include_root_in_json

    class << self
      def page(number)
        where(Hash[Config.page_query_name, number])
      end

      def per_page(number)
        where(Hash[Config.per_page_query_name, number])
      end
    end
  end
end

class Spyke::Relation
  def total_pages
    metadata[:total_pages]
  end

  def next_page?
    metadata[:page].to_i < metadata[:total_pages]
  end

  def current_page
    metadata[:page]
  end
end
