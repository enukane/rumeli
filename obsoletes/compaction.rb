ary = [
  {:type => "hoge",
   :val1 => 100,
   :val2 => 200,
  },
  {:type => "gua",
   :valon => 300,
  }
]

combined = ary.map{|hash|
  type = hash[:type]
  Hash[hash.map{|k, v|
    if k == :type
      nil
    else
      ["#{type.to_s}_#{k.to_s}".to_sym, v]
    end
  }]
}.flatten.inject({}){|sum, item| sum.merge(item)}
p combined
