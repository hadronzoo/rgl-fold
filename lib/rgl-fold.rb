# Adds {#fold} to RGL[http://rgl.rubyforge.org/rgl/] graphs
module RGLFold

  # Iterates over all paths accessible in the graph from a given vertex,
  # combining successive vertices using a given block. This method
  # works on both cyclic and acyclic graphs.
  #
  # @author Joshua B. Griffith
  # @param [Object] vertex vertex whose adjacent paths will be iterated over
  # @param [Object] init initial value sent to the given block
  # @yield [accum, vertex] Block used to combine a path's next vertex with the previously accumulated value
  # @yieldparam [Object] accum previously accumulated value, or init for first vertex in the path
  # @yieldparam [Object] vertex the current path vertex
  # @yieldreturn [Object] newly accumulated value
  # @return [Set] a set of accumulated paths adjacent to the given vertex
  #
  # === Graph for Examples:
  # link:img/graph.png
  # 
  # @example Create a directed adjacency graph and add fold functionality
  #   require 'rgl/adjacency'
  #   require 'rgl-fold'
  #   dg = RGL::DirectedAdjacencyGraph [1,2, 2,3, 2,4, 4,5, 6,4, 1,6]
  #   dg.extend RGLFold
  #
  # @example Return a set of every path in the graph from the root vertex
  #   dg.fold(1, []) {|accum, vertex| accum + [vertex]}
  #     #=> #<Set: {[1, 2, 3], [1, 2, 4, 5], [1, 6, 4, 5]}> 
  #
  # @example Return a set of every path in the graph from the 6 vertex
  #   dg.fold(6, []) {|accum, vertex| accum + [vertex]}
  #     #=> #<Set: {[6, 4, 5]}>
  #
  # @example Sum the vertices for each path
  #   dg.fold(1, 0) {|accum, vertex| accum + vertex}
  #     #=> #<Set: {6, 12, 16}>

  def fold(vertex, init, &proc)
    get_targets = lambda do |vertex|
      targets = []
      each_adjacent(vertex) {|v| targets << v}
    end

    results = Set.new
    tree_fold = lambda do |a, accum, visited_vertices|
      vertex_targets = get_targets.call a
      if vertex_targets.empty?
        results << accum
      else
        vertex_targets.each do |b|
          if !visited_vertices.include? b
            result = proc.call accum, b
            tree_fold.call b, result, visited_vertices + [b]
          end
        end
      end
    end

    tree_fold.call vertex, proc.call(init, vertex), Set.new
    results
  end
end