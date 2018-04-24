module DynamicContent
  class TagSerializer
    def load(data)
      data.to_s.split(',')
    end

    def dump(data)
      data.kind_of?(Array) ? data.reject{ |a| a.blank? }.join(',') : data
    end
  end
end
