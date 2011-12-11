require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RglFold" do
  before :all do
    require 'rgl/adjacency'
    DG = RGL::DirectedAdjacencyGraph[1,2, 2,3, 2,4, 4,5, 6,4, 1,6]
    DG.extend RGLFold
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
end