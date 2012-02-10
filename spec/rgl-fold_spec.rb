require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RglFold" do
  before :all do
    require 'rgl/adjacency'
    DG = RGL::DirectedAdjacencyGraph[1,2, 2,3, 2,4, 4,5, 6,4, 1,6]
    DG.extend RGLFold

    CycleDG = RGL::DirectedAdjacencyGraph[1,2, 2,3, 3,4, 3,1]
    CycleDG.extend RGLFold

    CycleDG2 = RGL::DirectedAdjacencyGraph[1,1, 1,2, 2,3, 2,1]
    CycleDG2.extend RGLFold
  end

  it "should fold from root vertex" do
    result = [[1, 2, 3], [1, 2, 4, 5], [1, 6, 4, 5]].to_set
    ops_1 = 0
    array_paths = DG.fold 1, [] do |accum, vertex| 
      ops_1 += 1
      accum + [vertex]
    end
    array_paths.should == result

    ops_2 = 0
    array_path_proc = DG.compile_fold 1
    array_paths = array_path_proc.call [] do |accum, vertex| 
      ops_2 += 1
      accum + [vertex]
    end
    array_paths.should == result
    ops_1.should == ops_2
  end

  it "should fold right from root vertex" do
    result = [[[3].to_set, [[5].to_set, 4].to_set, 2].to_set, [[[5].to_set, 4].to_set, 6].to_set, 1].to_set
    ops_1 = 0
    folded_tree = DG.fold_right 1, Set.new do |accum, vertex| 
      ops_1 += 1
      accum + [vertex]
    end
    folded_tree.should == result

    ops_2 = 0
    folded_tree_proc = DG.compile_fold_right 1
    folded_tree = folded_tree_proc.call Set.new do |accum, vertex| 
      ops_2 += 1
      accum + [vertex]
    end
    folded_tree.should == result
    ops_1.should == ops_2
  end

  it "should fold from non-root vertex" do
    result = [[6, 4, 5]].to_set
    ops_1 = 0
    alt_root_paths = DG.fold 6, [] do |accum, vertex| 
      ops_1 += 1
      accum + [vertex]
    end
    alt_root_paths.should == result

    ops_2 = 0
    alt_root_paths_proc = DG.compile_fold 6
    alt_root_paths = alt_root_paths_proc.call [] do |accum, vertex| 
      ops_2 += 1
      accum + [vertex]
    end
    alt_root_paths.should == result
    ops_1.should == ops_2
  end

  it "should fold right from non-root vertex" do
    result = [[[5].to_set, 4].to_set, 6].to_set
    ops_1 = 0
    alt_root_tree = DG.fold_right 6, Set.new do |accum, vertex| 
      ops_1 += 1
      accum + [vertex]
    end
    alt_root_tree.should == result

    ops_2 = 0
    alt_root_tree_proc = DG.compile_fold_right 6
    alt_root_tree =  alt_root_tree_proc.call Set.new do |accum, vertex| 
      ops_2 += 1
      accum + [vertex]
    end
    alt_root_tree.should == result
    ops_1.should == ops_2
  end

  it "should accumulate folded paths" do
    result = [6, 12, 16].to_set
    ops_1 = 0
    sum_paths = DG.fold 1, 0 do |accum, vertex| 
      ops_1 += 1
      accum + vertex
    end
    sum_paths.should == result

    ops_2 = 0
    sum_paths_proc = DG.compile_fold 1
    sum_paths = sum_paths_proc.call 0 do |accum, vertex|
      ops_2 += 1
      accum + vertex
    end
    sum_paths.should == result
    ops_1.should == ops_2
  end

  it "should accumulate folded tree" do
    result = 30
    ops_1 = 0
    sum_tree = DG.fold_right 1, 0 do |accum, vertex|
      ops_1 += 1
      if accum.class == Set
        accum.reduce(:+) + vertex
      else
        accum + vertex
      end
      
    end
    sum_tree.should == result

    ops_2 = 0
    fold_right_proc = DG.compile_fold_right 1
    sum_tree = fold_right_proc.call 0 do |accum, vertex|
      ops_2 += 1
      if accum.class == Set
        accum.reduce(:+) + vertex
      else
        accum + vertex
      end
    end

    sum_tree.should == result
    ops_1.should == ops_2
  end

  it "should fold trees with cycles" do
    result = [[1, 2, 3, 4]].to_set
    r = CycleDG.fold 1, [] do |accum, vertex|
      accum + [vertex]
    end
    r.should == result

    result = [[[[4].to_set, 3].to_set, 2].to_set, 1].to_set
    r = CycleDG.fold_right 1, Set.new do |accum, vertex|
      accum + [vertex]
     end
     r.should == result
  end

  it "should find all paths between two vertices" do
    DG.find_all_paths(1, 5).should == [[1,2,4,5], [1,6,4,5]].to_set
    CycleDG.find_all_paths(1, 1).should == [[1,2,3,1]].to_set
    CycleDG2.find_all_paths(1, 3).should == [[1,2,3]].to_set
    CycleDG2.find_all_paths(1, 1).should == [[1,1], [1,2,1]].to_set
  end
end
