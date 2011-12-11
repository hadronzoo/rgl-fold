# Adds {#fold} and {#compile_fold} to RGL[http://rgl.rubyforge.org/rgl/] graphs
module RGLFold

  # Iterates over all paths accessible in the graph from a given vertex, combining successive vertices using a given block. This method works on both cyclic and acyclic graphs.
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
  #   dg = RGL::DirectedAdjacencyGraph[1,2, 2,3, 2,4, 4,5, 6,4, 1,6]
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

  # Returns a lambda which, when called with an initial value and a fold block, iterates over all paths accessible in the graph from a given vertex, combining successive vertices using a given block. This method works on both cyclic and acyclic graphs.
  #
  # @author Joshua B. Griffith
  # @param [Object] vertex vertex whose adjacent paths will be iterated over
  # @return [Proc] a lambda which, when called given an initial value and a fold block, returns a set of accumulated paths adjacent to the given vertex
  # @note The returned lambda does not reference the graph when called. The graph paths are precompiled into the function.
  # 
  # @example Create a directed adjacency graph and add fold functionality
  #   require 'rgl/adjacency'
  #   require 'rgl-fold'
  #   dg = RGL::DirectedAdjacencyGraph[1,2, 2,3, 2,4, 4,5, 6,4, 1,6]
  #   dg.extend RGLFold
  #
  # @example Compile and call a lambda which, when given an initial value and a fold block, returns a set of every path in the graph from the root vertex
  #   fold_proc = dg.compile_fold 1
  #   fold_proc.call [] {|accum, vertex| accum + [vertex]}
  #     #=> #<Set: {[1, 2, 3], [1, 2, 4, 5], [1, 6, 4, 5]}> 

  def compile_fold(vertex)
    fold_paths = fold(vertex, []) {|accum, vertex| accum + [vertex]}

    lambda do |init, &proc|
      result_cache = {[] => init}
      current_result = nil
      results = fold_paths.map do |path|
        for i in 1..path.length
          previous_path = path.take (i - 1)
          previous_result = result_cache[previous_path]

          current_path = path.take i
          current_result = result_cache[current_path]
          current_vertex = path[i - 1]

          if current_result.nil?
            current_result = proc.call previous_result, current_vertex
            result_cache[current_path] = current_result
          end
        end
        current_result
      end

      results.to_set
    end
  end
end