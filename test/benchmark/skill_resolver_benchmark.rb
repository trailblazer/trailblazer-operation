require "trailblazer/operation"
require "benchmark/ips"

initialize_hash = {}
10.times do |i|
  initialize_hash["bla_#{i}"] = i
end

normal_container = {}
50.times do |i|
  normal_container["xbla_#{i}"] = i
end

Benchmark.ips do |x|
  x.report(:merge) do
    attrs = normal_container.merge(initialize_hash)
    10.times do |_i|
      attrs["bla_8"]
    end
    10.times do |_i|
      attrs["xbla_1"]
    end
  end

  x.report(:resolver) do
    attrs = Trailblazer::Skill::Resolver.new(initialize_hash, normal_container)

    10.times do |_i|
      attrs["bla_8"]
    end
    10.times do |_i|
      attrs["xbla_1"]
    end
  end
end

# Warming up --------------------------------------
#                merge     3.974k i/100ms
#             resolver     6.593k i/100ms
# Calculating -------------------------------------
#                merge     39.678k (± 9.1%) i/s -    198.700k in   5.056653s
#             resolver     68.928k (± 6.4%) i/s -    342.836k in   5.001610s
