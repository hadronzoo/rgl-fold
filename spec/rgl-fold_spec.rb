require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RglFold" do
  before :all do
    require 'rgl/adjacency'
    DG = RGL::DirectedAdjacencyGraph[1,2, 2,3, 2,4, 4,5, 6,4, 1,6]
    DG.extend RGLFold
  end

  it "should fold from root vertex" do
    array_paths = DG.fold(1, []) {|accum, vertex| accum + [vertex]}
    array_paths.should == [[1, 2, 3], [1, 2, 4, 5], [1, 6, 4, 5]].to_set
  end

  it "should fold from non-root vertex" do
    alt_root_paths = DG.fold(6, []) {|accum, vertex| accum + [vertex]}
    alt_root_paths.should == [[6, 4, 5]].to_set
  end

  it "should accumulate folded paths" do
    sum_paths = DG.fold(1, 0) {|accum, vertex| accum + vertex}
    sum_paths.should == [6, 12, 16].to_set
  end
end